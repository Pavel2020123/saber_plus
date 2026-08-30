import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academic/presentation/academic_home_controller.dart';
import '../../auth/presentation/session_controller.dart';
import '../../gamification/domain/gamification_models.dart';
import '../../gamification/presentation/gamification_providers.dart';
import '../../progress/domain/progress_models.dart';
import '../../progress/presentation/progress_providers.dart';
import '../../study_time/presentation/study_time_providers.dart';
import '../data/shared_preferences_exam_goal_repository.dart';
import '../domain/academic_activity_report.dart';
import '../domain/academic_profile_models.dart';
import '../domain/exam_goal_repository.dart';

final academicProfileProgressProvider =
    FutureProvider.autoDispose<ProgressDashboard>(
      (ref) => ref.watch(progressRepositoryProvider).loadDashboard(),
    );

final academicAreaInsightsProvider = Provider<AcademicAreaInsights>((ref) {
  final progress = ref.watch(academicProfileProgressProvider).valueOrNull;
  if (progress == null) return AcademicAreaInsights.empty;
  final diagnostic = ref
      .watch(academicHomeControllerProvider)
      .valueOrNull
      ?.diagnostic;
  return AcademicAreaInsights.fromSources(
    progress: progress,
    diagnostic: diagnostic,
  );
});

final academicActivityReportProvider =
    FutureProvider.autoDispose<AcademicActivityReport>((ref) async {
      final records = await ref.watch(studyTimeRecordsProvider.future);

      List<DailyActivity>? activity;
      try {
        activity = (await ref.watch(
          gamificationSummaryProvider.future,
        )).activity;
      } on Object {
        activity = null;
      }

      int? weeklyTargetMinutes;
      try {
        weeklyTargetMinutes = (await ref.watch(
          academicHomeControllerProvider.future,
        )).plan.targetMinutes;
      } on Object {
        weeklyTargetMinutes = null;
      }

      return AcademicActivityReport.fromSources(
        now: ref.watch(studyTimeNowProvider)(),
        studyRecords: records,
        dailyActivity: activity,
        weeklyTargetMinutes: weeklyTargetMinutes,
      );
    });

final examGoalRepositoryProvider = Provider<ExamGoalRepository>(
  (ref) => SharedPreferencesExamGoalRepository(),
);

class ExamGoalController extends AutoDisposeAsyncNotifier<PersonalExamGoal?> {
  @override
  Future<PersonalExamGoal?> build() async {
    final userId = ref.watch(
      sessionControllerProvider.select((session) => session.user?.id),
    );
    if (userId == null) return null;
    return ref.watch(examGoalRepositoryProvider).load(userId);
  }

  Future<bool> setTargetScore(int score) async {
    final userId = ref.read(sessionControllerProvider).user?.id;
    if (userId == null || !PersonalExamGoal.isValidScore(score)) return false;
    final previous = state;
    state = const AsyncLoading<PersonalExamGoal?>().copyWithPrevious(previous);
    try {
      final goal = PersonalExamGoal(userId: userId, targetScore: score);
      await ref.read(examGoalRepositoryProvider).save(goal);
      state = AsyncData(goal);
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncError<PersonalExamGoal?>(
        error,
        stackTrace,
      ).copyWithPrevious(previous);
      return false;
    }
  }
}

final examGoalControllerProvider =
    AutoDisposeAsyncNotifierProvider<ExamGoalController, PersonalExamGoal?>(
      ExamGoalController.new,
    );
