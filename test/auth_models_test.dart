import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/auth/domain/auth_models.dart';
import 'package:saber_plus/features/auth/domain/session.dart';

void main() {
  test('interpreta la respuesta de login móvil', () {
    final result = LoginResult.fromJson({
      'accessToken': 'access-token',
      'refreshToken': 'refresh-token',
      'user': {
        'id': 'user-1',
        'firstName': 'Laura',
        'email': 'laura@example.com',
        'role': 'teacher',
        'emailVerified': true,
        'mustChangePassword': false,
      },
    });

    expect(result.tokens.accessToken, 'access-token');
    expect(result.tokens.refreshToken, 'refresh-token');
    expect(result.user.role, AppRole.teacher);
    expect(result.user.emailVerified, isTrue);
  });

  test('registro omite un referido vacío y conserva consentimiento', () {
    const request = RegistrationRequest(
      firstName: 'Ana',
      lastName: 'Pérez',
      email: 'ana@example.com',
      password: 'password123',
      grade: '11',
      acceptedPolicyVersion: '2026-08-26',
      guardianConsent: true,
      referralCode: '',
    );

    final json = request.toJson();

    expect(json, isNot(contains('referralCode')));
    expect(json['guardianConsent'], isTrue);
    expect(json['acceptedPolicyVersion'], '2026-08-26');
  });
}
