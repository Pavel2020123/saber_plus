import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_form_scaffold.dart';
import 'session_controller.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(sessionControllerProvider.notifier)
        .requestPasswordReset(_email.text);
    if (success && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    return AuthFormScaffold(
      title: _sent ? 'Revisa tu correo' : 'Recupera tu cuenta',
      subtitle: _sent
          ? 'Si existe una cuenta asociada, enviaremos un enlace para crear una contraseña nueva.'
          : 'Escribe el correo con el que te registraste.',
      child: _sent
          ? const _SentMessage()
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (session.errorMessage case final message?) ...[
                    AuthErrorBanner(message: message),
                    const SizedBox(height: 18),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                    validator: (value) => (value?.contains('@') ?? false)
                        ? null
                        : 'Escribe un correo válido',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: session.isLoading ? null : _submit,
                    child: session.isLoading
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar enlace'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SentMessage extends StatelessWidget {
  const _SentMessage();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(
        Icons.mark_email_read_outlined,
        size: 88,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 18),
      const Text(
        'Por seguridad, mostramos el mismo mensaje aunque el correo no esté registrado.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}
