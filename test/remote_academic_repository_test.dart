import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/data/remote_academic_repository.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';

void main() {
  test('combina convocatoria, diagnóstico y plan semanal reales', () async {
    final paths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          paths.add(options.path);
          final data = switch (options.path) {
            '/calendario-icfes/activo' => {
              'calendario': {
                'id': 'calendar-1',
                'anio': 2026,
                'calendario': 'A',
                'fechaExamen': '2026-09-06T00:00:00.000Z',
              },
            },
            '/diagnostico-inicial' => {'estado': 'NO_INICIADO'},
            '/plan-estudio/semanal' => {'estado': 'DIAGNOSTICO_PENDIENTE'},
            _ => throw StateError('Ruta inesperada: ${options.path}'),
          };
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );

    final data = await RemoteAcademicRepository(dio).loadHome();

    expect(
      paths,
      containsAll(<String>[
        '/calendario-icfes/activo',
        '/diagnostico-inicial',
        '/plan-estudio/semanal',
      ]),
    );
    expect(data.activeExam?.calendar, 'A');
    expect(data.diagnostic.status, DiagnosticStatus.notStarted);
    expect(data.plan.status, StudyPlanStatus.diagnosticPending);
  });

  test('inicia el diagnóstico mediante el endpoint protegido', () async {
    late RequestOptions captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'estado': 'EN_PROGRESO',
                'diagnosticoId': 'diagnostic-1',
                'totalPreguntas': 15,
                'iniciadoEn': '2026-08-27T10:00:00.000Z',
                'preguntas': <Object>[],
              },
            ),
          );
        },
      ),
    );

    final diagnostic = await RemoteAcademicRepository(dio).startDiagnostic();

    expect(captured.method, 'POST');
    expect(captured.path, '/diagnostico-inicial/iniciar');
    expect(diagnostic.status, DiagnosticStatus.inProgress);
    expect(diagnostic.totalQuestions, 15);
  });
}
