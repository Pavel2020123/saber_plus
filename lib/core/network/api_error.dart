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

  @override
  String toString() => 'ApiError($code): $message';
}
