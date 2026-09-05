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

  test('staging también rechaza una API sin HTTPS', () {
    const config = AppConfig(
      environment: AppEnvironment.staging,
      apiBaseUrl: 'http://api.example.com',
      demoMode: false,
    );

    expect(config.validate, throwsStateError);
  });

  test('producción exige HTTPS para los recursos académicos', () {
    const config = AppConfig(
      environment: AppEnvironment.prod,
      apiBaseUrl: 'https://api.example.com',
      contentBaseUrl: 'http://content.example.com',
      demoMode: false,
    );

    expect(config.validate, throwsStateError);
  });
}
