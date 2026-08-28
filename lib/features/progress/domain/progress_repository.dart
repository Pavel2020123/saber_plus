import 'progress_models.dart';

abstract interface class ProgressRepository {
  Future<ProgressDashboard> loadDashboard();

  Future<ErrorNotebook> loadNotebook(NotebookFilter filter);

  Future<void> updateNotebookEntry({
    required String questionId,
    required String note,
    required NotebookStatus status,
  });
}
