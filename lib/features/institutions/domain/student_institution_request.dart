import 'dart:math';

enum StudentRequestStatus {
  pending('PENDIENTE', 'Pendiente de revisión'),
  approved('APROBADA', 'Aceptada'),
  rejected('RECHAZADA', 'Rechazada'),
  cancelled('CANCELADA', 'Cancelada');

  const StudentRequestStatus(this.value, this.label);
  final String value, label;
  static StudentRequestStatus parse(Object? value) => values.firstWhere(
    (status) => status.value == value,
    orElse: () => throw const FormatException('Estado de solicitud inválido.'),
  );
}

class StudentInstitutionRequest {
  const StudentInstitutionRequest({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    required this.status,
    required this.revision,
    required this.createdAt,
    required this.updatedAt,
    this.message,
    this.studentName,
  });
  final String id, institutionId, institutionName;
  final StudentRequestStatus status;
  final int revision;
  final DateTime createdAt, updatedAt;
  final String? message, studentName;

  factory StudentInstitutionRequest.fromJson(Map<String, dynamic> json) {
    final institution = json['institucion'];
    final revision = json['revision'];
    final created = DateTime.tryParse(json['fechaCreacion']?.toString() ?? '');
    final updated = DateTime.tryParse(
      json['fechaActualizacion']?.toString() ?? '',
    );
    if (institution is! Map<String, dynamic> ||
        !isStudentRequestUuid(json['id']) ||
        !isStudentRequestUuid(institution['id']) ||
        institution['nombre'] is! String ||
        (institution['nombre'] as String).trim().isEmpty ||
        revision is! int ||
        revision < 0 ||
        revision > 2147483647 ||
        created == null ||
        updated == null ||
        updated.isBefore(created) ||
        (json['mensaje'] != null && json['mensaje'] is! String) ||
        (json['estudianteNombre'] != null &&
            json['estudianteNombre'] is! String)) {
      throw const FormatException('Solicitud incompleta. Consulta nuevamente.');
    }
    return StudentInstitutionRequest(
      id: json['id'] as String,
      institutionId: institution['id'] as String,
      institutionName: institution['nombre'] as String,
      status: StudentRequestStatus.parse(json['estado']),
      revision: revision,
      createdAt: created,
      updatedAt: updated,
      message: json['mensaje'] as String?,
      studentName: json['estudianteNombre'] as String?,
    );
  }
}

class StudentInstitutionRequestPage {
  const StudentInstitutionRequestPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });
  final List<StudentInstitutionRequest> items;
  final int page;
  final bool hasMore;
}

abstract interface class StudentInstitutionRequestRepository {
  Future<StudentInstitutionRequestPage> own(int page);
  Future<StudentInstitutionRequestPage> inbox(
    int page,
    StudentRequestStatus status,
  );
  Future<StudentInstitutionRequest> create({
    required String operationId,
    required String institutionId,
    required String message,
  });
  Future<StudentInstitutionRequest> cancel(StudentInstitutionRequest request);
  Future<StudentInstitutionRequest> review(
    StudentInstitutionRequest request, {
    required bool approve,
  });
}

bool isStudentRequestUuid(Object? value) =>
    value is String &&
    RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    ).hasMatch(value);

// Identificador estable por intento, no una credencial. No generar al reintentar.
String newStudentRequestId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
