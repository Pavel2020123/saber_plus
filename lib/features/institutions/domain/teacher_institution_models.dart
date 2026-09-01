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

  String get backendValue => switch (this) {
    InstitutionMemberRole.owner => 'PROPIETARIO',
    InstitutionMemberRole.administrator => 'ADMINISTRADOR',
    InstitutionMemberRole.teacher => 'PROFESOR',
  };

  bool get canManage =>
      this == InstitutionMemberRole.owner ||
      this == InstitutionMemberRole.administrator;

  factory InstitutionMemberRole.fromBackend(String? value) => switch (value) {
    'PROPIETARIO' => InstitutionMemberRole.owner,
    'ADMINISTRADOR' => InstitutionMemberRole.administrator,
    _ => InstitutionMemberRole.teacher,
  };
}

enum InstitutionAnalyticsLevel {
  basic,
  detailed;

  factory InstitutionAnalyticsLevel.fromBackend(String? value) =>
      value == 'DETALLADA'
      ? InstitutionAnalyticsLevel.detailed
      : InstitutionAnalyticsLevel.basic;
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
    this.groupLimit = 1,
    this.advertisingEnabled = true,
    this.analyticsLevel = InstitutionAnalyticsLevel.basic,
    this.riskAlertsEnabled = false,
    this.prioritiesEnabled = false,
    this.exportsEnabled = false,
    this.planExpired = false,
    this.expiresAt,
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
  final int? groupLimit;
  final bool advertisingEnabled;
  final InstitutionAnalyticsLevel analyticsLevel;
  final bool riskAlertsEnabled;
  final bool prioritiesEnabled;
  final bool exportsEnabled;
  final bool planExpired;
  final DateTime? expiresAt;
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
        groupLimit:
            json['limiteGrupos'] as int? ??
            ((json['planActual'] as String? ?? 'GRATIS') == 'GRATIS' ? 1 : 5),
        advertisingEnabled:
            json['publicidadHabilitada'] as bool? ??
            (json['planActual'] as String? ?? 'GRATIS') == 'GRATIS',
        analyticsLevel: InstitutionAnalyticsLevel.fromBackend(
          json['nivelAnalitica'] as String?,
        ),
        riskAlertsEnabled:
            json['alertasHabilitadas'] as bool? ??
            json['nivelAnalitica'] == 'DETALLADA',
        prioritiesEnabled:
            json['prioridadesHabilitadas'] as bool? ??
            json['nivelAnalitica'] == 'DETALLADA',
        exportsEnabled:
            json['exportacionesHabilitadas'] as bool? ??
            json['nivelAnalitica'] == 'DETALLADA',
        planExpired: json['planVencido'] as bool? ?? false,
        expiresAt: _optionalInstitutionDate(json['venceEn']),
        welcomeMessage: json['mensajeBienvenida'] as String?,
      );
}

DateTime? _optionalInstitutionDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value)?.toLocal();
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
    this.invitations = const [],
  });

  final TeacherInstitutionStatus status;
  final TeacherInstitution? institution;
  final InstitutionMemberRole? memberRole;
  final InstitutionJoinRequest? joinRequest;
  final List<IncomingInstitutionInvitation> invitations;

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
      invitations: (json['invitaciones'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => IncomingInstitutionInvitation.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
    );
  }

  static const empty = TeacherInstitutionContext(
    status: TeacherInstitutionStatus.noInstitution,
  );
}

class IncomingInstitutionInvitation {
  const IncomingInstitutionInvitation({
    required this.id,
    required this.institutionId,
    required this.institutionName,
    required this.institutionCode,
    required this.role,
    required this.invitedBy,
    required this.expiresAt,
  });

  final String id;
  final String institutionId;
  final String institutionName;
  final String institutionCode;
  final InstitutionMemberRole role;
  final String invitedBy;
  final DateTime expiresAt;

  factory IncomingInstitutionInvitation.fromJson(Map<String, dynamic> json) {
    final institution = Map<String, dynamic>.from(
      json['institucion'] as Map? ?? const {},
    );
    final creator = Map<String, dynamic>.from(
      json['creadoPor'] as Map? ?? const {},
    );
    return IncomingInstitutionInvitation(
      id: json['id'] as String,
      institutionId: institution['id'] as String,
      institutionName: institution['nombre'] as String,
      institutionCode: institution['codigoUnico'] as String,
      role: InstitutionMemberRole.fromBackend(json['rol'] as String?),
      invitedBy: creator['nombre'] as String? ?? 'Equipo institucional',
      expiresAt: DateTime.parse(json['fechaExpiracion'] as String).toLocal(),
    );
  }
}

class InstitutionPermissionSet {
  const InstitutionPermissionSet({
    required this.reviewRequests,
    required this.inviteTeachers,
    required this.manageAdministrators,
    required this.removeTeachers,
    required this.transferOwnership,
    required this.viewAudit,
  });

  final bool reviewRequests;
  final bool inviteTeachers;
  final bool manageAdministrators;
  final bool removeTeachers;
  final bool transferOwnership;
  final bool viewAudit;

  factory InstitutionPermissionSet.fromJson(Map<String, dynamic> json) =>
      InstitutionPermissionSet(
        reviewRequests: json['revisarSolicitudes'] as bool? ?? false,
        inviteTeachers: json['invitarProfesores'] as bool? ?? false,
        manageAdministrators:
            json['gestionarAdministradores'] as bool? ?? false,
        removeTeachers: json['retirarProfesores'] as bool? ?? false,
        transferOwnership: json['transferirPropiedad'] as bool? ?? false,
        viewAudit: json['verAuditoria'] as bool? ?? false,
      );
}

