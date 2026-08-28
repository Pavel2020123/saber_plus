import 'gamification_models.dart';

abstract interface class GamificationRepository {
  Future<GamificationSummary> loadSummary();

  Future<AchievementCertificate?> findCertificate({
    required String userId,
    required Achievement achievement,
  });

  Future<AchievementCertificate> downloadCertificate({
    required String userId,
    required Achievement achievement,
  });
}
