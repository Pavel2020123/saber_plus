import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/auth/domain/password_policy.dart';

void main() {
  test('acepta la política real del backend', () {
    expect(validateStrongPassword('SaberPlus2026'), isNull);
  });

  test('exige mayúscula, número y longitud válida', () {
    expect(validateStrongPassword('saberplus1'), contains('mayúscula'));
    expect(validateStrongPassword('Saberplus'), contains('número'));
    expect(validateStrongPassword('Abc1'), contains('8 y 72'));
  });
}
