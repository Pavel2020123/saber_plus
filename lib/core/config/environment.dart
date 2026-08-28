import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { dev, staging, prod }

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.demoMode,
    this.contentBaseUrl,
  });

  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool demoMode;
  final String? contentBaseUrl;

  String get contentRoot => contentBaseUrl ?? apiBaseUrl;

  void validate() {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL no es una URL válida.');
    }
    if (environment == AppEnvironment.prod && uri.scheme != 'https') {
      throw StateError('La aplicación de producción requiere una API HTTPS.');
    }
    if (contentBaseUrl case final value?) {
      final contentUri = Uri.tryParse(value);
      if (contentUri == null ||
          !contentUri.hasScheme ||
          contentUri.host.isEmpty) {
        throw StateError('CONTENT_BASE_URL no es una URL válida.');
      }
      if (environment == AppEnvironment.prod && contentUri.scheme != 'https') {
        throw StateError(
          'Los recursos académicos de producción requieren HTTPS.',
        );
      }
    }
  }

  static AppConfig get current {
    const environmentName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'dev',
    );
    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000',
    );
    const demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);
    const contentBaseUrl = String.fromEnvironment('CONTENT_BASE_URL');

    return AppConfig(
      environment: AppEnvironment.values.firstWhere(
        (value) => value.name == environmentName,
        orElse: () => AppEnvironment.dev,
      ),
      apiBaseUrl: apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
      demoMode: demoMode,
      contentBaseUrl: contentBaseUrl.isEmpty
          ? null
          : contentBaseUrl.replaceFirst(RegExp(r'/$'), ''),
    );
  }
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.current);
