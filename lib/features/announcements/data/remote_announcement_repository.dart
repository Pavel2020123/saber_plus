import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/announcement_models.dart';
import '../domain/announcement_repository.dart';

class RemoteAnnouncementRepository implements AnnouncementRepository {
  RemoteAnnouncementRepository(this._dio);

  final Dio _dio;

  @override
  Future<AnnouncementBoard> load() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/anuncios');
      return AnnouncementBoard.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<DateTime> markRead(String id) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/anuncios/$id/leer',
      );
      final value = _body(response.data)['fechaLectura'];
      return value is String ? DateTime.parse(value).toLocal() : DateTime.now();
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<void> markAllRead() async {
    try {
      await _dio.patch<Map<String, dynamic>>('/anuncios/leer-todos');
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
