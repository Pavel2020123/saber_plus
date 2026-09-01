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

  @override
  Future<TeacherInstitutionContext> respondInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/instituciones/invitaciones/$invitationId/responder',
        data: {'respuesta': accept ? 'ACEPTAR' : 'RECHAZAR'},
      );
      return loadContext();
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<InstitutionAdministration> loadAdministration() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/instituciones/me/administracion',
      );
      return InstitutionAdministration.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<InstitutionAdministration> reviewRequest({
    required String requestId,
    required bool approve,
  }) async => _changeAdministration(
    () => _dio.patch<Map<String, dynamic>>(
      '/instituciones/me/solicitudes/$requestId',
      data: {'decision': approve ? 'APROBAR' : 'RECHAZAR'},
    ),
  );

  @override
  Future<InstitutionAdministration> inviteMember({
    required String email,
    required InstitutionMemberRole role,
  }) async => _changeAdministration(
    () => _dio.post<Map<String, dynamic>>(
      '/instituciones/me/invitaciones',
      data: {'correo': email, 'rol': role.backendValue},
    ),
  );

  @override
  Future<InstitutionAdministration> cancelInvitation(
    String invitationId,
  ) async => _changeAdministration(
    () => _dio.delete<Map<String, dynamic>>(
      '/instituciones/me/invitaciones/$invitationId',
    ),
  );

  @override
  Future<InstitutionAdministration> changeMemberRole({
    required String membershipId,
    required InstitutionMemberRole role,
  }) async => _changeAdministration(
    () => _dio.patch<Map<String, dynamic>>(
      '/instituciones/me/miembros/$membershipId/rol',
      data: {'rol': role.backendValue},
    ),
  );

  @override
  Future<InstitutionAdministration> removeMember(String membershipId) async =>
      _changeAdministration(
        () => _dio.delete<Map<String, dynamic>>(
          '/instituciones/me/miembros/$membershipId',
        ),
      );

  @override
  Future<InstitutionAdministration> transferOwnership({
    required String membershipId,
    required String confirmationCode,
  }) async => _changeAdministration(
    () => _dio.post<Map<String, dynamic>>(
      '/instituciones/me/transferir-propiedad',
      data: {'miembroId': membershipId, 'codigoConfirmacion': confirmationCode},
    ),
  );

  Future<InstitutionAdministration> _changeAdministration(
    Future<Response<Map<String, dynamic>>> Function() action,
  ) async {
    try {
      await action();
      return loadAdministration();
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
