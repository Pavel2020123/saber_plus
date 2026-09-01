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
        'requiereVerificacionCorreo': false,
        'debeCambiarContrasena': false,
      },
    });

    expect(result.tokens.accessToken, 'access-token');
    expect(result.user.role, AppRole.teacher);
    expect(result.user.firstName, 'Laura Gómez');
    expect(result.user.emailVerified, isFalse);
    expect(result.user.requiresEmailVerification, isFalse);
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
      'rol': 'ESTUDIANTE',
    });
  });

  test('registro de profesor no envía un código de referido', () {
    const request = RegistrationRequest(
      firstName: 'Andrea',
      lastName: 'Docente',
      email: 'andrea@example.com',
      password: 'Password123',
      referralCode: 'AMIGO10',
      accountType: RegistrationAccountType.teacher,
    );

    expect(request.toBackendJson(), {
      'nombre': 'Andrea Docente',
      'correo': 'andrea@example.com',
      'contrasena': 'Password123',
      'rol': 'PROFESOR',
    });
  });

  test('perfil identifica que un estudiante debe verificar su correo', () {
    final user = UserSession.fromBackendJson({
      'id': 'user-2',
      'nombre': 'Ana Pérez',
      'correo': 'ana@example.com',
      'rol': 'ESTUDIANTE',
      'correoVerificado': false,
      'requiereVerificacionCorreo': true,
      'debeCambiarContrasena': false,
    });

    expect(user.emailVerified, isFalse);
    expect(user.requiresEmailVerification, isTrue);
  });
}
