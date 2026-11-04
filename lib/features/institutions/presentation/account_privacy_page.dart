import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/remote_account_lifecycle_repository.dart';
import '../domain/account_privacy_request.dart';
import '../domain/student_institution_request.dart';

class AccountPrivacyPageView extends ConsumerWidget {
  const AccountPrivacyPageView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    if (user == null || user.isDemo) {
      return Scaffold(
        appBar: AppBar(title: const Text('Privacidad de mi cuenta')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Inicia sesión con una cuenta real para consultar o enviar solicitudes.',
            ),
          ),
        ),
      );
    }
    final repository = RemoteAccountLifecycleRepository(ref.watch(dioProvider));
    return AccountPrivacyBoard(
      key: ValueKey(user.id),
      userId: user.id,
      load: repository.privacyRequests,
      submit: (operation, reason) => repository.requestSuppression(
        userId: user.id,
        operationId: operation,
        reason: reason,
      ),
    );
  }
}

class AccountPrivacyBoard extends StatefulWidget {
  const AccountPrivacyBoard({
    super.key,
    required this.userId,
    required this.load,
    required this.submit,
  });
  final String userId;
  final Future<AccountPrivacyPage> Function(int) load;
  final Future<AccountPrivacyRequest> Function(String, String) submit;
  @override
  State<AccountPrivacyBoard> createState() => _AccountPrivacyBoardState();
}

class _AccountPrivacyBoardState extends State<AccountPrivacyBoard> {
  final _reason = TextEditingController();
  AccountPrivacyPage? _page;
  bool _loading = true, _busy = false, _uncertain = false;
  String? _message, _operation;
  int _generation = 0;
  bool _allowLeave = false, _confirmingLeave = false;

  @override
  void initState() {
    super.initState();
    _reason.addListener(_draftChanged);
    _load(1);
  }

  void _draftChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmLeave() async {
    if (_busy || _confirmingLeave) return;
    _confirmingLeave = true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir sin enviar?'),
        content: const Text(
          'El motivo escrito no se guardará. Tu cuenta no cambiará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir aquí'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    _confirmingLeave = false;
    if (!mounted || leave != true) return;
    setState(() => _allowLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _generation++;
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load(int number) async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() {
      _loading = true;
    });
    try {
      final page = await widget.load(number);
      if (!mounted || generation != _generation) return;
      setState(() => _page = page);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(
          () => _message = error is ApiError
              ? error.message
              : 'No pudimos consultar las solicitudes. Conservamos lo que escribiste.',
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_busy || _uncertain || _loading) return;
    if (_reason.text.trim().isEmpty) {
      setState(() => _message = 'Escribe el motivo de tu solicitud.');
      return;
    }
    setState(() => _busy = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar solicitud para revisión'),
        content: const Text(
          'Enviar no borra tu cuenta. Solo SaberPlus ADMIN podrá aprobar y ejecutar una supresión irreversible: eliminaría identidad, credenciales y progreso individual; conservaría resultados compartidos y auditoría sin tu identidad.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar solicitud'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _busy = false);
      return;
    }
    _operation ??= newStudentRequestId();
    try {
      final receipt = await widget.submit(_operation!, _reason.text.trim());
      if (!mounted) return;
      setState(() {
        _message = 'Solicitud registrada. Tu cuenta no ha sido eliminada.';
        _page = AccountPrivacyPage(1, _page?.hasNext ?? false, [
          receipt,
          ...?_page?.items.where((item) => item.id != receipt.id).take(19),
        ]);
        _reason.clear();
        _operation = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _uncertain = true;
          _message =
              'No pudimos confirmar el registro. Consulta el estado antes de volver a solicitar. No repetiremos el envío automáticamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) await _load(1);
  }

  @override
  Widget build(BuildContext context) {
    final own =
        _page?.items.where((item) => item.userId == widget.userId).toList() ??
        [];
    final pending = own.any((item) => item.state == 'PENDIENTE');
    return PopScope(
      canPop: !_busy && (_allowLeave || _reason.text.isEmpty),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Privacidad de mi cuenta')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Solicitud de supresión',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No es una baja del colegio ni un cambio a modalidad personal. Esta solicitud requiere revisión de SaberPlus ADMIN. No incluyas contraseñas ni documentos sensibles.',
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _reason,
                    readOnly: _busy || _uncertain || pending,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      labelText: 'Motivo de la solicitud',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy || _loading || _uncertain || pending
                        ? null
                        : _submit,
                    child: Text(_busy ? 'Enviando…' : 'Solicitar revisión'),
                  ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(_message!),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Mis solicitudes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  OutlinedButton(
                    onPressed: _busy || _loading
                        ? null
                        : () => _load(_page?.page ?? 1),
                    child: const Text('Actualizar estado'),
                  ),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_page != null && own.isEmpty)
                    const Text('No hay solicitudes propias en esta página.'),
                  for (final item in own)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            SelectableText('Referencia: ${item.id}'),
                          ],
                        ),
                      ),
                    ),
                  if (_page != null)
                    Wrap(
                      spacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _busy || _loading || _page!.page <= 1
                              ? null
                              : () => _load(_page!.page - 1),
                          child: const Text('Anterior'),
                        ),
                        Text('Página ${_page!.page}'),
                        TextButton(
                          onPressed: _busy || _loading || !_page!.hasNext
                              ? null
                              : () => _load(_page!.page + 1),
                          child: const Text('Siguiente'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountPrivacyShortcut extends StatelessWidget {
  const AccountPrivacyShortcut({super.key});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.privacy_tip_outlined),
    title: const Text('Privacidad de mi cuenta'),
    subtitle: const Text('Solicitudes de supresión y su estado'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const AccountPrivacyPageView()),
    ),
  );
}
