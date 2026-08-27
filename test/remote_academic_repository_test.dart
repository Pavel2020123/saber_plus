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

  test('finaliza enviando cada respuesta y su tiempo al backend', () async {
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
                'estado': 'COMPLETADO',
                'diagnosticoId': 'diagnostic-1',
                'totalPreguntas': 1,
                'respuestasCorrectas': 1,
                'porcentaje': 100,
                'nivel': 'FORTALEZA',
                'resultadosPorArea': <Object>[],
              },
            ),
          );
        },
      ),
    );

    final result = await RemoteAcademicRepository(dio).finishDiagnostic(const [
      DiagnosticAnswer(
        questionId: 'question-1',
        answerId: 'answer-1',
        responseTimeSeconds: 17,
      ),
    ]);

    expect(captured.method, 'POST');
    expect(captured.path, '/diagnostico-inicial/finalizar');
    expect(captured.data, {
      'respuestas': [
        {
          'preguntaId': 'question-1',
          'respuestaId': 'answer-1',
          'tiempoRespuestaSegundos': 17,
        },
      ],
    });
    expect(result.status, DiagnosticStatus.completed);
  });

  test('agrupa las falencias del cuaderno por tema y subtema', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'resumen': {
                  'total': 2,
                  'pendientes': 2,
                  'repasando': 0,
                  'dominados': 0,
                },
                'errores': [
                  {
                    'preguntaId': 'question-1',
                    'area': 'MATEMATICAS',
                    'tema': 'Razones y proporciones',
                    'subtema': 'Regla de tres',
                  },
                  {
                    'preguntaId': 'question-2',
                    'area': 'MATEMATICAS',
                    'tema': 'Razones y proporciones',
                    'subtema': 'Regla de tres',
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final topics = await RemoteAcademicRepository(dio).loadWeakTopics();

    expect(topics, hasLength(1));
    expect(topics.single.subtopic, 'Regla de tres');
    expect(topics.single.failedQuestions, 2);
  });
}
