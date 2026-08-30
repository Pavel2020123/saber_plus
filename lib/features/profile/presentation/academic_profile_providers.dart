import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academic/presentation/academic_home_controller.dart';
import '../../auth/presentation/session_controller.dart';
import '../../progress/domain/progress_models.dart';
import '../../progress/presentation/progress_providers.dart';
import '../data/shared_preferences_exam_goal_repository.dart';
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
