import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/environment.dart';
import '../domain/session.dart';
import 'auth_form_scaffold.dart';
import 'session_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref
        .read(sessionControllerProvider.notifier)
        .signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (!success || !mounted) return;

    final user = ref.read(sessionControllerProvider).user;
    if (user?.mustChangePassword ?? false) {
      context.go('/change-initial-password');
    } else {
      context.go(user?.role == AppRole.teacher ? '/teacher' : '/student/home');
    }
  }

  void _enterDemo(AppRole role) {
    ref.read(sessionControllerProvider.notifier).enterDemo(role: role);
    context.go(role == AppRole.teacher ? '/teacher' : '/student/home');
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    final session = ref.watch(sessionControllerProvider);
    final colors = Theme.of(context).colorScheme;

    return AuthFormScaffold(
      title: 'Qué bueno verte',
      subtitle: 'Ingresa para continuar con tu preparación.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session.errorMessage case final message?) ...[
              AuthErrorBanner(message: message),
              const SizedBox(height: 18),
            ],
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty || !email.contains('@')) {
                  return 'Escribe un correo válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _passwordController,
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  (value?.length ?? 0) < 6 ? 'Usa al menos 6 caracteres' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: session.isLoading
                    ? null
                    : () => context.push('/forgot-password'),
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('login-button'),
              onPressed: session.isLoading ? null : _submit,
              child: session.isLoading
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Iniciar sesión'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: session.isLoading
                  ? null
                  : () => context.push('/register'),
              child: const Text('Crear una cuenta'),
            ),
            if (config.demoMode) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: colors.outlineVariant)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'DEMOSTRACIÓN',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: colors.outlineVariant)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Permite revisar la interfaz sin enviar credenciales.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                key: const Key('student-demo-button'),
                onPressed: () => _enterDemo(AppRole.student),
                icon: const Icon(Icons.science_outlined),
                label: const Text('Explorar como estudiante'),
              ),
              TextButton.icon(
                onPressed: () => _enterDemo(AppRole.teacher),
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('Explorar como profesor'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
