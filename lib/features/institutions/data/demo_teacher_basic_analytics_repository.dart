import '../domain/institution_group_models.dart';
import '../domain/teacher_basic_analytics_models.dart';
import '../domain/teacher_basic_analytics_repository.dart';

class DemoTeacherBasicAnalyticsRepository
    implements TeacherBasicAnalyticsRepository {
  @override
  Future<TeacherBasicAnalytics> load() async {
    final now = DateTime.now();
    return TeacherBasicAnalytics(
      scope: 'INSTITUCION',
      periodDays: 30,
      generatedAt: now,
      plan: const BasicAnalyticsPlan(
        name: 'GRATIS',
        advertisingEnabled: true,
        groupLimit: 1,
        studentLimit: 40,
      ),
      summary: BasicAnalyticsMetrics(
        totalStudents: 28,
        activeStudents: 21,
        totalSimulations: 46,
        averageScore: 63.4,
        averageProgress: 37.5,
        lastActivity: now.subtract(const Duration(hours: 2)),
      ),
      groups: [
        BasicGroupAnalytics(
          id: 'demo-group-1',
          name: 'Once A',
          grade: InstitutionGrade.eleventh,
          totalStudents: 28,
          activeStudents: 21,
          totalSimulations: 46,
          averageScore: 63.4,
          averageProgress: 37.5,
          lastActivity: now.subtract(const Duration(hours: 2)),
        ),
      ],
      privacyDescription:
          'Los indicadores básicos son agregados y no incluyen nombres ni correos.',
    );
  }
}
