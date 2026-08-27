import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/auth/domain/auth_models.dart';
import 'package:saber_plus/features/auth/domain/session.dart';

void main() {
  test('interpreta la respuesta de login móvil', () {
    final result = LoginResult.fromJson({
      'accessToken': 'access-token',
      'usuario': {
        'id': 'user-1',
        'nombre': 'Laura Gómez',
        'correo': 'laura@example.com',
        'rol': 'PROFESOR',
        'debeCambiarContrasena': false,
      },
    });

    expect(result.tokens.accessToken, 'access-token');
    expect(result.user.role, AppRole.teacher);
    expect(result.user.firstName, 'Laura Gómez');
    expect(result.user.emailVerified, isFalse);
  });

  test('registro genera exactamente los campos aceptados por el backend', () {
    const request = RegistrationRequest(
      firstName: 'Ana',
      lastName: 'Pérez',
      email: 'ana@example.com',
      password: 'Password123',
      referralCode: '',
    );

    final json = request.toBackendJson();

    expect(json, {
      'nombre': 'Ana Pérez',
      'correo': 'ana@example.com',
      'contrasena': 'Password123',
    });
  });
}
