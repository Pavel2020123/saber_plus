import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/config/environment.dart';

void main() {
  test('producción rechaza una API sin HTTPS', () {
    const config = AppConfig(
      environment: AppEnvironment.prod,
      apiBaseUrl: 'http://api.example.com',
      demoMode: false,
    );

    expect(config.validate, throwsStateError);
  });

  test('producción acepta una API HTTPS válida', () {
    const config = AppConfig(
      environment: AppEnvironment.prod,
      apiBaseUrl: 'https://api.example.com',
      demoMode: false,
    );

    expect(config.validate, returnsNormally);
  });
}
