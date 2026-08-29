import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/data/practice_draft_store.dart';
import 'package:saber_plus/features/practice/domain/practice_history_models.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

void main() {
  test('interpreta una sesión protegida sin exponer respuestas correctas', () {
    final session = PracticeSession.fromJson(
      {
        'intentoId': 'attempt-1',
        'preguntas': [
          {
            'id': 'question-1',
            'enunciado': '¿Cuál es el resultado?',
            'dificultad': 'MEDIA',
            'ordenEnCaso': 1,
            'caso': {
              'id': 'case-1',
              'titulo': 'Situación',
              'contexto': 'Lee el caso.',
              'imagenUrl': null,
            },
            'respuestas': [
              {'id': 'answer-a', 'texto': '10'},
              {'id': 'answer-b', 'texto': '20'},
            ],
            'subtema': {
              'id': 'subtopic-1',
              'nombre': 'Regla de tres',
              'tema': {'nombre': 'Proporciones', 'area': 'MATEMATICAS'},
            },
          },
        ],
      },
      area: AcademicArea.mathematics,
      subtopicId: 'subtopic-1',
    );

    expect(session.attemptId, 'attempt-1');
    expect(session.questions.single.options, hasLength(2));
    expect(session.questions.single.caseContent?.title, 'Situación');
    expect(session.questions.single.area, AcademicArea.mathematics);
    expect(session.questions.single.subtopicId, 'subtopic-1');
  });

  test('interpreta puntaje, XP y revisión después de calificar', () {
    final result = PracticeResult.fromJson({
      'resumen': {
        'totalPreguntas': 1,
        'respuestasCorrectas': 0,
        'respuestasIncorrectas': 1,
        'puntaje': '0.00%',
        'xpGanado': 0,
      },
      'detalle': [
        {
          'preguntaId': 'question-1',
          'enunciado': '¿Cuál es el resultado?',
          'esCorrecto': false,
          'respuestaSeleccionadaId': 'answer-b',
          'respuestaCorrectaId': 'answer-a',
          'explicacion': 'Divide y luego multiplica.',
          'respuestas': [
            {
              'id': 'answer-a',
              'texto': '10',
              'esCorrecta': true,
              'explicacion': 'Esta es la proporción correcta.',
            },
            {
              'id': 'answer-b',
              'texto': '20',
              'esCorrecta': false,
              'explicacion': null,
            },
          ],
        },
      ],
    });

    expect(result.summary.percentage, 0);
    expect(result.review.single.isCorrect, isFalse);
    expect(result.review.single.correctAnswerId, 'answer-a');
    expect(result.review.single.options.first.isCorrect, isTrue);
  });

  test(
    'serializa el intento público para reanudarlo sin respuestas correctas',
    () {
      final now = DateTime.utc(2026, 8, 27, 15);
      final session = PracticeSession.fromJson(
        {
          'intentoId': 'attempt-1',
          'preguntas': [
            {
              'id': 'question-1',
              'enunciado': 'Pregunta',
              'dificultad': 'MEDIA',
              'respuestas': [
                {'id': 'answer-a', 'texto': 'Opción pública'},
              ],
              'subtema': {
                'id': 'subtopic-1',
                'nombre': 'Subtema',
                'tema': {'nombre': 'Tema', 'area': 'MATEMATICAS'},
              },
            },
          ],
        },
        area: AcademicArea.mathematics,
        subtopicId: 'subtopic-1',
      );
      final draft = PracticeDraft(
        session: session,
        selectedAnswers: const {'question-1': 'answer-a'},
        responseTimesSeconds: const {'question-1': 14},
        currentIndex: 0,
        startedAt: now,
        expiresAt: now.add(const Duration(minutes: 115)),
      );

      final restored = PracticeDraft.fromJson(draft.toJson());

      expect(restored.session.attemptId, 'attempt-1');
      expect(restored.selectedAnswers['question-1'], 'answer-a');
      expect(restored.responseTimesSeconds['question-1'], 14);
      expect(
        restored.session.questions.single.options.single.text,
        'Opción pública',
      );
      expect(restored.session.questions.single.subtopicId, 'subtopic-1');
      expect(draft.toJson().toString(), isNot(contains('esCorrecta')));
    },
  );

  test('construye y recupera la ruta de una sesión aleatoria', () {
    const config = RandomPracticeConfig(
      areas: [AcademicArea.mathematics, AcademicArea.english],
      questionCount: 20,
      difficulty: PracticeDifficulty.hard,
    );

    final restored = RandomPracticeConfig.tryFromUri(
      Uri.parse(config.routeLocation),
    );

    expect(restored?.areas, [AcademicArea.mathematics, AcademicArea.english]);
    expect(restored?.questionCount, 20);
    expect(restored?.difficulty, PracticeDifficulty.hard);
  });

  test('interpreta resultados recientes y fechas del historial', () {
    final history = SimulationHistory.fromJson({
      'totalSimulacros': 1,
      'resultados': [
        {
          'id': 'result-1',
          'area': 'MATEMATICAS',
          'totalPreguntas': 25,
          'respuestasCorrectas': 20,
          'puntaje': 80.0,
          'xpGanado': 250,
          'fechaRealizado': '2026-08-28T15:30:00.000Z',
        },
      ],
    });

    expect(history.total, 1);
    expect(history.results.single.area, AcademicArea.mathematics);
    expect(history.results.single.percentage, 80);
    expect(history.results.single.completedAt.isUtc, isFalse);
  });

  test('interpreta la revisión histórica de una respuesta', () {
    final history = AnswerHistory.fromJson({
      'resumen': {
        'total': 1,
        'correctas': 0,
        'incorrectas': 1,
        'porcentajeAciertos': 0,
      },
      'respuestas': [
        {
          'id': 'history-1',
          'sesionId': 'session-1',
          'preguntaId': 'question-1',
          'enunciado': '¿Cuál es el resultado?',
          'explicacion': 'Divide y multiplica.',
          'dificultad': 'MEDIO',
          'area': 'MATEMATICAS',
          'origen': 'SIMULACRO',
          'esCorrecta': false,
          'tiempoRespuestaSegundos': 25,
          'fechaRespuesta': '2026-08-28T15:31:00.000Z',
          'respuestaSeleccionada': {'id': 'answer-b', 'texto': '15'},
          'respuestaCorrecta': {
            'id': 'answer-a',
            'texto': '20',
            'explicacion': 'Correcta',
          },
          'tema': 'Proporciones',
          'subtema': 'Regla de tres',
          'caso': {'id': 'case-1', 'titulo': 'Compra escolar'},
        },
      ],
    });

    final answer = history.answers.single;
    expect(answer.origin, PracticeOrigin.simulation);
    expect(answer.correctAnswer?.text, '20');
    expect(answer.caseTitle, 'Compra escolar');
  });
}
