import 'package:shared_preferences/shared_preferences.dart';

import '../domain/academic_profile_models.dart';
import '../domain/exam_goal_repository.dart';

class SharedPreferencesExamGoalRepository implements ExamGoalRepository {
  SharedPreferencesExamGoalRepository([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _keyPrefix = 'saberplus.exam-goal.';

  final SharedPreferencesAsync _preferences;

  @override
  Future<PersonalExamGoal?> load(String userId) async {
    final score = await _preferences.getInt('$_keyPrefix$userId');
    if (score == null || !PersonalExamGoal.isValidScore(score)) return null;
    return PersonalExamGoal(userId: userId, targetScore: score);
  }

  @override
  Future<void> save(PersonalExamGoal goal) {
    if (!PersonalExamGoal.isValidScore(goal.targetScore)) {
      throw RangeError.range(
        goal.targetScore,
        PersonalExamGoal.minimumScore,
        PersonalExamGoal.maximumScore,
        'targetScore',
      );
    }
    return _preferences.setInt('$_keyPrefix${goal.userId}', goal.targetScore);
  }
}
