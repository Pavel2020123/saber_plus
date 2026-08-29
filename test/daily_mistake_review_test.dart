import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/domain/daily_mistake_review.dart';
import 'package:saber_plus/features/practice/domain/practice_history_models.dart';

void main() {
  test('conserva solo el fallo más reciente de cada pregunta de hoy', () {
    final today = DateTime(2026, 8, 29, 18);
    final history = AnswerHistory(
      summary: const AnswerHistorySummary(
        total: 5,
        correct: 1,
        incorrect: 4,
        successPercentage: 20,
      ),
      answers: [
        _answer(
          id: 'old-question-1',
          questionId: 'question-1',
          answeredAt: DateTime(2026, 8, 29, 8),
        ),
        _answer(
          id: 'latest-question-1',
          questionId: 'question-1',
          answeredAt: DateTime(2026, 8, 29, 15),
        ),
        _answer(
          id: 'question-2',
          questionId: 'question-2',
          answeredAt: DateTime(2026, 8, 29, 13),
        ),
        _answer(
          id: 'yesterday',
          questionId: 'question-3',
          answeredAt: DateTime(2026, 8, 28, 23, 59),
        ),
        _answer(
          id: 'correct',
          questionId: 'question-4',
          answeredAt: DateTime(2026, 8, 29, 16),
          isCorrect: true,
        ),
      ],
    );

    final review = DailyMistakeReview.fromHistory(history, day: today);

    expect(review.day, DateTime(2026, 8, 29));
    expect(review.mistakes.map((answer) => answer.id), [
      'latest-question-1',
      'question-2',
    ]);
  });
}

AnswerHistoryItem _answer({
  required String id,
  required String questionId,
  required DateTime answeredAt,
  bool isCorrect = false,
}) => AnswerHistoryItem(
  id: id,
  sessionId: 'session-1',
  questionId: questionId,
  statement: 'Pregunta de prueba',
  difficulty: 'MEDIA',
  area: AcademicArea.mathematics,
  origin: PracticeOrigin.subtopic,
  isCorrect: isCorrect,
  answeredAt: answeredAt,
  theme: 'Proporciones',
  subtopic: 'Regla de tres',
);
