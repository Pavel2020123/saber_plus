import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/data/demo_practice_repository.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';

void main() {
  test('define 150 preguntas en dos jornadas independientes', () {
    expect(OfficialSimulationBlock.values, hasLength(2));
    expect(OfficialSimulationBlock.questionCount, 75);
    expect(OfficialSimulationBlock.totalQuestionCount, 150);
    expect(
      OfficialSimulationBlock.tryFromSlug('am'),
      OfficialSimulationBlock.morning,
    );
    expect(
      OfficialSimulationBlock.afternoon.routeLocation,
      '/student/practice/official/pm',
    );
  });

  test('la demostración entrega y califica una jornada completa', () async {
    final repository = DemoPracticeRepository();
    const block = OfficialSimulationBlock.morning;

    final session = await repository.startRandomPractice(block.practiceConfig);

    expect(session.questions, hasLength(75));
    expect(
      session.questions.map((question) => question.id).toSet(),
      hasLength(75),
    );
    expect(
      session.questions.map((question) => question.area).toSet(),
      containsAll(AcademicArea.values),
    );
    expect(block.accepts(session), isTrue);

    final result = await repository.gradeRandomPractice(
      attemptId: session.attemptId,
      answers: [
        for (final question in session.questions)
          PracticeAnswer(
            questionId: question.id,
            answerId: question.id.endsWith('-2') ? 'answer-e' : 'answer-a',
            responseTimeSeconds: 30,
          ),
      ],
    );

    expect(result.summary.totalQuestions, 75);
    expect(result.summary.correctAnswers, 75);
    expect(result.review, hasLength(75));
  });
}
