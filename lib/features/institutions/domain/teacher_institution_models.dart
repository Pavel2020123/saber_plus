enum TeacherInstitutionStatus {
  noInstitution,
  pendingRequest,
  linked;

  factory TeacherInstitutionStatus.fromBackend(String? value) =>
      switch (value) {
        'SOLICITUD_PENDIENTE' => TeacherInstitutionStatus.pendingRequest,
        'VINCULADO' => TeacherInstitutionStatus.linked,
        _ => TeacherInstitutionStatus.noInstitution,
      };
}

enum InstitutionMemberRole {
  owner('Propietario'),
  administrator('Administrador'),
  teacher('Profesor');

  const InstitutionMemberRole(this.label);

  final String label;

  factory InstitutionMemberRole.fromBackend(String? value) => switch (value) {
    'PROPIETARIO' => InstitutionMemberRole.owner,
    'ADMINISTRADOR' => InstitutionMemberRole.administrator,
    _ => InstitutionMemberRole.teacher,
  };
}

class TeacherInstitution {
  const TeacherInstitution({
    required this.id,
    required this.name,
    required this.teacherCode,
    required this.plan,
    required this.totalStudents,
    required this.totalGroups,
    required this.totalTeachers,
    required this.studentLimit,
    this.welcomeMessage,
  });

  final String id;
  final String name;
  final String teacherCode;
  final String plan;
  final int totalStudents;
  final int totalGroups;
  final int totalTeachers;
  final int? studentLimit;
  final String? welcomeMessage;

  factory TeacherInstitution.fromJson(Map<String, dynamic> json) =>
      TeacherInstitution(
        id: json['id'] as String,
        name: json['nombre'] as String,
        teacherCode: json['codigoUnico'] as String,
        plan: json['planActual'] as String? ?? 'GRATIS',
        totalStudents: json['totalEstudiantes'] as int? ?? 0,
        totalGroups: json['totalGrupos'] as int? ?? 0,
        totalTeachers: json['totalProfesores'] as int? ?? 0,
        studentLimit: json['limiteEstudiantes'] as int?,
        welcomeMessage: json['mensajeBienvenida'] as String?,
      );
}

class InstitutionJoinRequest {
  const InstitutionJoinRequest({
    required this.id,
    required this.institutionName,
    required this.institutionCode,
    required this.createdAt,
    this.message,
  });

  final String id;
  final String institutionName;
  final String institutionCode;
  final DateTime createdAt;
  final String? message;

  factory InstitutionJoinRequest.fromJson(Map<String, dynamic> json) {
    final institution = Map<String, dynamic>.from(
      json['institucion'] as Map? ?? const {},
    );
    return InstitutionJoinRequest(
      id: json['id'] as String,
      institutionName: institution['nombre'] as String,
      institutionCode: institution['codigoUnico'] as String,
      createdAt: DateTime.parse(json['fechaCreacion'] as String).toLocal(),
      message: json['mensaje'] as String?,
    );
  }
}

class TeacherInstitutionContext {
  const TeacherInstitutionContext({
    required this.status,
    this.institution,
    this.memberRole,
    this.joinRequest,
  });

  final TeacherInstitutionStatus status;
  final TeacherInstitution? institution;
  final InstitutionMemberRole? memberRole;
  final InstitutionJoinRequest? joinRequest;

  factory TeacherInstitutionContext.fromJson(Map<String, dynamic> json) {
    final rawInstitution = json['institucion'];
    final rawMembership = json['membresia'];
    final rawRequest = json['solicitud'];
    return TeacherInstitutionContext(
      status: TeacherInstitutionStatus.fromBackend(json['estado'] as String?),
      institution: rawInstitution is Map
          ? TeacherInstitution.fromJson(
              Map<String, dynamic>.from(rawInstitution),
            )
          : null,
      memberRole: rawMembership is Map
          ? InstitutionMemberRole.fromBackend(
              Map<String, dynamic>.from(rawMembership)['rol'] as String?,
            )
          : null,
      joinRequest: rawRequest is Map
          ? InstitutionJoinRequest.fromJson(
              Map<String, dynamic>.from(rawRequest),
            )
          : null,
    );
  }

  static const empty = TeacherInstitutionContext(
    status: TeacherInstitutionStatus.noInstitution,
  );
}
