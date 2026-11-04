import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/remote_account_lifecycle_repository.dart';
import '../domain/personal_return_eligibility.dart';
import '../domain/student_institution_request.dart';

class PersonalReturnPage extends ConsumerWidget {
  const PersonalReturnPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionControllerProvider).user;
    final institution = user?.institutionId;
    if (user == null || user.isDemo || institution == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modalidad personal')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'No hay una vinculación institucional disponible. Consulta tu perfil actualizado.',
            ),
          ),
        ),
      );
    }
    final repository = RemoteAccountLifecycleRepository(ref.watch(dioProvider));
    return PersonalReturnBoard(
      key: ValueKey((user.id, institution)),
      load: () => repository.personalReturnEligibility(institution),
      submit: (eligibility, operation) => repository.returnToPersonal(
        institutionId: institution,
        userId: user.id,
        operationId: operation,
        eligibility: eligibility,
      ),
      refreshSession: () => ref
          .read(sessionControllerProvider.notifier)
          .revalidateInstitutionalAccess(),
    );
  }
}

class PersonalReturnBoard extends StatefulWidget {
  const PersonalReturnBoard({
    super.key,
    required this.load,
    required this.submit,
    required this.refreshSession,
  });
  final Future<PersonalReturnEligibility> Function() load;
  final Future<void> Function(PersonalReturnEligibility, String) submit;
  final Future<bool> Function() refreshSession;

  @override
  State<PersonalReturnBoard> createState() => _PersonalReturnBoardState();
}

class _PersonalReturnBoardState extends State<PersonalReturnBoard> {
  PersonalReturnEligibility? _eligibility;
  bool _loading = true, _busy = false, _uncertain = false, _done = false;
  String? _message, _operation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final eligibility = await widget.load();
      if (!mounted) return;
      setState(() => _eligibility = eligibility);
    } catch (error) {
      if (mounted) {
        setState(() {
          _eligibility = null;
          _message = error is ApiError
              ? error.message
              : 'No pudimos validar tu vinculación. Intenta consultar nuevamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final eligibility = _eligibility;
    if (_busy || _uncertain || eligibility == null || !eligibility.allowed) {
      return;
    }
    setState(() => _busy = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Volver a modalidad personal?'),
        content: const SingleChildScrollView(
          child: Text(
            'Dejarás la institución y sus grupos. Tu cuenta y tu historial se conservan. '
            'El saldo personal guardado se reanuda una sola vez; esto no crea una suscripción ni realiza un cobro.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar salida'),
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
      await widget.submit(eligibility, _operation!);
      if (!mounted) return;
      setState(() {
        _done = true;
        _message = 'Salida confirmada. Se conserva tu historial.';
      });
      final refreshed = await widget.refreshSession();
      if (mounted && !refreshed) {
        setState(
          () => _message =
              'Salida confirmada. No pudimos actualizar el perfil; actualízalo con conexión. No repitas la salida.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _uncertain = true;
          _message =
              'No pudimos confirmar el resultado. No repetiremos la operación. '
              'Actualiza tu perfil para comprobar la vinculación antes de continuar.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Modalidad personal')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Tu cuenta, tu progreso',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Text(
                  'La salida no elimina tu cuenta. Solo está disponible para cuentas personales vinculadas, después del vencimiento y sin cobertura institucional activa. El servidor confirma cada solicitud.',
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_eligibility?.managed == true)
                  const Text(
                    'Esta cuenta fue creada por el colegio. No puede convertirse en una cuenta personal desde aquí. Puedes consultar tu historial y contactar al administrador.',
                  )
                else if (_eligibility != null &&
                    !_eligibility!.allowed &&
                    !_done)
                  const Text(
                    'El retorno personal no está disponible para esta vinculación en este momento.',
                  ),
                if (_message != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Semantics(liveRegion: true, child: Text(_message!)),
                  ),
                if (!_loading && !_done && !_uncertain)
                  OutlinedButton(
                    onPressed: _busy ? null : _load,
                    child: const Text('Actualizar vinculación'),
                  ),
                if (!_loading &&
                    _eligibility?.allowed == true &&
                    !_done &&
                    !_uncertain)
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy ? 'Confirmando…' : 'Volver a modalidad personal',
                    ),
                  ),
                if (_uncertain || _done)
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () async {
                            final refreshed = await widget.refreshSession();
                            if (context.mounted && refreshed) {
                              Navigator.pop(context);
                            }
                          },
                    child: const Text('Actualizar mi perfil'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
