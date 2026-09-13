import '../../learning_evidence/domain/learning_evidence.dart';

class TeacherStudentEvidence {
  const TeacherStudentEvidence({
    required this.studentId,
    required this.name,
    required this.groups,
    required this.evidence,
  });

  final String studentId;
  final String name;
  final List<String> groups;
  final LearningEvidence evidence;

  factory TeacherStudentEvidence.fromJson(
    Map<String, dynamic> json,
    String expectedId,
  ) {
    if (json['version'] != 1 ||
        json['estudiante'] is! Map<String, dynamic> ||
        json['evidencia'] is! Map<String, dynamic>) {
      throw const FormatException('Ficha de seguimiento incompatible.');
    }
    final student = json['estudiante'] as Map<String, dynamic>;
    if (student['id'] != expectedId ||
        student['nombre'] is! String ||
        (student['nombre'] as String).trim().isEmpty ||
        student['grupos'] is! List) {
      throw const FormatException('Estudiante de la ficha no válido.');
    }
    final groups = <String>[];
    for (final group in student['grupos'] as List) {
      if (group is! Map ||
          group['id'] is! String ||
          group['nombre'] is! String) {
        throw const FormatException('Grupo de la ficha no válido.');
      }
      groups.add(group['nombre'] as String);
    }
    return TeacherStudentEvidence(
      studentId: expectedId,
      name: student['nombre'] as String,
      groups: List.unmodifiable(groups),
      evidence: LearningEvidence.fromJson(
        json['evidencia'] as Map<String, dynamic>,
      ),
    );
  }
}
