import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/referral_models.dart';
import '../domain/referral_repository.dart';

class RemoteReferralRepository implements ReferralRepository {
  RemoteReferralRepository(this._dio);

  final Dio _dio;

  @override
  Future<ReferralSummary> loadSummary() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/referidos/mobile',
      );
      return ReferralSummary.fromJson(_body(response.data));
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
