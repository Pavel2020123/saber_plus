import 'teacher_basic_analytics_models.dart';

abstract interface class TeacherBasicAnalyticsRepository {
  Future<TeacherBasicAnalytics> load();
}
