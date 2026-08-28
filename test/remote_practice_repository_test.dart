import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/data/remote_practice_repository.dart';
import 'package:saber_plus/features/practice/domain/practice_history_models.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

void main() {
  test('abre la práctica usando el subtema y conserva el intento', () async {
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
                'intentoId': 'attempt-1',
                'preguntas': [_questionJson],
              },
            ),
          );
        },
      ),
    );

    final session = await RemotePracticeRepository(dio).startSubtopicPractice(
      area: AcademicArea.mathematics,
      subtopicId: 'subtopic con espacio',
    );

    expect(captured.path, '/simulacros/preguntas/subtopic%20con%20espacio');
    expect(session.attemptId, 'attempt-1');
    expect(session.questions.single.statement, '¿Cuánto cuesta?');
  });

  test('califica con origen PRACTICA, área y tiempos de respuesta', () async {
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
                'resumen': {
                  'totalPreguntas': 1,
                  'respuestasCorrectas': 1,
                  'respuestasIncorrectas': 0,
                  'puntaje': '100.00%',
                  'xpGanado': 60,
                },
                'detalle': [
                  {
                    'preguntaId': 'question-1',
                    'enunciado': '¿Cuánto cuesta?',
                    'esCorrecto': true,
                    'respuestaSeleccionadaId': 'answer-a',
                    'respuestaCorrectaId': 'answer-a',
                    'explicacion': 'Explicación',
                    'respuestas': [
                      {
                        'id': 'answer-a',
                        'texto': '20',
                        'esCorrecta': true,
                        'explicacion': null,
                      },
                    ],
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final result = await RemotePracticeRepository(dio).gradePractice(
      attemptId: 'attempt-1',
      area: AcademicArea.mathematics,
      answers: const [
        PracticeAnswer(
          questionId: 'question-1',
          answerId: 'answer-a',
          responseTimeSeconds: 18,
        ),
      ],
    );

    expect(captured.path, '/simulacros/calificar');
    expect(captured.data['intentoId'], 'attempt-1');
    expect(captured.data['area'], 'MATEMATICAS');
    expect(captured.data['origen'], 'PRACTICA');
    expect(captured.data['respuestas'], [
      {
        'preguntaId': 'question-1',
        'respuestaId': 'answer-a',
        'tiempoRespuestaSegundos': 18,
      },
    ]);
    expect(result.summary.percentage, 100);
    expect(result.summary.earnedXp, 60);
  });

  test(
    'genera preguntas aleatorias con áreas, cantidad y dificultad',
    () async {
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
                  'intentoId': 'random-attempt-1',
                  'preguntas': [
                    _questionJson,
                    _questionJsonForArea(
                      id: 'question-2',
                      area: 'LECTURA_CRITICA',
                    ),
                  ],
                },
              ),
            );
          },
        ),
      );

      final session = await RemotePracticeRepository(dio).startRandomPractice(
        const RandomPracticeConfig(
          areas: [AcademicArea.mathematics, AcademicArea.criticalReading],
          questionCount: 10,
          difficulty: PracticeDifficulty.medium,
        ),
      );

      expect(captured.path, '/simulacros/generar-personalizado');
      expect(captured.queryParameters, {
        'areas': 'MATEMATICAS,LECTURA_CRITICA',
        'cantidad': 10,
        'dificultad': 'MEDIO',
      });
      expect(session.isRandom, isTrue);
      expect(session.questions, hasLength(2));
    },
  );

  test('califica el intento aleatorio sin inventar un área única', () async {
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
                    'enunciado': '¿Cuánto cuesta?',
                    'esCorrecto': true,
                    'respuestaSeleccionadaId': 'answer-a',
                    'respuestaCorrectaId': 'answer-a',
                    'respuestas': [
                      {'id': 'answer-a', 'texto': '20', 'esCorrecta': true},
                    ],
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    await RemotePracticeRepository(dio).gradeRandomPractice(
      attemptId: 'random-attempt-1',
      answers: const [
        PracticeAnswer(
          questionId: 'question-1',
          answerId: 'answer-a',
          responseTimeSeconds: 9,
        ),
      ],
    );

    expect(captured.path, '/simulacros/calificar-personalizado');
    expect(captured.data.keys, containsAll(['intentoId', 'respuestas']));
    expect(captured.data.containsKey('area'), isFalse);
    expect(captured.data.containsKey('origen'), isFalse);
  });

  test('genera el simulacro completo para una sola área', () async {
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
                'intentoId': 'simulation-attempt-1',
                'totalPreguntas': 1,
                'preguntas': [_questionJson],
              },
            ),
          );
        },
      ),
    );

    final session = await RemotePracticeRepository(
      dio,
    ).startAreaSimulation(AcademicArea.mathematics);

    expect(captured.path, '/simulacros/generar');
    expect(captured.queryParameters, {'area': 'MATEMATICAS'});
    expect(session.isSimulation, isTrue);
    expect(session.attemptId, 'simulation-attempt-1');
  });

  test('califica el simulacro completo con origen SIMULACRO', () async {
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
              data: _gradedResponse,
            ),
          );
        },
      ),
    );

    await RemotePracticeRepository(dio).gradeAreaSimulation(
      attemptId: 'simulation-attempt-1',
      area: AcademicArea.mathematics,
      answers: const [
        PracticeAnswer(
          questionId: 'question-1',
          answerId: 'answer-a',
          responseTimeSeconds: 30,
        ),
      ],
    );

    expect(captured.path, '/simulacros/calificar');
    expect(captured.data['area'], 'MATEMATICAS');
    expect(captured.data['origen'], 'SIMULACRO');
  });

  test('consulta historial de respuestas con filtros reales', () async {
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
                  'total': 1,
                  'correctas': 0,
                  'incorrectas': 1,
                  'porcentajeAciertos': 0,
                },
                'respuestas': [_historyAnswerJson],
              },
            ),
          );
        },
      ),
    );

    final history = await RemotePracticeRepository(dio).loadAnswerHistory(
      const AnswerHistoryFilter(
        area: AcademicArea.mathematics,
        outcome: AnswerOutcomeFilter.incorrect,
        limit: 100,
      ),
    );

    expect(captured.path, '/simulacros/historial-respuestas');
    expect(captured.queryParameters, {
      'area': 'MATEMATICAS',
      'resultado': 'incorrectas',
      'limite': 100,
    });
    expect(history.answers.single.subtopic, 'Regla de tres');
  });

  test('consulta los últimos resultados de simulacro', () async {
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
                'totalSimulacros': 1,
                'resultados': [
                  {
                    'id': 'result-1',
                    'area': 'MATEMATICAS',
                    'totalPreguntas': 25,
                    'respuestasCorrectas': 20,
                    'puntaje': 80,
                    'xpGanado': 250,
                    'fechaRealizado': '2026-08-28T15:30:00.000Z',
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final history = await RemotePracticeRepository(dio).loadSimulationHistory();

    expect(captured.path, '/simulacros/historial');
    expect(history.results.single.percentage, 80);
  });
}

const _questionJson = {
  'id': 'question-1',
  'enunciado': '¿Cuánto cuesta?',
  'dificultad': 'MEDIA',
  'respuestas': [
    {'id': 'answer-a', 'texto': '20'},
  ],
  'subtema': {
    'nombre': 'Regla de tres',
    'tema': {'nombre': 'Proporciones', 'area': 'MATEMATICAS'},
  },
};

Map<String, dynamic> _questionJsonForArea({
  required String id,
  required String area,
}) => {
  ..._questionJson,
  'id': id,
  'subtema': {
    'nombre': 'Subtema',
    'tema': {'nombre': 'Tema', 'area': area},
  },
};

const _gradedResponse = {
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
      'enunciado': '¿Cuánto cuesta?',
      'esCorrecto': true,
      'respuestaSeleccionadaId': 'answer-a',
      'respuestaCorrectaId': 'answer-a',
      'respuestas': [
        {'id': 'answer-a', 'texto': '20', 'esCorrecta': true},
      ],
    },
  ],
};

const _historyAnswerJson = {
  'id': 'history-1',
  'sesionId': 'session-1',
  'preguntaId': 'question-1',
  'enunciado': '¿Cuánto cuesta?',
  'explicacion': 'Divide y multiplica.',
  'dificultad': 'MEDIO',
  'area': 'MATEMATICAS',
  'origen': 'SIMULACRO',
  'esCorrecta': false,
  'tiempoRespuestaSegundos': 30,
  'fechaRespuesta': '2026-08-28T15:31:00.000Z',
  'respuestaSeleccionada': {'id': 'answer-b', 'texto': '15'},
  'respuestaCorrecta': {'id': 'answer-a', 'texto': '20', 'explicacion': null},
  'tema': 'Proporciones',
  'subtema': 'Regla de tres',
  'caso': null,
};
