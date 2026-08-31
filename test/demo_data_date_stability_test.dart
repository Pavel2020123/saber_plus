import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/practice/data/demo_practice_repository.dart';
import 'package:saber_plus/features/practice/domain/daily_mistake_review.dart';
import 'package:saber_plus/features/practice/domain/practice_history_models.dart';
import 'package:saber_plus/features/study_time/data/demo_study_time_repository.dart';
import 'package:saber_plus/features/study_time/domain/study_time_models.dart';

void main() {
  final mondayAfterMidnight = DateTime(2026, 8, 31, 0, 1);

  test(
    'la demostración conserva el error de hoy después de medianoche',
    () async {
      final repository = DemoPracticeRepository(now: () => mondayAfterMidnight);

      final history = await repository.loadAnswerHistory(
        const AnswerHistoryFilter(
          outcome: AnswerOutcomeFilter.incorrect,
          limit: 100,
        ),
      );
      final review = DailyMistakeReview.fromHistory(
        history,
        day: mondayAfterMidnight,
      );

      expect(review.mistakes, hasLength(1));
      expect(review.mistakes.single.subtopic, 'Regla de tres');
    },
  );

  test(
    'la demostración conserva sus 105 minutos al iniciar una semana',
    () async {
      final repository = DemoStudyTimeRepository(now: mondayAfterMidnight);
      addTearDown(repository.dispose);

      final records = await repository.watchAll('demo-student').first;
      final summary = StudyTimeSummary.fromRecords(
        records,
        now: mondayAfterMidnight,
      );

      expect(summary.totalSeconds, 105 * 60);
      expect(summary.todaySeconds, 105 * 60);
      expect(summary.lastSevenDaysSeconds, 105 * 60);
    },
  );
}
