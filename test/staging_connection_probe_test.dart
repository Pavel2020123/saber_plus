import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/config/environment.dart';
import 'package:saber_plus/core/network/staging_connection_probe.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/login_page.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';

const _config = AppConfig(
  environment: AppEnvironment.staging,
  apiBaseUrl: 'https://api.example.com',
  demoMode: false,
);

void main() {
  test('el archivo compartido selecciona staging real sin secretos', () {
    final json =
        jsonDecode(File('config/staging.json').readAsStringSync()) as Map;
    expect(json.keys.toSet(), {
      'APP_ENV',
      'API_BASE_URL',
      'CONTENT_BASE_URL',
      'DEMO_MODE',
    });
    expect(json['APP_ENV'], 'staging');
    expect(json['DEMO_MODE'], 'false');
    final config = AppConfig(
      environment: AppConfig.parseEnvironment(json['APP_ENV'] as String),
      apiBaseUrl: json['API_BASE_URL'] as String,
      contentBaseUrl: json['CONTENT_BASE_URL'] as String,
      demoMode: false,
    );
    expect(config.validate, returnsNormally);
  });

  test(
    'solo usa tres GET sin tokens y el 401 es el resultado esperado',
    () async {
      final requests = <RequestOptions>[];
      final dio = _dio((request) {
        requests.add(request);
        return request.path == '/auth/perfil'
            ? (401, {'message': 'Unauthorized'})
            : (
                200,
                {'service': 'saberplus-api', 'status': 'OK', 'database': 'UP'},
              );
      });
      addTearDown(() => dio.close(force: true));
      final report = await StagingConnectionProbe(dio).check();
      expect(report.passed, isTrue);
      expect(requests.map((r) => r.path), [
        '/health/live',
        '/health/ready',
        '/auth/perfil',
      ]);
      for (final request in requests) {
        expect(request.method, 'GET');
        expect(request.followRedirects, isFalse);
        expect(
          request.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('authorization')),
        );
        expect(
          request.headers.keys.map((k) => k.toLowerCase()),
          isNot(contains('cookie')),
        );
      }
    },
  );

  test('no declara la base lista si falta database UP', () async {
    final dio = _dio(
      (r) => (200, {'service': 'saberplus-api', 'status': 'OK'}),
    );
    final report = await StagingConnectionProbe(dio).check();
    expect(report.passed, isFalse);
    expect(report.checks.length, 2);
    expect(report.checks.first.passed, isTrue);
    expect(report.checks.last.passed, isFalse);
  });

  test(
    'perfil abierto sin token falla y nunca muestra datos recibidos',
    () async {
      final dio = _dio(
        (r) => r.path == '/auth/perfil'
            ? (200, {'correo': 'PRIVATE_VALUE'})
            : (
                200,
                {'service': 'saberplus-api', 'status': 'OK', 'database': 'UP'},
              ),
      );
      final report = await StagingConnectionProbe(dio).check();
      expect(report.passed, isFalse);
      expect(report.checks.length, 3);
      expect(report.checks.last.message, isNot(contains('PRIVATE_VALUE')));
    },
  );

  test('no sigue redirecciones ni acepta una página HTML', () async {
    for (final response in [
      (302, '<html>redirect</html>'),
      (200, '<html>not the API</html>'),
    ]) {
      final report = await StagingConnectionProbe(
        _dio((_) => response),
      ).check();
      expect(report.passed, isFalse);
      expect(report.checks.length, 1);
    }
  });

  test('timeout produce aviso seguro sin reintentos automáticos', () async {
    var requests = 0;
    final dio = StagingConnectionProbe.createClient(_config);
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests++;
          handler.reject(
            DioException(
              requestOptions: request,
              type: DioExceptionType.receiveTimeout,
              error: 'PRIVATE_TRACE',
            ),
          );
        },
      ),
    );
    final report = await StagingConnectionProbe(dio).check();
    expect(requests, 1);
    expect(report.passed, isFalse);
    expect(report.checks.single.message, contains('despertando'));
    expect(report.checks.single.message, isNot(contains('PRIVATE_TRACE')));
  });

  test(
    'cancelar interrumpe la comprobación sin convertirla en un fallo remoto',
    () async {
      final token = CancelToken()..cancel();
      await expectLater(
        StagingConnectionProbe(
          _dio((_) => (200, {})),
        ).check(cancelToken: token),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
    },
  );

  testWidgets('staging ofrece comprobación sin botones de demostración', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(_config),
          sessionControllerProvider.overrideWith(_Unauthenticated.new),
          stagingConnectionReportProvider.overrideWith(
            (ref) async => const StagingConnectionReport([
              ConnectionCheck(
                label: 'API disponible',
                passed: true,
                message: 'OK',
              ),
              ConnectionCheck(
                label: 'Base de datos accesible',
                passed: true,
                message: 'OK',
              ),
              ConnectionCheck(
                label: 'Perfil protegido sin sesión',
                passed: true,
                message: 'HTTP 401 esperado',
              ),
            ]),
          ),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('student-demo-button')), findsNothing);
    final check = find.byKey(const Key('check-staging-connection'));
    await tester.ensureVisible(check);
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(find.text('Conexión básica verificada'), findsOneWidget);
    expect(find.textContaining('no crea cuentas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Dio _dio((int, Object) Function(RequestOptions request) answer) {
  final dio = StagingConnectionProbe.createClient(_config);
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        final result = answer(request);
        handler.resolve(
          Response(
            requestOptions: request,
            statusCode: result.$1,
            data: result.$2,
          ),
        );
      },
    ),
  );
  return dio;
}

class _Unauthenticated extends SessionController {
  @override
  SessionState build() => const SessionState.unauthenticated();
}
