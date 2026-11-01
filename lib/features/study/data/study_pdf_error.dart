import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';

// PDF endpoints return bytes, including error bodies. Use status-based public
// messages instead of exposing an internal revocation reason or parsing a PDF.
ApiError studyPdfError(
  DioException error,
) => switch (error.response?.statusCode) {
  401 => const ApiError(
    code: 'pdf_session_required',
    message: 'Inicia sesión nuevamente para descargar el PDF.',
  ),
  403 || 404 || 410 => const ApiError(
    code: 'pdf_unavailable',
    message:
        'Este PDF no está disponible. Consulta el contenido vigente en la app.',
  ),
  503 => const ApiError(
    code: 'pdf_temporarily_unavailable',
    message: 'No pudimos preparar el PDF. Intenta nuevamente más tarde.',
  ),
  _ => ApiError.fromDioException(error),
};
