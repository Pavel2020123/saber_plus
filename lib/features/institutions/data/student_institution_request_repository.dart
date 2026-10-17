import 'package:dio/dio.dart';
import '../../../core/network/api_error.dart';
import '../domain/student_institution_request.dart';

class RemoteStudentInstitutionRequestRepository
    implements StudentInstitutionRequestRepository {
  RemoteStudentInstitutionRequestRepository(this._dio);
  final Dio _dio;
  static const path = '/instituciones/ingresos-estudiantes';

  Future<Map<String, dynamic>> _send(
    String url, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.request<Map<String, dynamic>>(
        url,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );
      if (response.data == null) {
        throw const FormatException('Respuesta vacía.');
      }
      return response.data!;
    } on DioException catch (error) {
      throw ApiError.fromDioException(error);
    }
  }

  Future<StudentInstitutionRequestPage> _list(
    int page, {
    StudentRequestStatus? status,
  }) async {
    if (page < 1 || page > 10000) {
      throw ArgumentError('Página inválida.');
    }
    final data = await _send(
      '$path/${status == null ? 'me' : 'pendientes'}',
      query: {'pagina': page, if (status != null) 'estado': status.value},
    );
    final raw = data['solicitudes'];
    if (raw is! List ||
        raw.length > 20 ||
        data['pagina'] is! int ||
        data['pagina'] != page ||
        data['hayMas'] is! bool) {
      throw const FormatException('Listado de solicitudes inválido.');
    }
    final rows = raw
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Solicitud inválida.');
          }
          return StudentInstitutionRequest.fromJson(item);
        })
        .toList(growable: false);
    if (rows.map((r) => r.id).toSet().length != rows.length ||
        (status != null &&
            rows.any((r) => r.status != status || r.studentName == null))) {
      throw const FormatException('La bandeja no corresponde a la consulta.');
    }
    return StudentInstitutionRequestPage(
      items: rows,
      page: page,
      hasMore: data['hayMas'] as bool,
    );
  }

  @override
  Future<StudentInstitutionRequestPage> own(int page) => _list(page);
  @override
  Future<StudentInstitutionRequestPage> inbox(
    int page,
    StudentRequestStatus status,
  ) => _list(page, status: status);
  @override
  Future<StudentInstitutionRequest> create({
    required String operationId,
    required String institutionId,
    required String message,
  }) async {
    if (!isStudentRequestUuid(operationId) ||
        !isStudentRequestUuid(institutionId) ||
        message.trim().runes.length > 500) {
      throw ArgumentError('Solicitud inválida.');
    }
    final row = StudentInstitutionRequest.fromJson(
      await _send(
        path,
        method: 'POST',
        body: {
          'id': operationId,
          'institucionId': institutionId,
          'mensaje': message.trim(),
        },
      ),
    );
    if (row.id != operationId || row.institutionId != institutionId) {
      throw const FormatException('No se pudo confirmar la solicitud.');
    }
    return row;
  }

  @override
  Future<StudentInstitutionRequest> cancel(StudentInstitutionRequest request) =>
      _decide(request, null);
  @override
  Future<StudentInstitutionRequest> review(
    StudentInstitutionRequest request, {
    required bool approve,
  }) => _decide(request, approve);
  Future<StudentInstitutionRequest> _decide(
    StudentInstitutionRequest request,
    bool? approve,
  ) async {
    if (!isStudentRequestUuid(request.id) ||
        request.status != StudentRequestStatus.pending ||
        request.revision >= 2147483647) {
      throw ArgumentError('Consulta la solicitud antes de decidir.');
    }
    final row = StudentInstitutionRequest.fromJson(
      await _send(
        '$path/${request.id}${approve == null ? '' : '/revision'}',
        method: approve == null ? 'DELETE' : 'PATCH',
        body: {
          'revision': request.revision,
          if (approve != null) 'decision': approve ? 'APROBAR' : 'RECHAZAR',
        },
      ),
    );
    final expected = approve == null
        ? StudentRequestStatus.cancelled
        : approve
        ? StudentRequestStatus.approved
        : StudentRequestStatus.rejected;
    if (row.id != request.id ||
        row.institutionId != request.institutionId ||
        row.status != expected ||
        row.revision <= request.revision) {
      throw const FormatException('No se pudo confirmar la decisión.');
    }
    return row;
  }
}
