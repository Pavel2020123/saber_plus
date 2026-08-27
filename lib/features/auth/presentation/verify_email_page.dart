import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_form_scaffold.dart';
import 'session_controller.dart';

class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({required this.token, super.key});

  final String token;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  bool? _success;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_verify);
  }

  Future<void> _verify() async {
    if (widget.token.isEmpty) {
      setState(() => _success = false);
      return;
    }
    final success = await ref
        .read(sessionControllerProvider.notifier)
        .verifyEmail(widget.token);
    if (mounted) setState(() => _success = success);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final isWaiting = _success == null && session.errorMessage == null;
    return AuthFormScaffold(
      title: isWaiting
          ? 'Verificando correo'
          : _success == true
          ? 'Correo verificado'
          : 'No pudimos verificarlo',
      subtitle: isWaiting
          ? 'Espera un momento mientras confirmamos tu enlace.'
          : _success == true
          ? 'Tu prueba gratuita puede comenzar ahora.'
          : 'El enlace puede haber vencido o ya fue utilizado.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isWaiting)
            const Center(child: CircularProgressIndicator())
          else
            Icon(
              _success == true
                  ? Icons.verified_rounded
                  : Icons.link_off_rounded,
              size: 88,
              color: _success == true
                  ? Colors.green
                  : Theme.of(context).colorScheme.error,
            ),
          if (session.errorMessage case final message?) ...[
            const SizedBox(height: 18),
            AuthErrorBanner(message: message),
          ],
          if (!isWaiting) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/login'),
              child: const Text('Ir al ingreso'),
            ),
          ],
        ],
      ),
    );
  }
}
