import 'safe_sync_models.dart';

abstract interface class SafeSyncRepository {
  Stream<List<SyncOperation>> watchOperations(String userId);

  Future<SafeWriteResult> saveStudyProgress({
    required String userId,
    required String subtopicId,
    required int percentage,
  });

  Future<SafeWriteResult> saveNotebookEntry({
    required String userId,
    required String questionId,
    required String note,
    required String status,
  });

  Future<SyncReport> synchronize(String userId);

  Future<SyncReport> retry(String userId, String operationId);

  Future<void> discard(String userId, String operationId);
}
