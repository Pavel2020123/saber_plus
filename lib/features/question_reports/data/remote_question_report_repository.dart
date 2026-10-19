import 'package:dio/dio.dart';

import '../domain/question_report.dart';

class RemoteQuestionReportRepository implements QuestionReportRepository {
  RemoteQuestionReportRepository(this.dio);
  final Dio dio;

  Future<T> _read<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Map<String, dynamic>) parse,
  ) async {
    try {
      final response = await request();
      if (response.data is! Map<String, dynamic>) throw const FormatException();
      return parse(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      throw QuestionReportFailure(switch (status) {
        400 || 422 => 'Revisa el motivo y el detalle antes de enviar.',
        401 ||
        403 => 'Verifica tu correo y tu sesión de estudiante para continuar.',
        404 =>
          'El reporte no está disponible o no se acredita una respuesta propia.',
        409 => 'El intento cambió. Consulta el recibo; no cambies el envío.',
        429 =>
          'Alcanzaste el límite de intentos o reportes. Espera antes de reintentar.',
        _ =>
          'No se pudo confirmar la operación. Consulta el recibo antes de reenviar el mismo intento.',
      }, status: status);
    } on FormatException {
      throw const QuestionReportFailure(
        'No se pudo validar la respuesta. Consulta el recibo antes de reenviar el mismo intento.',
      );
    }
  }

  @override
  Future<QuestionReport> send(
    QuestionReportAttempt attempt,
  ) => _read(() => dio.post('/preguntas/reportes', data: attempt.toJson()), (
    json,
  ) {
    final report = QuestionReport.fromJson(json, receipt: true);
    if (report.questionId != attempt.questionId ||
        report.reason != attempt.reason) {
      throw const FormatException();
    }
    // Semantic duplicates retain the FIRST detail; it need not match this draft.
    if (report.duplicate == false && (report.detail ?? '') != attempt.detail) {
      throw const FormatException();
    }
    return report;
  });

  @override
  Future<QuestionReport> receipt(String operationId) {
    if (!reportUuid(operationId)) {
      throw const FormatException('Operación inválida.');
    }
    return _read(
      () => dio.get('/preguntas/reportes/operaciones/$operationId'),
      (json) => QuestionReport.fromJson(json, receipt: true),
    );
  }

  @override
  Future<QuestionReportPage> own(int page) {
    if (page < 1 || page > 10000) {
      throw const FormatException('Página inválida.');
    }
    return _read(
      () => dio.get(
        '/preguntas/reportes/mios',
        queryParameters: {'pagina': page, 'limite': 20},
      ),
      (json) {
        final rows = json['items'];
        if (json['pagina'] != page ||
            json['limite'] != 20 ||
            json['hayMas'] is! bool ||
            rows is! List ||
            rows.length > 20 ||
            (json['hayMas'] == true && rows.length != 20)) {
          throw const FormatException();
        }
        final items = rows
            .map((r) {
              if (r is! Map<String, dynamic>) throw const FormatException();
              return QuestionReport.fromJson(r);
            })
            .toList(growable: false);
        if (items.map((r) => r.id).toSet().length != items.length) {
          throw const FormatException();
        }
        return QuestionReportPage(items, page, json['hayMas'] as bool);
      },
    );
  }
}
