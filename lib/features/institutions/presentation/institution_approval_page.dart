import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/institution_approval_repository.dart';
import 'teacher_institution_providers.dart';

final institutionApprovalRepositoryProvider =
    Provider<InstitutionApprovalRepository>((ref) {
      final identity = ref.watch(
        sessionControllerProvider.select((s) => (s.user?.id, s.user?.isDemo)),
      );
      return identity.$2 == true
          ? DemoInstitutionApprovalRepository()
          : RemoteInstitutionApprovalRepository(ref.watch(dioProvider));
    });
final institutionApplicationProvider =
    FutureProvider.autoDispose<InstitutionApplicationContext>((ref) {
      ref.watch(sessionControllerProvider);
      final cancel = CancelToken();
      ref.onDispose(() => cancel.cancel());
      return ref
          .watch(institutionApprovalRepositoryProvider)
          .load(cancelToken: cancel);
    });

class InstitutionApprovalPage extends ConsumerStatefulWidget {
  const InstitutionApprovalPage({super.key});
  @override
  ConsumerState<InstitutionApprovalPage> createState() =>
      _InstitutionApprovalPageState();
}

class _InstitutionApprovalPageState
    extends ConsumerState<InstitutionApprovalPage> {
  final _form = GlobalKey<FormState>();
  final _fields = {
    for (final key in [
      'nombre',
      'ciudad',
      'correoInstitucional',
      'contacto',
      'referenciaUrl',
      'evidencia',
    ])
      key: TextEditingController(),
  };
  final _cancel = CancelToken();
  var _working = false, _declared = false;
  String? _loaded, _message;
  List<String>? _matches;
  @override
  void dispose() {
    _cancel.cancel();
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionControllerProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id) {
        _cancel.cancel();
        for (final field in _fields.values) {
          field.clear();
        }
        if (mounted) Navigator.of(context).pop();
      }
    });
    final async = ref.watch(institutionApplicationProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificación de institución'),
        actions: [
          IconButton(
            tooltip: 'Actualizar estado',
            onPressed: _working
                ? null
                : () {
                    setState(() {
                      _loaded = null;
                      _matches = null;
                      _message = null;
                    });
                    ref.invalidate(institutionApplicationProvider);
                    ref.invalidate(teacherInstitutionControllerProvider);
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: async.when(
          skipLoadingOnRefresh: false,
          skipLoadingOnReload: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error(e)),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(institutionApplicationProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) {
            final row = data.request;
            final key = '${row?.data['id']}:${row?.revision}';
            if (_loaded != key) {
              for (final field in _fields.entries) {
                field.value.text = row?.field(field.key) ?? '';
              }
              _loaded = key;
              _declared = false;
            }
            return Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (ref.watch(sessionControllerProvider).user?.isDemo == true)
                    const Text(
                      'Demostración: esta solicitud no llega al equipo de SaberPlus.',
                    ),
                  const Text(
                    'Solicita la aprobación de tu institución',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'El equipo de SaberPlus comprobará que representas a la institución. Los grupos y el seguimiento se habilitan después de aprobarla.',
                  ),
                  if (row != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              institutionApprovalLabels[row.state]!,
                              key: const Key('institution-approval-status'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(row.message),
                            if (data.transitionUntil != null)
                              Text(
                                'Plazo de revisión: ${data.transitionUntil!.toLocal().day}/${data.transitionUntil!.toLocal().month}/${data.transitionUntil!.toLocal().year}. Pide al propietario que complete la información.',
                              ),
                          ],
                        ),
                      ),
                    ),
                  if (data.canEdit) ...[
                    _field('nombre', 'Nombre de la institución', min: 3),
                    OutlinedButton(
                      onPressed: _working ? null : _search,
                      child: const Text('Buscar instituciones existentes'),
                    ),
                    if (_matches != null)
                      Text(
                        _matches!.isEmpty
                            ? 'No encontramos coincidencias. El equipo revisará posibles duplicados.'
                            : 'Posibles coincidencias:\n${_matches!.join('\n')}\nSi es tu institución, solicita una invitación a su responsable.',
                      ),
                    _field('ciudad', 'Ciudad o municipio', min: 2),
                    _field(
                      'correoInstitucional',
                      'Correo de contacto institucional',
                      max: 254,
                      email: true,
                    ),
                    _field(
                      'contacto',
                      'Nombre y teléfono del contacto institucional',
                      min: 5,
                    ),
                    _field(
                      'referenciaUrl',
                      'Página institucional HTTPS (opcional)',
                      max: 500,
                      optional: true,
                    ),
                    _field(
                      'evidencia',
                      'Tu cargo y cómo podemos verificar la autorización',
                      min: 20,
                      max: 2000,
                      lines: 4,
                    ),
                    const Text(
                      'Incluye una referencia que permita comprobar tu vínculo. No escribas documentos de identidad ni datos de estudiantes. Si necesitas ayuda, explica aquí cómo contactarte.',
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _declared,
                      onChanged: _working
                          ? null
                          : (v) => setState(() => _declared = v ?? false),
                      title: const Text(
                        'Tengo autorización para representar a esta institución y los datos son correctos.',
                      ),
                    ),
                    FilledButton(
                      key: const Key('submit-institution-application'),
                      onPressed: _working
                          ? null
                          : () => _submit(row?.revision ?? 0),
                      child: Text(
                        _working ? 'Enviando…' : 'Enviar para revisión',
                      ),
                    ),
                  ] else if (row?.state == 'APROBADA')
                    OutlinedButton(
                      onPressed: () {
                        ref.invalidate(teacherInstitutionControllerProvider);
                        Navigator.pop(context);
                      },
                      child: const Text('Volver al espacio del profesor'),
                    ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_message!, semanticsLabel: _message),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    int min = 1,
    int max = 120,
    int lines = 1,
    bool email = false,
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: TextFormField(
      key: Key('application-$key'),
      controller: _fields[key],
      enabled: !_working,
      maxLength: max,
      minLines: lines,
      maxLines: lines == 1 ? 1 : 6,
      keyboardType: email
          ? TextInputType.emailAddress
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (optional && text.isEmpty) return null;
        if (text.length < min) return 'Escribe al menos $min caracteres.';
        if (email && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
          return 'Escribe un correo válido.';
        }
        if (key == 'referenciaUrl') {
          final uri = Uri.tryParse(text);
          if (uri == null ||
              uri.scheme != 'https' ||
              uri.host.isEmpty ||
              uri.userInfo.isNotEmpty) {
            return 'Usa una dirección HTTPS sin credenciales.';
          }
        }
        return null;
      },
    ),
  );
  Future<void> _search() async {
    final name = _fields['nombre']!.text.trim();
    if (name.length < 3) {
      setState(() => _message = 'Escribe primero el nombre de la institución.');
      return;
    }
    setState(() => _working = true);
    try {
      final matches = await ref
          .read(institutionApprovalRepositoryProvider)
          .matches(name, cancelToken: _cancel);
      if (mounted && !_cancel.isCancelled) {
        setState(() {
          _matches = matches;
          _message = null;
        });
      }
    } catch (e) {
      if (mounted && !_cancel.isCancelled) setState(() => _message = _error(e));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _submit(int revision) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (!_declared) {
      setState(
        () => _message =
            'Confirma que tienes autorización para representar a la institución.',
      );
      return;
    }
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      await ref.read(institutionApprovalRepositoryProvider).submit({
        'revision': revision,
        'declaracion': true,
        for (final field in _fields.entries)
          if (field.key != 'referenciaUrl' ||
              field.value.text.trim().isNotEmpty)
            field.key: field.value.text.trim(),
      }, cancelToken: _cancel);
      if (!mounted || _cancel.isCancelled) return;
      ref.invalidate(institutionApplicationProvider);
      ref.invalidate(teacherInstitutionControllerProvider);
      setState(
        () => _message =
            'Solicitud enviada. Puedes consultar aquí la respuesta del equipo.',
      );
    } catch (e) {
      if (mounted && !_cancel.isCancelled) setState(() => _message = _error(e));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
}

String _error(Object error) => error is ApiError
    ? error.message
    : 'No pudimos consultar la verificación. Revisa la conexión e intenta nuevamente.';
