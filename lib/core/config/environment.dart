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
    if (environment != AppEnvironment.dev && demoMode) {
      throw StateError('Staging y producción requieren DEMO_MODE=false.');
    }
    final uri = Uri.tryParse(apiBaseUrl);
    if (!_safeHttpUrl(uri)) {
      throw StateError('API_BASE_URL no es una URL válida.');
    }
    if (environment != AppEnvironment.dev && uri!.scheme != 'https') {
      throw StateError('Staging y producción requieren una API HTTPS.');
    }
    if (contentBaseUrl case final value?) {
      final contentUri = Uri.tryParse(value);
      if (!_safeHttpUrl(contentUri)) {
        throw StateError('CONTENT_BASE_URL no es una URL válida.');
      }
      if (environment != AppEnvironment.dev && contentUri!.scheme != 'https') {
        throw StateError(
          'Los recursos académicos de staging y producción requieren HTTPS.',
        );
      }
    }
  }

  static bool _safeHttpUrl(Uri? uri) =>
      uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment;

  static AppEnvironment parseEnvironment(String name) =>
      AppEnvironment.values.firstWhere(
        (value) => value.name == name,
        orElse: () => throw StateError('APP_ENV debe ser dev, staging o prod.'),
      );

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
      environment: parseEnvironment(environmentName),
      apiBaseUrl: apiBaseUrl.replaceFirst(RegExp(r'/$'), ''),
      demoMode: demoMode,
      contentBaseUrl: contentBaseUrl.isEmpty
          ? null
          : contentBaseUrl.replaceFirst(RegExp(r'/$'), ''),
    );
  }
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.current);
