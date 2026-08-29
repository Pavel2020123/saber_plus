import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/practice/domain/correct_answer_streak.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

void main() {
  test('detecta la racha correcta más larga', () {
    final streak = CorrectAnswerStreak.fromReview([
      _reviewQuestion('1', true),
      _reviewQuestion('2', true),
      _reviewQuestion('3', true),
      _reviewQuestion('4', false),
      _reviewQuestion('5', true),
    ]);

    expect(streak.longestRun, 3);
    expect(streak.earnsFeedback, isTrue);
  });

  test('no entrega feedback con menos de tres aciertos consecutivos', () {
    final streak = CorrectAnswerStreak.fromReview([
      _reviewQuestion('1', true),
      _reviewQuestion('2', false),
      _reviewQuestion('3', true),
      _reviewQuestion('4', true),
    ]);

    expect(streak.longestRun, 2);
    expect(streak.earnsFeedback, isFalse);
  });
}

PracticeReviewQuestion _reviewQuestion(String id, bool isCorrect) =>
    PracticeReviewQuestion(
      id: id,
      statement: 'Pregunta $id',
      isCorrect: isCorrect,
      selectedAnswerId: 'answer-a',
      correctAnswerId: isCorrect ? 'answer-a' : 'answer-b',
      options: const [
        PracticeReviewOption(id: 'answer-a', text: 'A', isCorrect: true),
        PracticeReviewOption(id: 'answer-b', text: 'B', isCorrect: false),
      ],
    );
