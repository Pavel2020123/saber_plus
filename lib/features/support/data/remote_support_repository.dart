import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/support_configuration.dart';
import '../domain/support_repository.dart';

class RemoteSupportRepository implements SupportRepository {
  RemoteSupportRepository(this._dio);

  final Dio _dio;

  @override
  Future<SupportConfiguration> load() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/soporte');
      return SupportConfiguration.fromJson(_body(response.data));
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
