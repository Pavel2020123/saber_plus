import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/data/remote_practice_repository.dart';
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
