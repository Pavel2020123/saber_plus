import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/gamification_models.dart';
import '../domain/gamification_repository.dart';

class RemoteGamificationRepository implements GamificationRepository {
  RemoteGamificationRepository(this._dio);

  final Dio _dio;

  @override
  Future<GamificationSummary> loadSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/gamificacion/resumen',
      );
      return GamificationSummary.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Map<String, dynamic> _body(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final data = body['data'];
    return data is Map<String, dynamic> ? data : body;
  }
}
