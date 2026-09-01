import 'teacher_institution_models.dart';

enum InstitutionGrade {
  tenth('Décimo', 'DECIMO'),
  eleventh('Once', 'ONCE');

  const InstitutionGrade(this.label, this.backendValue);

  final String label;
  final String backendValue;

  factory InstitutionGrade.fromBackend(String? value) =>
      value == 'DECIMO' ? InstitutionGrade.tenth : InstitutionGrade.eleventh;
}

class AssignedGroupTeacher {
  const AssignedGroupTeacher({
    required this.membershipId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
  });

  final String membershipId;
  final String userId;
  final String name;
  final String email;
  final InstitutionMemberRole role;

  factory AssignedGroupTeacher.fromJson(Map<String, dynamic> json) {
    final member = Map<String, dynamic>.from(
      json['miembro'] as Map? ?? const {},
    );
    final user = Map<String, dynamic>.from(
      member['usuario'] as Map? ?? const {},
    );
    return AssignedGroupTeacher(
      membershipId: member['id'] as String,
      userId: user['id'] as String,
      name: user['nombre'] as String,
      email: user['correo'] as String,
      role: InstitutionMemberRole.fromBackend(member['rol'] as String?),
    );
  }
}

class TemporaryGroupCode {
  const TemporaryGroupCode({
    required this.id,
    required this.suffix,
    required this.uses,
    required this.maximumUses,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String suffix;
  final int uses;
  final int maximumUses;
  final DateTime expiresAt;
  final DateTime createdAt;

  int get availableUses => (maximumUses - uses).clamp(0, maximumUses);

  factory TemporaryGroupCode.fromJson(Map<String, dynamic> json) =>
      TemporaryGroupCode(
        id: json['id'] as String,
        suffix: json['sufijo'] as String,
        uses: json['usos'] as int? ?? 0,
        maximumUses: json['usosMaximos'] as int,
        expiresAt: DateTime.parse(json['fechaExpiracion'] as String).toLocal(),
        createdAt: DateTime.parse(json['fechaCreacion'] as String).toLocal(),
      );
}

class CreatedTemporaryGroupCode extends TemporaryGroupCode {
  const CreatedTemporaryGroupCode({
    required super.id,
    required super.suffix,
    required super.uses,
    required super.maximumUses,
    required super.expiresAt,
    required super.createdAt,
    required this.code,
  });

  final String code;

  factory CreatedTemporaryGroupCode.fromJson(Map<String, dynamic> json) =>
      CreatedTemporaryGroupCode(
        id: json['id'] as String,
        suffix: json['sufijo'] as String,
        uses: json['usos'] as int? ?? 0,
        maximumUses: json['usosMaximos'] as int,
        expiresAt: DateTime.parse(json['fechaExpiracion'] as String).toLocal(),
        createdAt: DateTime.parse(json['fechaCreacion'] as String).toLocal(),
        code: json['codigo'] as String,
      );
}

class InstitutionGroup {
  const InstitutionGroup({
    required this.id,
    required this.name,
    required this.grade,
    required this.studentCount,
    required this.teachers,
    required this.codes,
  });

  final String id;
  final String name;
  final InstitutionGrade grade;
  final int studentCount;
  final List<AssignedGroupTeacher> teachers;
  final List<TemporaryGroupCode> codes;

  factory InstitutionGroup.fromJson(Map<String, dynamic> json) {
    final count = Map<String, dynamic>.from(json['_count'] as Map? ?? const {});
    return InstitutionGroup(
      id: json['id'] as String,
      name: json['nombre'] as String,
      grade: InstitutionGrade.fromBackend(json['grado'] as String?),
      studentCount: count['ClaseEstudiante'] as int? ?? 0,
      teachers: _mapList(json['profesores'], AssignedGroupTeacher.fromJson),
      codes: _mapList(json['codigos'], TemporaryGroupCode.fromJson),
    );
  }
}

enum StudentGroupPreviewStatus {
  available,
  alreadyLinked,
  anotherInstitution;

  factory StudentGroupPreviewStatus.fromBackend(String? value) =>
      switch (value) {
        'YA_VINCULADO' => StudentGroupPreviewStatus.alreadyLinked,
        'OTRA_INSTITUCION' => StudentGroupPreviewStatus.anotherInstitution,
        _ => StudentGroupPreviewStatus.available,
      };
}

class StudentGroupPreview {
  const StudentGroupPreview({
    required this.status,
    required this.canJoin,
    required this.requiresAcceptance,
    required this.groupId,
    required this.groupName,
    required this.grade,
    required this.institutionId,
    required this.institutionName,
    required this.expiresAt,
    required this.availableUses,
  });

  final StudentGroupPreviewStatus status;
  final bool canJoin;
  final bool requiresAcceptance;
  final String groupId;
  final String groupName;
  final InstitutionGrade grade;
  final String institutionId;
  final String institutionName;
  final DateTime expiresAt;
  final int availableUses;

  factory StudentGroupPreview.fromJson(Map<String, dynamic> json) {
    final group = Map<String, dynamic>.from(json['grupo'] as Map? ?? const {});
    final institution = Map<String, dynamic>.from(
      json['institucion'] as Map? ?? const {},
    );
    final code = Map<String, dynamic>.from(json['codigo'] as Map? ?? const {});
    return StudentGroupPreview(
      status: StudentGroupPreviewStatus.fromBackend(json['estado'] as String?),
      canJoin: json['puedeUnirse'] as bool? ?? false,
      requiresAcceptance: json['requiereAceptacion'] as bool? ?? true,
      groupId: group['id'] as String,
      groupName: group['nombre'] as String,
      grade: InstitutionGrade.fromBackend(group['grado'] as String?),
      institutionId: institution['id'] as String,
      institutionName: institution['nombre'] as String,
      expiresAt: DateTime.parse(code['fechaExpiracion'] as String).toLocal(),
      availableUses: code['usosDisponibles'] as int? ?? 0,
    );
  }
}

class StudentInstitutionGroup {
  const StudentInstitutionGroup({
    required this.id,
    required this.name,
    required this.grade,
    required this.institutionId,
    required this.institutionName,
    required this.joinedAt,
    required this.explicitlyAccepted,
  });

  final String id;
  final String name;
  final InstitutionGrade grade;
  final String institutionId;
  final String institutionName;
  final DateTime joinedAt;
  final bool explicitlyAccepted;

  factory StudentInstitutionGroup.fromJson(Map<String, dynamic> json) {
    final institution = Map<String, dynamic>.from(
      json['institucion'] as Map? ?? const {},
    );
    return StudentInstitutionGroup(
      id: json['id'] as String,
      name: json['nombre'] as String,
      grade: InstitutionGrade.fromBackend(json['grado'] as String?),
      institutionId: institution['id'] as String,
      institutionName: institution['nombre'] as String,
      joinedAt: DateTime.parse(json['fechaIngreso'] as String).toLocal(),
      explicitlyAccepted: json['aceptacionExplicita'] as bool? ?? false,
    );
  }
}

class StudentInstitutionGroups {
  const StudentInstitutionGroups({required this.groups, this.institutionId});

  final String? institutionId;
  final List<StudentInstitutionGroup> groups;

  factory StudentInstitutionGroups.fromJson(Map<String, dynamic> json) =>
      StudentInstitutionGroups(
        institutionId: json['institucionId'] as String?,
        groups: _mapList(json['grupos'], StudentInstitutionGroup.fromJson),
      );
}

List<T> _mapList<T>(Object? value, T Function(Map<String, dynamic>) parser) =>
    (value as List? ?? const [])
        .whereType<Map>()
        .map((item) => parser(Map<String, dynamic>.from(item)))
        .toList(growable: false);
