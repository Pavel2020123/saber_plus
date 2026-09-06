import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/environment.dart';

class ConnectionCheck {
  const ConnectionCheck({
    required this.label,
    required this.passed,
    required this.message,
  });
  final String label;
  final bool passed;
  final String message;
}

class StagingConnectionReport {
  const StagingConnectionReport(this.checks);
  final List<ConnectionCheck> checks;
  bool get passed =>
      checks.length == 3 && checks.every((check) => check.passed);
}

/// Exclusivamente GET, sin iniciar sesión, cookies, tokens ni escrituras.
/// No comparte el cliente autenticado: el 401 esperado no revoca la sesión.
class StagingConnectionProbe {
  StagingConnectionProbe(this.dio);
  final Dio dio;

  static Dio createClient(AppConfig config) {
    config.validate();
    if (config.environment != AppEnvironment.staging) {
      throw StateError('Esta comprobación es exclusiva de staging.');
    }
    return Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 15),
        followRedirects: false,
        headers: const {'Accept': 'application/json'},
      ),
    );
  }

  Future<StagingConnectionReport> check({CancelToken? cancelToken}) async {
    final checks = <ConnectionCheck>[];
    for (final spec in const [
      ('/health/live', 'API disponible'),
      ('/health/ready', 'Base de datos accesible'),
      ('/auth/perfil', 'Perfil protegido sin sesión'),
    ]) {
      try {
        final response = await dio.get<Object?>(
          spec.$1,
          cancelToken: cancelToken,
          options: Options(followRedirects: false, validateStatus: (_) => true),
        );
        final body = response.data;
        final passed = spec.$1 == '/auth/perfil'
            ? response.statusCode == 401
            : response.statusCode == 200 &&
                  body is Map &&
                  body['service'] == 'saberplus-api' &&
                  body['status'] == 'OK' &&
                  (spec.$1 != '/health/ready' || body['database'] == 'UP');
        checks.add(
          ConnectionCheck(
            label: spec.$2,
            passed: passed,
            message: passed
                ? spec.$1 == '/auth/perfil'
                      ? 'HTTP 401 esperado: no expone el perfil sin token.'
                      : 'Respuesta correcta del servidor.'
                : 'La respuesta no coincide con el contrato esperado (HTTP ${response.statusCode ?? 0}).',
          ),
        );
        if (!passed) break;
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) rethrow;
        checks.add(
          ConnectionCheck(
            label: spec.$2,
            passed: false,
            message: switch (error.type) {
              DioExceptionType.receiveTimeout ||
              DioExceptionType.connectionTimeout =>
                'El servidor tardó demasiado. Puede estar despertando; espera y vuelve a comprobar.',
              _ =>
                'No se pudo completar la conexión. Revisa la red y la disponibilidad del servidor.',
            },
          ),
        );
        break;
      }
    }
    return StagingConnectionReport(List.unmodifiable(checks));
  }
}

final stagingConnectionReportProvider =
    FutureProvider.autoDispose<StagingConnectionReport>((ref) async {
      final dio = StagingConnectionProbe.createClient(
        ref.watch(appConfigProvider),
      );
      final cancellation = CancelToken();
      ref.onDispose(() {
        cancellation.cancel();
        dio.close(force: true);
      });
      return StagingConnectionProbe(dio).check(cancelToken: cancellation);
    });