class InstitutionTeamMember {
  const InstitutionTeamMember({
    required this.membershipId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  final String membershipId;
  final String userId;
  final String name;
  final String email;
  final InstitutionMemberRole role;
  final DateTime joinedAt;

  factory InstitutionTeamMember.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['usuario'] as Map? ?? const {});
    return InstitutionTeamMember(
      membershipId: json['id'] as String,
      userId: user['id'] as String,
      name: user['nombre'] as String,
      email: user['correo'] as String,
      role: InstitutionMemberRole.fromBackend(json['rol'] as String?),
      joinedAt: DateTime.parse(json['fechaCreacion'] as String).toLocal(),
    );
  }
}

class InstitutionManagementRequest {
  const InstitutionManagementRequest({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.createdAt,
    this.message,
  });

  final String id;
  final String userId;
  final String name;
  final String email;
  final String? message;
  final DateTime createdAt;

  factory InstitutionManagementRequest.fromJson(Map<String, dynamic> json) {
    final applicant = Map<String, dynamic>.from(
      json['solicitante'] as Map? ?? const {},
    );
    return InstitutionManagementRequest(
      id: json['id'] as String,
      userId: applicant['id'] as String,
      name: applicant['nombre'] as String,
      email: applicant['correo'] as String,
      message: json['mensaje'] as String?,
      createdAt: DateTime.parse(json['fechaCreacion'] as String).toLocal(),
    );
  }
}

class InstitutionSentInvitation {
  const InstitutionSentInvitation({
    required this.id,
    required this.email,
    required this.role,
    required this.invitedBy,
    required this.expiresAt,
  });

  final String id;
  final String email;
  final InstitutionMemberRole role;
  final String invitedBy;
  final DateTime expiresAt;

  factory InstitutionSentInvitation.fromJson(Map<String, dynamic> json) {
    final creator = Map<String, dynamic>.from(
      json['creadoPor'] as Map? ?? const {},
    );
    return InstitutionSentInvitation(
      id: json['id'] as String,
      email: json['correo'] as String,
      role: InstitutionMemberRole.fromBackend(json['rol'] as String?),
      invitedBy: creator['nombre'] as String? ?? 'Equipo institucional',
      expiresAt: DateTime.parse(json['fechaExpiracion'] as String).toLocal(),
    );
  }
}

class InstitutionAuditEntry {
  const InstitutionAuditEntry({
    required this.id,
    required this.action,
    required this.actorName,
    required this.createdAt,
    this.affectedName,
  });

  final String id;
  final String action;
  final String actorName;
  final String? affectedName;
  final DateTime createdAt;

  factory InstitutionAuditEntry.fromJson(Map<String, dynamic> json) {
    final actor = Map<String, dynamic>.from(json['actor'] as Map? ?? const {});
    final affected = json['afectado'] is Map
        ? Map<String, dynamic>.from(json['afectado'] as Map)
        : const <String, dynamic>{};
    return InstitutionAuditEntry(
      id: json['id'] as String,
      action: json['accion'] as String,
      actorName: actor['nombre'] as String? ?? 'Cuenta eliminada',
      affectedName: affected['nombre'] as String?,
      createdAt: DateTime.parse(json['fechaCreacion'] as String).toLocal(),
    );
  }
}

class InstitutionAdministration {
  const InstitutionAdministration({
    required this.institutionId,
    required this.institutionName,
    required this.institutionCode,
    required this.myRole,
    required this.permissions,
    required this.members,
    required this.requests,
    required this.invitations,
    required this.audit,
  });

  final String institutionId;
  final String institutionName;
  final String institutionCode;
  final InstitutionMemberRole myRole;
  final InstitutionPermissionSet permissions;
  final List<InstitutionTeamMember> members;
  final List<InstitutionManagementRequest> requests;
  final List<InstitutionSentInvitation> invitations;
  final List<InstitutionAuditEntry> audit;

  factory InstitutionAdministration.fromJson(Map<String, dynamic> json) {
    final institution = Map<String, dynamic>.from(
      json['institucion'] as Map? ?? const {},
    );
    return InstitutionAdministration(
      institutionId: institution['id'] as String,
      institutionName: institution['nombre'] as String,
      institutionCode: institution['codigoUnico'] as String,
      myRole: InstitutionMemberRole.fromBackend(json['miRol'] as String?),
      permissions: InstitutionPermissionSet.fromJson(
        Map<String, dynamic>.from(json['permisos'] as Map? ?? const {}),
      ),
      members: _mapList(json['miembros'], InstitutionTeamMember.fromJson),
      requests: _mapList(
        json['solicitudes'],
        InstitutionManagementRequest.fromJson,
      ),
      invitations: _mapList(
        json['invitaciones'],
        InstitutionSentInvitation.fromJson,
      ),
      audit: _mapList(json['auditoria'], InstitutionAuditEntry.fromJson),
    );
  }
}

List<T> _mapList<T>(Object? value, T Function(Map<String, dynamic>) parser) =>
    (value as List? ?? const [])
        .whereType<Map>()
        .map((item) => parser(Map<String, dynamic>.from(item)))
        .toList(growable: false);
