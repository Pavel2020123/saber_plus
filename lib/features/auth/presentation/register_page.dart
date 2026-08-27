import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth_models.dart';
import 'auth_form_scaffold.dart';
import 'session_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _referralCode = TextEditingController();
  String? _grade;
  bool _acceptedPolicies = false;
  bool _guardianConsent = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _referralCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedPolicies || !_guardianConsent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes confirmar las autorizaciones para continuar.'),
        ),
      );
      return;
    }

    final result = await ref
        .read(sessionControllerProvider.notifier)
        .register(
          RegistrationRequest(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim().toLowerCase(),
            password: _password.text,
            grade: _grade!,
            acceptedPolicyVersion: '2026-08-26',
            guardianConsent: _guardianConsent,
            referralCode: _referralCode.text.trim(),
          ),
        );
    if (result == null || !mounted) return;
    context.go(
      Uri(
        path: '/verify-pending',
        queryParameters: {'email': result.email},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    return AuthFormScaffold(
      title: 'Crea tu cuenta',
      subtitle: 'Comienza con un diagnóstico y recibe un plan a tu medida.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session.errorMessage case final message?) ...[
              AuthErrorBanner(message: message),
              const SizedBox(height: 18),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _NameField(controller: _firstName, label: 'Nombre'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NameField(controller: _lastName, label: 'Apellido'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (value) => (value?.contains('@') ?? false)
                  ? null
                  : 'Escribe un correo válido',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _grade,
              decoration: const InputDecoration(
                labelText: 'Grado',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              items: const [
                DropdownMenuItem(value: '9', child: Text('Noveno')),
                DropdownMenuItem(value: '10', child: Text('Décimo')),
                DropdownMenuItem(value: '11', child: Text('Once')),
                DropdownMenuItem(
                  value: 'graduate',
                  child: Text('Ya me gradué'),
                ),
              ],
              onChanged: (value) => setState(() => _grade = value),
              validator: (value) =>
                  value == null ? 'Selecciona tu grado' : null,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmPassword,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _referralCode,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Código de referido (opcional)',
                prefixIcon: Icon(Icons.card_giftcard_rounded),
              ),
            ),
            const SizedBox(height: 18),
            CheckboxListTile(
              value: _acceptedPolicies,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Acepto los términos y la política de privacidad vigentes.',
              ),
              onChanged: (value) =>
                  setState(() => _acceptedPolicies = value ?? false),
            ),
            CheckboxListTile(
              value: _guardianConsent,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Confirmo la autorización de mi acudiente o institución cuando aplica.',
              ),
              subtitle: const Text(
                'El servidor debe registrar la versión, fecha y responsable.',
              ),
              onChanged: (value) =>
                  setState(() => _guardianConsent = value ?? false),
            ),
            const SizedBox(height: 18),
            FilledButton(
              key: const Key('register-button'),
              onPressed: session.isLoading ? null : _submit,
              child: session.isLoading
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.label});
  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(labelText: label),
    validator: (value) => (value?.trim().length ?? 0) < 2 ? 'Requerido' : null,
  );
}
