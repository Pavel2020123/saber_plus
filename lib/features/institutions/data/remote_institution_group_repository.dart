import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/institution_group_models.dart';
import '../domain/institution_group_repository.dart';

class RemoteInstitutionGroupRepository implements InstitutionGroupRepository {
  RemoteInstitutionGroupRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<InstitutionGroup>> loadTeacherGroups() async {
    try {
      final response = await _dio.get<Object?>('/instituciones/me/grupos');
      final items = _listBody(response.data);
      return items
          .whereType<Map>()
          .map(
            (item) =>
                InstitutionGroup.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<List<InstitutionGroup>> createGroup({
    required String name,
    required InstitutionGrade grade,
  }) async => _changeTeacherGroups(
    () => _dio.post<Object?>(
      '/instituciones/me/grupos',
      data: {'nombre': name, 'grado': grade.backendValue},
    ),
  );

  @override
  Future<List<InstitutionGroup>> deleteGroup(String groupId) async =>
      _changeTeacherGroups(
        () => _dio.delete<Object?>('/instituciones/me/grupos/$groupId'),
      );

  @override
  Future<CreatedTemporaryGroupCode> createTemporaryCode({
    required String groupId,
    required int durationMinutes,
    required int maximumUses,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/instituciones/me/grupos/$groupId/codigos',
        data: {'duracionMinutos': durationMinutes, 'usosMaximos': maximumUses},
      );
      return CreatedTemporaryGroupCode.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<List<InstitutionGroup>> revokeTemporaryCode({
    required String groupId,
    required String codeId,
  }) async => _changeTeacherGroups(
    () => _dio.delete<Object?>(
      '/instituciones/me/grupos/$groupId/codigos/$codeId',
    ),
  );

  @override
  Future<List<InstitutionGroup>> assignTeacher({
    required String groupId,
    required String membershipId,
  }) async => _changeTeacherGroups(
    () => _dio.post<Object?>(
      '/instituciones/me/grupos/$groupId/profesores',
      data: {'miembroId': membershipId},
    ),
  );

  @override
  Future<List<InstitutionGroup>> removeTeacher({
    required String groupId,
    required String membershipId,
  }) async => _changeTeacherGroups(
    () => _dio.delete<Object?>(
      '/instituciones/me/grupos/$groupId/profesores/$membershipId',
    ),
  );

  @override
  Future<StudentInstitutionGroups> loadStudentGroups() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/instituciones/grupos/estudiante',
      );
      return StudentInstitutionGroups.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<StudentGroupPreview> previewCode(String code) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/instituciones/grupos/vista-previa',
        data: {'codigo': code},
      );
      return StudentGroupPreview.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<StudentInstitutionGroups> acceptCode(String code) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/instituciones/grupos/aceptar',
        data: {'codigo': code, 'acepto': true},
      );
      return loadStudentGroups();
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<List<InstitutionGroup>> _changeTeacherGroups(
    Future<Response<Object?>> Function() action,
  ) async {
    try {
      await action();
      return loadTeacherGroups();
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

List<dynamic> _listBody(Object? value) {
  if (value is List) return value;
  if (value is Map) {
    final data = value['data'];
    if (data is List) return data;
  }
  return const [];
}
