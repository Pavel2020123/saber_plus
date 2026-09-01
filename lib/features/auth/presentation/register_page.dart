import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth_models.dart';
import '../domain/password_policy.dart';
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
  var _accountType = RegistrationAccountType.student;

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
    final result = await ref
        .read(sessionControllerProvider.notifier)
        .register(
          RegistrationRequest(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            email: _email.text.trim().toLowerCase(),
            password: _password.text,
            referralCode: _referralCode.text.trim(),
            accountType: _accountType,
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
      subtitle: _accountType == RegistrationAccountType.student
          ? 'Comienza con un diagnóstico y recibe un plan a tu medida.'
          : 'Crea tu cuenta personal y luego vincula tu institución.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (session.errorMessage case final message?) ...[
              AuthErrorBanner(message: message),
              const SizedBox(height: 18),
            ],
            Text(
              'Tipo de cuenta',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<RegistrationAccountType>(
              key: const Key('registration-account-type'),
              segments: const [
                ButtonSegment(
                  value: RegistrationAccountType.student,
                  icon: Icon(Icons.school_outlined),
                  label: Text('Estudiante'),
                ),
                ButtonSegment(
                  value: RegistrationAccountType.teacher,
                  icon: Icon(Icons.co_present_outlined),
                  label: Text('Profesor'),
                ),
              ],
              selected: {_accountType},
              onSelectionChanged: (selection) {
                setState(() => _accountType = selection.first);
                if (_accountType == RegistrationAccountType.teacher) {
                  _referralCode.clear();
                }
              },
            ),
            const SizedBox(height: 10),
            Text(
              _accountType == RegistrationAccountType.student
                  ? 'La cuenta tendrá acceso a estudio, prácticas y juegos.'
                  : 'No se crean cuentas compartidas de colegio. Cada profesor usa su propio correo y contraseña.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
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
            PasswordField(
              controller: _password,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmPassword,
              label: 'Confirmar contraseña',
              validator: (value) {
                final policyError = validateStrongPassword(value);
                if (policyError != null) return policyError;
                if (value != _password.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
            if (_accountType == RegistrationAccountType.student) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _referralCode,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código de referido (opcional)',
                  prefixIcon: Icon(Icons.card_giftcard_rounded),
                ),
              ),
            ],
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
