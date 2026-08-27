import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/network/api_error.dart';

void main() {
  test('interpreta errores personalizados del backend', () {
    final error = ApiError.fromJson({
      'codigo': 'CORREO_NO_VERIFICADO',
      'mensaje': 'Debes verificar tu correo.',
    });

    expect(error.code, 'CORREO_NO_VERIFICADO');
    expect(error.message, 'Debes verificar tu correo.');
  });

  test('agrupa los mensajes de validación de NestJS', () {
    final error = ApiError.fromJson({
      'statusCode': 400,
      'message': ['El correo no es válido', 'La contraseña es obligatoria'],
    });

    expect(error.code, '400');
    expect(error.message, contains('El correo no es válido'));
    expect(error.message, contains('La contraseña es obligatoria'));
  });
}
