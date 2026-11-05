import 'vocational_orientation.dart';

abstract interface class VocationalOrientationRepository {
  Future<VocationalQuestionnaire> questionnaire();
  Future<VocationalAttempt?> current();
  Future<VocationalAttempt> start();
  Future<VocationalAttempt> saveAnswer(
    String attemptId,
    String questionId,
    VocationalAnswer answer,
  );
  Future<VocationalAttempt> finish(String attemptId);
  Future<VocationalHistory> history(int page);
  Future<VocationalAttempt> getAttempt(String attemptId);
  Future<void> deleteAttempt(String attemptId);
}
