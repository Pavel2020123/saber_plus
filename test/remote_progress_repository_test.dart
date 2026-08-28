import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';
import 'package:saber_plus/features/progress/data/remote_progress_repository.dart';
import 'package:saber_plus/features/progress/domain/progress_models.dart';

void main() {
  test(
    'combina aprendizaje y rendimiento global por las cinco áreas',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options);
            if (options.path == '/simulacros/progreso') {
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'totalSubtemas': 10,
                    'temasVistos': 6,
                    'temasCompletados': 4,
                    'porcentajeGeneral': 55,
                    'porSubtema': <String, int>{},
                  },
                ),
              );
              return;
            }
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'resumen': {
                    'total': 8,
                    'correctas': 6,
                    'incorrectas': 2,
                    'porcentajeAciertos': 75,
                  },
                  'respuestas': <Object>[],
                },
              ),
            );
          },
        ),
      );

      final dashboard = await RemoteProgressRepository(dio).loadDashboard();

      expect(requests, hasLength(7));
      expect(dashboard.study.overallPercentage, 55);
      expect(dashboard.answers.total, 8);
      expect(dashboard.byArea.keys, containsAll(AcademicArea.values));
      expect(
        requests
            .where(
              (request) => request.path == '/simulacros/historial-respuestas',
            )
            .every((request) => request.queryParameters['limite'] == 1),
        isTrue,
      );
    },
  );

  test('envía los filtros del cuaderno con los valores del backend', () async {
    late RequestOptions captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'resumen': {
                  'total': 0,
                  'pendientes': 0,
                  'repasando': 0,
                  'dominados': 0,
                },
                'errores': <Object>[],
              },
            ),
          );
        },
      ),
    );

    await RemoteProgressRepository(dio).loadNotebook(
      const NotebookFilter(
        area: AcademicArea.english,
        status: NotebookStatus.mastered,
      ),
    );

    expect(captured.path, '/cuaderno-errores');
    expect(captured.queryParameters, {'area': 'INGLES', 'estado': 'DOMINADO'});
  });

  test('guarda la nota y estado de una pregunta con PATCH', () async {
    late RequestOptions captured;
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'preguntaId': 'question 1',
                'nota': 'Repasar proporciones',
                'estado': 'REPASANDO',
              },
            ),
          );
        },
      ),
    );

    await RemoteProgressRepository(dio).updateNotebookEntry(
      questionId: 'question 1',
      note: '  Repasar proporciones  ',
      status: NotebookStatus.reviewing,
    );

    expect(captured.method, 'PATCH');
    expect(captured.path, '/cuaderno-errores/question%201');
    expect(captured.data, {
      'nota': 'Repasar proporciones',
      'estado': 'REPASANDO',
    });
  });

  test('consulta el perfil adaptativo protegido', () async {
    late RequestOptions captured;
    final dio = _adaptiveDio((options) => captured = options);

    final profile = await RemoteProgressRepository(dio).loadAdaptiveProfile();

    expect(captured.method, 'GET');
    expect(captured.path, '/repaso-adaptativo/perfil');
    expect(profile.analyzedAttempts, 12);
    expect(profile.priorityAreas.first, AcademicArea.mathematics);
  });

  test('genera un intento adaptativo con cantidad limitada', () async {
    late RequestOptions captured;
    final dio = _adaptiveDio((options) => captured = options);

    final start = await RemoteProgressRepository(dio).startAdaptiveSession(50);

    expect(captured.method, 'POST');
    expect(captured.path, '/repaso-adaptativo/generar');
    expect(captured.queryParameters['cantidad'], 30);
    expect(start.session.isAdaptive, isTrue);
    expect(start.session.questions.single.options, hasLength(2));
    expect(start.plan.questionMix.medium, 1);
  });

  test('califica el repaso y recibe el perfil siguiente', () async {
    late RequestOptions captured;
    final dio = _adaptiveDio((options) => captured = options);

    final grade = await RemoteProgressRepository(dio).gradeAdaptiveSession(
      attemptId: '11111111-1111-4111-8111-111111111111',
      answers: const [
        PracticeAnswer(
          questionId: 'question-1',
          answerId: 'answer-a',
          responseTimeSeconds: 19,
        ),
      ],
    );

    expect(captured.method, 'POST');
    expect(captured.path, '/repaso-adaptativo/calificar');
    expect(captured.data, {
      'intentoId': '11111111-1111-4111-8111-111111111111',
      'respuestas': [
        {
          'preguntaId': 'question-1',
          'respuestaId': 'answer-a',
          'tiempoRespuestaSegundos': 19,
        },
      ],
    });
    expect(grade.result.summary.percentage, 100);
    expect(grade.nextProfile.analyzedAttempts, 12);
  });
}

Dio _adaptiveDio(void Function(RequestOptions options) capture) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        capture(options);
        final data = switch (options.path) {
          '/repaso-adaptativo/perfil' => _profileJson,
          '/repaso-adaptativo/generar' => {
            'intentoId': '11111111-1111-4111-8111-111111111111',
            'totalPreguntas': 1,
            'adaptacion': {
              'nivelObjetivo': 'MEDIO',
              'precisionReciente': 60,
              'areasPrioritarias': ['MATEMATICAS'],
              'mezcla': {'BASICO': 0, 'MEDIO': 1, 'AVANZADO': 0},
            },
            'preguntas': [_questionJson],
          },
          '/repaso-adaptativo/calificar' => {
            'resumen': {
              'totalPreguntas': 1,
              'respuestasCorrectas': 1,
              'respuestasIncorrectas': 0,
              'puntaje': '100%',
              'xpGanado': 60,
            },
            'detalle': [
              {
                'preguntaId': 'question-1',
                'enunciado': '¿Cuánto es 2 + 2?',
                'esCorrecto': true,
                'respuestaSeleccionadaId': 'answer-a',
                'respuestaCorrectaId': 'answer-a',
                'explicacion': 'Se suman ambos valores.',
                'respuestas': [
                  {'id': 'answer-a', 'texto': '4', 'esCorrecta': true},
                  {'id': 'answer-b', 'texto': '5', 'esCorrecta': false},
                ],
              },
            ],
            'perfilSiguiente': _profileJson,
          },
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
  return dio;
}

const _profileJson = <String, dynamic>{
  'intentosAnalizados': 12,
  'precisionReciente': 60,
  'nivelObjetivo': 'MEDIO',
  'rendimientoPorArea': [
    {'area': 'MATEMATICAS', 'intentos': 5, 'precision': 40, 'prioridad': 60},
  ],
  'areasPrioritarias': ['MATEMATICAS'],
  'mezclaRecomendada': {'BASICO': 25, 'MEDIO': 60, 'AVANZADO': 15},
};

const _questionJson = <String, dynamic>{
  'id': 'question-1',
  'enunciado': '¿Cuánto es 2 + 2?',
  'dificultad': 'MEDIO',
  'respuestas': [
    {'id': 'answer-a', 'texto': '4'},
    {'id': 'answer-b', 'texto': '5'},
  ],
  'subtema': {
    'nombre': 'Operaciones',
    'tema': {'nombre': 'Aritmética', 'area': 'MATEMATICAS'},
  },
};
