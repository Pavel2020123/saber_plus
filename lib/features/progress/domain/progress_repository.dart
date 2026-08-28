import '../../practice/domain/practice_models.dart';
import 'progress_models.dart';

abstract interface class ProgressRepository {
  Future<ProgressDashboard> loadDashboard();

  Future<ErrorNotebook> loadNotebook(NotebookFilter filter);

  Future<void> updateNotebookEntry({
    required String questionId,
    required String note,
    required NotebookStatus status,
  });

  Future<AdaptiveProfile> loadAdaptiveProfile();

  Future<AdaptiveSessionStart> startAdaptiveSession(int questionCount);

  Future<AdaptiveGradeResult> gradeAdaptiveSession({
    required String attemptId,
    required List<PracticeAnswer> answers,
  });
}
