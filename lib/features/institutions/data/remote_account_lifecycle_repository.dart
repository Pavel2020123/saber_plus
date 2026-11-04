import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../domain/personal_return_eligibility.dart';
import '../domain/account_privacy_request.dart';

/// Uses the existing authenticated client. Commands are never retried here.
class RemoteAccountLifecycleRepository {
  RemoteAccountLifecycleRepository(this._dio);
  final Dio _dio;

  Future<AccountPrivacyPage> privacyRequests(int page) async {
    if (page < 1) throw ArgumentError.value(page, 'page');
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/cuentas/supresion',
        queryParameters: {'pagina': page},
      );
      final result = AccountPrivacyPage.fromJson(_body(response.data));
      if (result.page != page) {
        throw const FormatException('Unexpected privacy page');
      }
      return result;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<AccountPrivacyRequest> requestSuppression({
    required String userId,
    required String operationId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty || reason.length > 500) {
      throw ArgumentError.value(reason, 'reason');
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/cuentas/supresion',
        data: {
          'usuarioId': userId,
          'operacionId': operationId,
          'motivo': reason.trim(),
        },
      );
      final result = AccountPrivacyRequest.fromJson(_body(response.data));
      if (result.userId != userId) {
        throw const FormatException('Unexpected privacy target');
      }
      return result;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<PersonalReturnEligibility> personalReturnEligibility(
    String institutionId,
  ) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/instituciones/${Uri.encodeComponent(institutionId)}/licencia/mi-salida',
      );
      return PersonalReturnEligibility.fromJson(_body(response.data));
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<void> returnToPersonal({
    required String institutionId,
    required String userId,
    required String operationId,
    required PersonalReturnEligibility eligibility,
  }) async {
    if (!eligibility.allowed || eligibility.managed) {
      throw StateError('Personal return is not available');
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/instituciones/${Uri.encodeComponent(institutionId)}/licencia/volver-personal',
        data: {
          'operacionId': operationId,
          'usuarioId': userId,
          'asignacionId': eligibility.assignmentId,
          'versionAsignacion': eligibility.assignmentVersion,
        },
      );
      final body = _body(response.data);
      if (body['usuarioId'] != userId ||
          body['modalidad'] != 'PERSONAL' ||
          body['historialConservado'] != true) {
        throw const FormatException('Invalid personal return receipt');
      }
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }
}

Map<String, dynamic> _body(Map<String, dynamic>? value) {
  if (value == null) throw const FormatException('Missing lifecycle response');
  final data = value['data'];
  return data is Map<String, dynamic> ? data : value;
}
