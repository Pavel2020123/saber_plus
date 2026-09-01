import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/teacher_basic_analytics_models.dart';
import '../domain/teacher_basic_analytics_repository.dart';

class RemoteTeacherBasicAnalyticsRepository
    implements TeacherBasicAnalyticsRepository {
  RemoteTeacherBasicAnalyticsRepository(this._dio);

  final Dio _dio;

  @override
  Future<TeacherBasicAnalytics> load() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/instituciones/me/analiticas-basicas',
      );
      return TeacherBasicAnalytics.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}

Map<String, dynamic> _body(Map<String, dynamic>? value) {
  if (value == null) return const {};
  final data = value['data'];
  return data is Map ? Map<String, dynamic>.from(data) : value;
}
