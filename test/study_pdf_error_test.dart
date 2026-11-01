import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/study/data/study_pdf_error.dart';

void main() {
  for (final status in [401, 403, 404, 410, 503]) {
    test('PDF bytes error $status has a safe actionable message', () {
      final request = RequestOptions(path: '/simulacros/temas/test/pdf');
      final error = studyPdfError(
        DioException(
          requestOptions: request,
          type: DioExceptionType.badResponse,
          response: Response<List<int>>(
            requestOptions: request,
            statusCode: status,
            data: 'internal revocation detail'.codeUnits,
          ),
        ),
      );
      expect(error.code, switch (status) {
        401 => 'pdf_session_required',
        503 => 'pdf_temporarily_unavailable',
        _ => 'pdf_unavailable',
      });
      expect(error.message, isNot(contains('internal')));
      expect(error.message, isNot(contains('inesperado')));
    });
  }
  test('connection failures keep the existing network message', () {
    final error = studyPdfError(
      DioException(
        requestOptions: RequestOptions(path: '/pdf'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(error.code, 'network_unavailable');
  });
}
