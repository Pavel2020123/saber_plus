import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../domain/student_institution_code.dart';
import '../domain/student_institution_request.dart';

class RemoteStudentInstitutionCodeRepository
    implements StudentInstitutionCodeRepository {
  RemoteStudentInstitutionCodeRepository(this._dio);
  final Dio _dio;
  static const path = '/instituciones/codigo-estudiantes';

  Future<Map<String, dynamic>> _send(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        '$path/$endpoint',
        data: body,
        options: Options(method: body == null ? 'GET' : 'POST'),
      );
      if (response.data == null) {
        throw const FormatException('Respuesta vacía.');
      }
      return response.data!;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  @override
  Future<InstitutionStudentCode> own() async =>
      InstitutionStudentCode.fromJson(await _send('propio'));

  @override
  Future<InstitutionCodeRotation> rotate({
    required String operationId,
    required int revision,
  }) async {
    if (!isStudentRequestUuid(operationId) ||
        revision < 0 ||
        revision > 2147483646) {
      throw ArgumentError('Consulta el código antes de renovarlo.');
    }
    final result = InstitutionCodeRotation.fromJson(
      await _send('renovar', body: {'id': operationId, 'revision': revision}),
    );
    if (result.operationId != operationId || result.revision != revision + 1) {
      throw const FormatException('No se pudo confirmar esta renovación.');
    }
    return result;
  }

  @override
  Future<InstitutionCodePreview> preview(String code) async {
    final normalized = normalizeInstitutionStudentCode(code);
    if (!isInstitutionStudentCode(normalized)) {
      throw ArgumentError('Código institucional inválido.');
    }
    return InstitutionCodePreview.fromJson(
      await _send('consultar', body: {'codigo': normalized}),
    );
  }

  @override
  Future<InstitutionCodeJoinResult> join(
    InstitutionCodeJoinAttempt attempt,
  ) async {
    if (!isStudentRequestUuid(attempt.operationId) ||
        !isInstitutionStudentCode(attempt.code) ||
        !isStudentRequestUuid(attempt.preview.institution.id) ||
        attempt.preview.revision < 1 ||
        attempt.preview.revision > 2147483647) {
      throw ArgumentError('Vuelve a consultar el código institucional.');
    }
    final result = InstitutionCodeJoinResult.fromJson(
      await _send(
        'ingresar',
        body: {
          'id': attempt.operationId,
          'codigo': attempt.code,
          'institucionId': attempt.preview.institution.id,
          'revision': attempt.preview.revision,
        },
      ),
    );
    if (result.institution.id != attempt.preview.institution.id) {
      throw const FormatException(
        'El ingreso no corresponde a la institución consultada.',
      );
    }
    return result;
  }
}
