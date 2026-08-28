import '../../academic/domain/academic_models.dart';
import '../../practice/domain/practice_history_models.dart';
import '../../study/domain/study_models.dart';
import '../domain/progress_models.dart';
import '../domain/progress_repository.dart';

class DemoProgressRepository implements ProgressRepository {
  @override
  Future<ProgressDashboard> loadDashboard() async => ProgressDashboard(
    study: const StudyProgress(
      totalSubtopics: 5,
      viewedSubtopics: 3,
      completedSubtopics: 2,
      overallPercentage: 48,
      bySubtopic: {},
    ),
    answers: const AnswerHistorySummary(
      total: 24,
      correct: 15,
      incorrect: 9,
      successPercentage: 62.5,
    ),
    byArea: {
      for (final area in AcademicArea.values)
        area: AnswerHistorySummary(
          total: 4,
          correct: area == AcademicArea.mathematics ? 2 : 3,
          incorrect: area == AcademicArea.mathematics ? 2 : 1,
          successPercentage: area == AcademicArea.mathematics ? 50 : 75,
        ),
    },
  );

  @override
  Future<ErrorNotebook> loadNotebook(NotebookFilter filter) async =>
      ErrorNotebook.empty;

  @override
  Future<void> updateNotebookEntry({
    required String questionId,
    required String note,
    required NotebookStatus status,
  }) async {}
}
