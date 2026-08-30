import 'academic_profile_models.dart';

abstract interface class ExamGoalRepository {
  Future<PersonalExamGoal?> load(String userId);

  Future<void> save(PersonalExamGoal goal);
}
