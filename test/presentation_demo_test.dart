import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/config/environment.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/data/demo_practice_repository.dart';
import 'package:saber_plus/features/practice/domain/practice_models.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';
import 'package:saber_plus/main_demo.dart' as presentation;

void main() {
  test('presentation rejects real environments and disabled demo', () {
    for (final environment in AppEnvironment.values) {
      for (final demo in [false, true]) {
        final config = AppConfig(
          environment: environment,
          apiBaseUrl: 'https://example.invalid',
          demoMode: demo,
        );
        expect(
          () => presentation.validatePresentationConfig(config),
          environment == AppEnvironment.dev && demo
              ? returnsNormally
              : throwsStateError,
        );
      }
    }
  });

  for (final area in AcademicArea.values) {
    test(
      '${area.name}: lesson and two gradable questions without a server',
      () async {
        final catalog = StudyCatalog.demo(area);
        final lesson = catalog.themes.single.subtopics.single;
        expect(lesson.content!.length, greaterThan(200));
        expect(
          lesson.content,
          isNot(contains('Esta es una lección demostrativa')),
        );
        final repository = DemoPracticeRepository();
        final session = await repository.startSubtopicPractice(
          area: area,
          subtopicId: lesson.id,
        );
        expect(session.questions.length, lesson.totalQuestions);
        expect(
          session.questions.map((question) => question.statement).toSet(),
          hasLength(2),
        );
        final result = await repository.gradePractice(
          attemptId: session.attemptId,
          area: area,
          answers: [
            for (final question in session.questions)
              PracticeAnswer(
                questionId: question.id,
                answerId: question.options.first.id,
                responseTimeSeconds: 5,
              ),
          ],
        );
        expect(result.summary.percentage, 100);
        expect(
          result.review.every(
            (question) => question.explanation?.isNotEmpty ?? false,
          ),
          isTrue,
        );
      },
    );
  }
}
