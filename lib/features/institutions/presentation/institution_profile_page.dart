import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/institution_profile_repository.dart';
import '../domain/institution_profile.dart';
import 'institution_directory_providers.dart';
import 'institution_logo.dart';
import 'institution_logo_page.dart';

final institutionProfileRepositoryProvider =
    Provider<InstitutionProfileRepository>((ref) {
      final user = ref.watch(sessionControllerProvider.select((s) => s.user));
      return user?.isDemo == true
          ? DemoInstitutionProfileRepository()
          : RemoteInstitutionProfileRepository(ref.watch(dioProvider));
    });

class InstitutionProfilePage extends ConsumerWidget {
  const InstitutionProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider.select((s) => s.user));
    final repository = ref.watch(institutionProfileRepositoryProvider);
    // Nueva sesión/repositorio: destruir borrador y descartar respuestas anteriores.
    return InstitutionProfileEditor(
      key: ValueKey((user?.id, repository)),
      repository: repository,
      isDemo: user?.isDemo == true,
      onSaved: (id) {
        ref.invalidate(institutionDirectoryDetailProvider(id));
        ref.invalidate(institutionDirectoryProvider);
      },
      onLogo: user?.isDemo == true
          ? null
          : () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const InstitutionLogoPage()),
            ),
    );
  }
}

class InstitutionProfileEditor extends StatefulWidget {
  const InstitutionProfileEditor({
    super.key,
    required this.repository,
    required this.onSaved,
    this.isDemo = false,
    this.onLogo,
  });
  final InstitutionProfileRepository repository;
  final ValueChanged<String> onSaved;
  final bool isDemo;
  final Future<void> Function()? onLogo;
  @override
  State<InstitutionProfileEditor> createState() =>
      _InstitutionProfileEditorState();
}

class _InstitutionProfileEditorState extends State<InstitutionProfileEditor> {
  final _text = TextEditingController();
  InstitutionProfile? _profile;
  bool _busy = true, _mustReload = false, _allowExit = false;
  bool _editing = false;
  String? _message;
  bool get _dirty =>
      _profile != null && _text.text.trim() != (_profile!.description ?? '');
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final profile = await widget.repository.load();
      if (!mounted) return;
      // Nunca asignar el borrador de otra institución a la nueva.
      final keepDraft = _profile?.id == profile.id && _dirty;
      setState(() {
        if (!keepDraft) {
          _text.text = profile.description ?? '';
          _editing = false;
        }
        _profile = profile;
        _mustReload = false;
        _message = keepDraft
            ? 'Versión actual consultada. Conservamos tu borrador; compara el texto publicado antes de guardar.'
            : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _mustReload = true;
          _message =
              'No pudimos cargar el perfil. Tu texto no se ha descartado.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final profile = _profile;
    if (profile == null ||
        !profile.canEdit ||
        !_editing ||
        _busy ||
        _mustReload) {
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await widget.repository.save(profile, _text.text);
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      setState(() {
        _profile = result;
        _text.text = result.description ?? '';
        _editing = false;
        _message = widget.isDemo
            ? 'Guardado solo en la demostración.'
            : 'Presentación pública guardada.';
      });
      widget.onSaved(result.id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _mustReload = true;
          _message =
              'No se pudo confirmar el guardado o cambió la versión. Tu borrador sigue aquí. Consulta la versión actual antes de volver a guardar.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exit() async {
    if (_busy) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir del editor?'),
        content: const Text(
          'Se perderá el borrador de esta pantalla. Si el guardado no se confirmó, el servidor podría haberlo recibido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Seguir editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return PopScope(
      canPop: _allowExit || (!_busy && !_dirty && !_mustReload),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Perfil institucional')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (widget.isDemo)
                const Text('DEMOSTRACIÓN · Cambios solo en memoria.'),
              if (_busy) const LinearProgressIndicator(),
              if (profile != null) ...[
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (profile.logoUrl != null)
                  InstitutionLogo(path: profile.logoUrl, size: 80),
                if (profile.canEdit && widget.onLogo != null)
                  OutlinedButton.icon(
                    onPressed: _busy || _dirty || _mustReload
                        ? null
                        : () async {
                            await widget.onLogo!();
                            if (mounted) await _load();
                          },
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Cambiar logo'),
                  ),
                const Text(
                  'El nombre y la ubicación aprobados se gestionan mediante la verificación institucional.',
                ),
                const SizedBox(height: 20),
                Text(
                  profile.canEdit
                      ? 'Presentación pública'
                      : 'Presentación pública · Solo lectura',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Visible para quienes consulten la institución. No incluyas códigos de ingreso ni datos personales.',
                ),
                const SizedBox(height: 12),
                if (_editing && profile.canEdit)
                  TextField(
                    key: const Key('institution-description'),
                    controller: _text,
                    readOnly: !profile.canEdit || _busy,
                    minLines: 4,
                    maxLines: 10,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        profile.description ??
                            'Todavía no hay una presentación pública.',
                      ),
                    ),
                  ),
                if (profile.canEdit && !_editing)
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _text.text = profile.description ?? '';
                            _editing = true;
                            _message = null;
                          }),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar presentación'),
                  ),
                if (_dirty) ...[
                  const Text(
                    'Texto publicado actualmente:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(profile.description ?? 'Sin presentación pública.'),
                  const SizedBox(height: 12),
                ],
                if (profile.canEdit && _editing)
                  FilledButton(
                    onPressed:
                        _busy ||
                            _mustReload ||
                            !_dirty ||
                            _text.text.trim().runes.length > 500
                        ? null
                        : _save,
                    child: const Text('Guardar presentación'),
                  ),
              ],
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Semantics(liveRegion: true, child: Text(_message!)),
                ),
              OutlinedButton(
                onPressed: _busy ? null : _load,
                child: const Text('Consultar versión actual'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
