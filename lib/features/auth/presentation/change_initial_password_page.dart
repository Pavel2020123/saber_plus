import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/session.dart';
import 'auth_form_scaffold.dart';
import 'session_controller.dart';

class ChangeInitialPasswordPage extends ConsumerStatefulWidget {
  const ChangeInitialPasswordPage({super.key});

  @override
  ConsumerState<ChangeInitialPasswordPage> createState() =>
      _ChangeInitialPasswordPageState();
}

class _ChangeInitialPasswordPageState
    extends ConsumerState<ChangeInitialPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(sessionControllerProvider.notifier)
        .changeInitialPassword(_password.text);
    if (!success || !mounted) return;
    final role = ref.read(sessionControllerProvider).user?.role;
    context.go(role == AppRole.teacher ? '/teacher' : '/student/home');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    return AuthFormScaffold(
      title: 'Protege tu cuenta',
      subtitle:
          'Tu institución creó una contraseña temporal. Debes reemplazarla antes de continuar.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session.errorMessage case final message?) ...[
              AuthErrorBanner(message: message),
              const SizedBox(height: 18),
            ],
            PasswordField(controller: _password, label: 'Contraseña nueva'),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmation,
              label: 'Confirmar contraseña',
              validator: (value) {
                if ((value?.length ?? 0) < 8) {
                  return 'Usa al menos 8 caracteres';
                }
                if (value != _password.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: session.isLoading ? null : _submit,
              child: session.isLoading
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Actualizar y continuar'),
            ),
          ],
        ),
      ),
    );
  }
}
