import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
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
}
