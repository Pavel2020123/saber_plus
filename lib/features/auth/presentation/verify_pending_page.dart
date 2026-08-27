import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_form_scaffold.dart';
import 'session_controller.dart';

class VerifyPendingPage extends ConsumerWidget {
  const VerifyPendingPage({required this.email, super.key});

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    return AuthFormScaffold(
      title: 'Verifica tu correo',
      subtitle:
          'Enviamos un enlace a $email. Tu prueba comienza cuando el correo quede verificado.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.outgoing_mail,
            size: 88,
            color: Theme.of(context).colorScheme.primary,
          ),
          if (session.errorMessage case final message?) ...[
            const SizedBox(height: 18),
            AuthErrorBanner(message: message),
          ],
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: session.isLoading || email.isEmpty
                ? null
                : () async {
                    final success = await ref
                        .read(sessionControllerProvider.notifier)
                        .resendVerification(email);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enlace reenviado.')),
                      );
                    }
                  },
            child: const Text('Reenviar enlace'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Volver al ingreso'),
          ),
        ],
      ),
    );
  }
}
