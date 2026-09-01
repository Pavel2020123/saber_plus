import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/ranking_models.dart';
import '../domain/ranking_repository.dart';

class RemoteRankingRepository implements RankingRepository {
  RemoteRankingRepository(this._dio);

  final Dio _dio;

  @override
  Future<RankingBoard> load({
    required RankingScope scope,
    required RankingPeriod period,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/ranking',
        queryParameters: {
          'alcance': scope.backendValue,
          'periodo': period.backendValue,
          'limite': 50,
        },
      );
      return RankingBoard.fromJson(_body(response.data));
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
