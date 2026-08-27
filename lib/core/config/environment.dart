import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.demoMode,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool demoMode;

  static AppConfig get current {
    const environmentName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'dev',
    );
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000/v1',
    );
    const demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);

    return AppConfig(
      environment: AppEnvironment.values.firstWhere(
        (value) => value.name == environmentName,
        orElse: () => AppEnvironment.dev,
      ),
      apiBaseUrl: apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
      demoMode: demoMode,
    );
  }
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.current);
