import '../../../core/network/api_error.dart';
import '../domain/gamification_models.dart';
import '../domain/gamification_repository.dart';

class DemoGamificationRepository implements GamificationRepository {
  @override
  Future<AchievementCertificate> downloadCertificate({
    required String userId,
    required Achievement achievement,
  }) => throw const ApiError(
    code: 'demo_certificate',
    message:
        'Los certificados personales están disponibles al ingresar con una cuenta real.',
  );

  @override
  Future<AchievementCertificate?> findCertificate({
    required String userId,
    required Achievement achievement,
  }) async => null;

  @override
  Future<GamificationSummary> loadSummary() async {
    final today = DateTime.now();
    return GamificationSummary(
      streak: StudyStreak(
        current: 4,
        best: 7,
        activeToday: true,
        lastActivity: today,
      ),
      activity: [
        DailyActivity(date: today.subtract(const Duration(days: 6)), count: 2),
        DailyActivity(date: today.subtract(const Duration(days: 4)), count: 5),
        DailyActivity(date: today.subtract(const Duration(days: 3)), count: 3),
        DailyActivity(date: today.subtract(const Duration(days: 2)), count: 7),
        DailyActivity(date: today.subtract(const Duration(days: 1)), count: 4),
        DailyActivity(date: today, count: 2),
      ],
      totals: const AchievementTotals(
        unlocked: 4,
        total: 16,
        answeredQuestions: 24,
      ),
      achievements: const [
        Achievement(
          id: 'PRIMER_PASO',
          title: 'Primer paso',
          description: 'Responde tu primera pregunta.',
          category: AchievementCategory.practice,
          unlocked: true,
          progress: 1,
          goal: 1,
          percentage: 100,
        ),
        Achievement(
          id: 'MENTE_ACTIVA',
          title: 'Mente activa',
          description: 'Responde 25 preguntas.',
          category: AchievementCategory.practice,
          unlocked: false,
          progress: 24,
          goal: 25,
          percentage: 96,
        ),
        Achievement(
          id: 'PRIMER_SIMULACRO',
          title: 'Primer simulacro',
          description: 'Completa tu primer simulacro.',
          category: AchievementCategory.simulations,
          unlocked: true,
          progress: 1,
          goal: 1,
          percentage: 100,
        ),
        Achievement(
          id: 'RACHA_7',
          title: 'Semana completa',
          description: 'Alcanza una racha de 7 días.',
          category: AchievementCategory.streak,
          unlocked: true,
          progress: 7,
          goal: 7,
          percentage: 100,
        ),
        Achievement(
          id: 'ESTUDIANTE_DEDICADO',
          title: 'Estudiante dedicado',
          description: 'Completa 10 temas.',
          category: AchievementCategory.study,
          unlocked: false,
          progress: 2,
          goal: 10,
          percentage: 20,
        ),
      ],
    );
  }
}
