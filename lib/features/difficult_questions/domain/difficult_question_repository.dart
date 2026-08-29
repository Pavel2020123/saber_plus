import 'difficult_question_models.dart';

abstract interface class DifficultQuestionRepository {
  Stream<List<DifficultQuestionMark>> watchAll(String userId);

  Stream<bool> watchContains(String userId, String questionId);

  Future<bool> toggle(DifficultQuestionMark mark);

  Future<void> remove(String userId, String questionId);
}
