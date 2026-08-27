import 'package:dio/dio.dart';

class ApiError implements Exception {
  const ApiError({
    required this.code,
    required this.message,
    this.details,
    this.traceId,
  });

  final String code;
  final String message;
  final Object? details;
  final String? traceId;

  factory ApiError.fromJson(Map<String, dynamic> json) => ApiError(
    code: json['code'] as String? ?? 'unknown_error',
    message: json['message'] as String? ?? 'Ocurrió un error inesperado.',
    details: json['details'],
    traceId: json['traceId'] as String?,
  );

  factory ApiError.fromDioException(DioException exception) {
    final body = exception.response?.data;
    if (body is Map<String, dynamic>) {
      return ApiError.fromJson(body);
    }
    if (body is Map) {
      return ApiError.fromJson(Map<String, dynamic>.from(body));
    }

    return ApiError(
      code: switch (exception.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'network_timeout',
        DioExceptionType.connectionError => 'network_unavailable',
        _ => 'unexpected_error',
      },
      message: switch (exception.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'La conexión está tardando demasiado. Intenta nuevamente.',
        DioExceptionType.connectionError =>
          'No pudimos conectar con SaberPlus. Revisa tu conexión.',
        _ => 'Ocurrió un error inesperado. Intenta nuevamente.',
      },
    );
  }

  @override
  String toString() => 'ApiError($code): $message';
}
