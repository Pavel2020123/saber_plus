import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/auth/data/remote_auth_repository.dart';
import 'package:saber_plus/features/auth/domain/auth_models.dart';

void main() {
  test('login usa la ruta y el DTO en español del backend', () async {
    late RequestOptions captured;
    final dio = _respondingDio(
      onRequest: (options) => captured = options,
      response: {
        'accessToken': 'jwt',
        'usuario': {
          'id': 'user-1',
          'nombre': 'Laura Gómez',
          'correo': 'laura@example.com',
          'rol': 'ESTUDIANTE',
          'debeCambiarContrasena': false,
        },
      },
    );
    final repository = RemoteAuthRepository(dio, dio);

    await repository.login(email: 'laura@example.com', password: 'Password1');

    expect(captured.path, '/auth/login');
    expect(captured.data, {
      'correo': 'laura@example.com',
      'contrasena': 'Password1',
    });
  });

  test('registro no envía campos rechazados por el ValidationPipe', () async {
    late RequestOptions captured;
    final dio = _respondingDio(
      onRequest: (options) => captured = options,
      response: {'mensaje': 'Cuenta creada', 'usuarioId': 'user-2'},
    );
    final repository = RemoteAuthRepository(dio, dio);

    final result = await repository.register(
      const RegistrationRequest(
        firstName: 'Ana',
        lastName: 'Pérez',
        email: 'ana@example.com',
        password: 'Password1',
        referralCode: 'AMIGO10',
      ),
    );

    expect(captured.path, '/auth/registro');
    expect(captured.data, {
      'nombre': 'Ana Pérez',
      'correo': 'ana@example.com',
      'contrasena': 'Password1',
      'rol': 'ESTUDIANTE',
      'codigoReferido': 'AMIGO10',
    });
    expect(result.userId, 'user-2');
    expect(result.email, 'ana@example.com');
  });

  test('restablecimiento usa nuevaContrasena', () async {
    late RequestOptions captured;
    final dio = _respondingDio(
      onRequest: (options) => captured = options,
      response: {'mensaje': 'Contraseña actualizada'},
    );
    final repository = RemoteAuthRepository(dio, dio);

    await repository.resetPassword(token: 'token', password: 'Password1');

    expect(captured.path, '/auth/restablecer-contrasena');
    expect(captured.data, {'token': 'token', 'nuevaContrasena': 'Password1'});
  });
}

Dio _respondingDio({
  required void Function(RequestOptions options) onRequest,
  required Map<String, dynamic> response,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        onRequest(options);
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 200,
            data: response,
          ),
        );
      },
    ),
  );
  return dio;
}
