import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/config/environment.dart';

void main() {
  test('un nombre de ambiente incorrecto no cae silenciosamente en dev', () {
    expect(() => AppConfig.parseEnvironment('stagging'), throwsStateError);
    expect(AppConfig.parseEnvironment('staging'), AppEnvironment.staging);
  });

  for (final environment in [AppEnvironment.staging, AppEnvironment.prod]) {
    test('$environment rechaza datos demo', () {
      final config = AppConfig(
        environment: environment,
        apiBaseUrl: 'https://api.example.com',
        demoMode: true,
      );
      expect(config.validate, throwsStateError);
    });
  }

  for (final url in [
    'postgresql://user:password@db.example.com/app',
    'https://user:password@api.example.com',
    'https://api.example.com?token=secret',
    'https://api.example.com#fragment',
    'ftp://api.example.com',
  ]) {
    test(
      'rechaza esquema o credenciales incrustadas: ${Uri.parse(url).scheme}',
      () {
        final config = AppConfig(
          environment: AppEnvironment.dev,
          apiBaseUrl: url,
          demoMode: true,
        );
        expect(config.validate, throwsStateError);
        final resources = AppConfig(
          environment: AppEnvironment.dev,
          apiBaseUrl: 'http://localhost:3000',
          contentBaseUrl: url,
          demoMode: true,
        );
        expect(resources.validate, throwsStateError);
      },
    );
  }

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
