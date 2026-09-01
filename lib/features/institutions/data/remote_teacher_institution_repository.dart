import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/teacher_institution_models.dart';
import '../domain/teacher_institution_repository.dart';

class RemoteTeacherInstitutionRepository
    implements TeacherInstitutionRepository {
  RemoteTeacherInstitutionRepository(this._dio);

  final Dio _dio;

  @override
  Future<TeacherInstitutionContext> loadContext() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/instituciones/profesor/contexto',
      );
      return TeacherInstitutionContext.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<TeacherInstitutionContext> createInstitution({
    required String name,
    String? welcomeMessage,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/instituciones',
        data: {
          'nombre': name,
          if (welcomeMessage case final message? when message.isNotEmpty)
            'mensajeBienvenida': message,
        },
      );
      return loadContext();
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<TeacherInstitutionContext> requestJoin({
    required String institutionCode,
    String? message,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/instituciones/solicitudes',
        data: {
          'codigoInstitucion': institutionCode,
          if (message case final value? when value.isNotEmpty) 'mensaje': value,
        },
      );
      return loadContext();
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<TeacherInstitutionContext> cancelJoinRequest() async {
    try {
      await _dio.delete<Map<String, dynamic>>('/instituciones/solicitudes/me');
      return loadContext();
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
