import 'learning_resume_models.dart';

abstract interface class LearningResumeRepository {
  Stream<LearningResume?> watch(String userId);

  Future<void> save(LearningResume entry);

  Future<void> clear(String userId);
}
