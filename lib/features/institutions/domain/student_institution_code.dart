import 'institution_directory.dart';
import 'student_institution_request.dart';

String normalizeInstitutionStudentCode(String value) =>
    value.trim().toUpperCase();
bool isInstitutionStudentCode(Object? value) =>
    value is String && RegExp(r'^SPI-[A-F0-9]{32}$').hasMatch(value);

PublicInstitution _institution(Object? value) {
  if (value is! Map<String, dynamic> ||
      !isStudentRequestUuid(value['id']) ||
      value['nombre'] is! String ||
      (value['nombre'] as String).trim().isEmpty ||
      (value['nombre'] as String).length > 255) {
    throw const FormatException('Institución no válida.');
  }
  // No conservar campos adicionales ni secretos ajenos al contrato.
  return PublicInstitution(
    id: value['id'] as String,
    name: value['nombre'] as String,
  );
}

int _revision(Object? value, {int minimum = 1}) {
  if (value is! int || value < minimum || value > 2147483647) {
    throw const FormatException('Versión de código no válida.');
  }
  return value;
}

class InstitutionStudentCode {
  const InstitutionStudentCode({
    required this.institution,
    required this.revision,
    this.code,
    this.operationId,
  });
  final PublicInstitution institution;
  final String? code, operationId;
  final int revision;

  factory InstitutionStudentCode.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('codigo') || !json.containsKey('operacionId')) {
      throw const FormatException('Estado de código incompleto.');
    }
    final institution = _institution(json['institucion']);
    final revision = _revision(json['revision'], minimum: 0);
    final code = json['codigo'];
    final operationId = json['operacionId'];
    if (code == null
        ? revision != 0 || operationId != null
        : !isInstitutionStudentCode(code) ||
              revision == 0 ||
              !isStudentRequestUuid(operationId)) {
      throw const FormatException(
        'No se pudo confirmar el código institucional.',
      );
    }
    return InstitutionStudentCode(
      institution: institution,
      revision: revision,
      code: code as String?,
      operationId: operationId as String?,
    );
  }

  InstitutionStudentCode rotated(InstitutionCodeRotation rotation) =>
      InstitutionStudentCode(
        institution: institution,
        revision: rotation.revision,
        code: rotation.code,
        operationId: rotation.operationId,
      );
}

class InstitutionCodeRotation {
  const InstitutionCodeRotation({
    required this.code,
    required this.revision,
    required this.operationId,
  });
  final String code, operationId;
  final int revision;
  factory InstitutionCodeRotation.fromJson(Map<String, dynamic> json) {
    if (!isInstitutionStudentCode(json['codigo']) ||
        !isStudentRequestUuid(json['operacionId'])) {
      throw const FormatException('Renovación no confirmada.');
    }
    return InstitutionCodeRotation(
      code: json['codigo'] as String,
      revision: _revision(json['revision']),
      operationId: json['operacionId'] as String,
    );
  }
}

class InstitutionCodePreview {
  const InstitutionCodePreview({
    required this.institution,
    required this.revision,
    required this.alreadyLinked,
  });
  final PublicInstitution institution;
  final int revision;
  final bool alreadyLinked;
  factory InstitutionCodePreview.fromJson(Map<String, dynamic> json) {
    if (json['yaVinculado'] is! bool) {
      throw const FormatException('Consulta no válida.');
    }
    return InstitutionCodePreview(
      institution: _institution(json['institucion']),
      revision: _revision(json['revision']),
      alreadyLinked: json['yaVinculado'] as bool,
    );
  }
}

class InstitutionCodeJoinAttempt {
  const InstitutionCodeJoinAttempt({
    required this.operationId,
    required this.code,
    required this.preview,
  });
  final String operationId, code;
  final InstitutionCodePreview preview;
}

class InstitutionCodeJoinResult {
  const InstitutionCodeJoinResult({
    required this.institution,
    required this.alreadyLinked,
  });
  final PublicInstitution institution;
  final bool alreadyLinked;
  factory InstitutionCodeJoinResult.fromJson(Map<String, dynamic> json) {
    if (json['estado'] != 'VINCULADO' || json['yaVinculado'] is! bool) {
      throw const FormatException('Ingreso no confirmado.');
    }
    return InstitutionCodeJoinResult(
      institution: _institution(json['institucion']),
      alreadyLinked: json['yaVinculado'] as bool,
    );
  }
}

abstract interface class StudentInstitutionCodeRepository {
  Future<InstitutionStudentCode> own();
  Future<InstitutionCodeRotation> rotate({
    required String operationId,
    required int revision,
  });
  Future<InstitutionCodePreview> preview(String code);
  Future<InstitutionCodeJoinResult> join(InstitutionCodeJoinAttempt attempt);
}
