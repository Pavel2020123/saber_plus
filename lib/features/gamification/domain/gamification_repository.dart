import 'gamification_models.dart';

abstract interface class GamificationRepository {
  Future<GamificationSummary> loadSummary();
}
