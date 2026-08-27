import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_form_scaffold.dart';
import 'session_controller.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({required this.token, super.key});

  final String token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
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
        .resetPassword(token: widget.token, password: _password.text);
    if (!success || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contraseña actualizada. Ya puedes ingresar.'),
      ),
    );
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    if (widget.token.isEmpty) {
      return const AuthFormScaffold(
        title: 'Enlace inválido',
        subtitle:
            'El enlace no contiene un token de recuperación. Solicita uno nuevo.',
        child: AuthErrorBanner(message: 'Token de recuperación ausente.'),
      );
    }

    return AuthFormScaffold(
      title: 'Crea una contraseña nueva',
      subtitle:
          'Al finalizar, el servidor debe revocar las sesiones anteriores.',
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
                  : const Text('Guardar contraseña'),
            ),
          ],
        ),
      ),
    );
  }
}
