import '../domain/teacher_institution_models.dart';
import '../domain/teacher_institution_repository.dart';

class DemoTeacherInstitutionRepository implements TeacherInstitutionRepository {
  TeacherInstitutionContext _context = TeacherInstitutionContext.empty;
  var _sequence = 0;
  final _members = <InstitutionTeamMember>[];
  final _requests = <InstitutionManagementRequest>[];
  final _sentInvitations = <InstitutionSentInvitation>[];
  final _audit = <InstitutionAuditEntry>[];

  @override
  Future<TeacherInstitutionContext> loadContext() async => _context;

  @override
  Future<TeacherInstitutionContext> createInstitution({
    required String name,
    String? welcomeMessage,
  }) async {
    _sequence += 1;
    _context = TeacherInstitutionContext(
      status: TeacherInstitutionStatus.linked,
      memberRole: InstitutionMemberRole.owner,
      institution: TeacherInstitution(
        id: 'demo-institution-$_sequence',
        name: name.trim(),
        teacherCode: 'INST-DEMO01',
        plan: 'GRATIS',
        totalStudents: 0,
        totalGroups: 0,
        totalTeachers: 1,
        studentLimit: 40,
        welcomeMessage: welcomeMessage?.trim(),
      ),
    );
    final now = DateTime.now();
    _members
      ..clear()
      ..add(
        InstitutionTeamMember(
          membershipId: 'demo-owner',
          userId: 'demo-owner-user',
          name: 'Profesor demo',
          email: 'profesor@saberplus.demo',
          role: InstitutionMemberRole.owner,
          joinedAt: now,
        ),
      );
    _requests
      ..clear()
      ..add(
        InstitutionManagementRequest(
          id: 'demo-request-admin',
          userId: 'demo-applicant-user',
          name: 'Laura Martínez',
          email: 'laura@saberplus.demo',
          message: 'Soy docente de matemáticas.',
          createdAt: now,
        ),
      );
    _sentInvitations.clear();
    _audit
      ..clear()
      ..add(
        InstitutionAuditEntry(
          id: 'demo-audit-created',
          action: 'INSTITUCION_CREADA',
          actorName: 'Profesor demo',
          affectedName: 'Profesor demo',
          createdAt: now,
        ),
      );
    return _context;
  }

  @override
  Future<TeacherInstitutionContext> requestJoin({
    required String institutionCode,
    String? message,
  }) async {
    _sequence += 1;
    _context = TeacherInstitutionContext(
      status: TeacherInstitutionStatus.pendingRequest,
      joinRequest: InstitutionJoinRequest(
        id: 'demo-request-$_sequence',
        institutionName: 'Institución demostrativa',
        institutionCode: institutionCode.trim().toUpperCase(),
        createdAt: DateTime.now(),
        message: message?.trim(),
      ),
    );
    return _context;
  }

  @override
  Future<TeacherInstitutionContext> cancelJoinRequest() async {
    _context = TeacherInstitutionContext.empty;
    return _context;
  }

  @override
  Future<TeacherInstitutionContext> respondInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    final invitation = _context.invitations
        .where((item) => item.id == invitationId)
        .firstOrNull;
    if (invitation == null) throw StateError('La invitación ya no existe.');
    if (!accept) {
      _context = TeacherInstitutionContext(
        status: _context.status,
        joinRequest: _context.joinRequest,
        invitations: _context.invitations
            .where((item) => item.id != invitationId)
            .toList(growable: false),
      );
      return _context;
    }
    _context = TeacherInstitutionContext(
      status: TeacherInstitutionStatus.linked,
      memberRole: invitation.role,
      institution: TeacherInstitution(
        id: invitation.institutionId,
        name: invitation.institutionName,
        teacherCode: invitation.institutionCode,
        plan: 'GRATIS',
        totalStudents: 0,
        totalGroups: 0,
        totalTeachers: 1,
        studentLimit: 40,
      ),
    );
    return _context;
  }

  @override
  Future<InstitutionAdministration> loadAdministration() async => _snapshot();

  @override
  Future<InstitutionAdministration> reviewRequest({
    required String requestId,
    required bool approve,
  }) async {
    final index = _requests.indexWhere((item) => item.id == requestId);
    if (index < 0) throw StateError('La solicitud ya no está pendiente.');
    final request = _requests.removeAt(index);
    if (approve) {
      _members.add(
        InstitutionTeamMember(
          membershipId: 'demo-member-${++_sequence}',
          userId: request.userId,
          name: request.name,
          email: request.email,
          role: InstitutionMemberRole.teacher,
          joinedAt: DateTime.now(),
        ),
      );
    }
    _addAudit(
      approve ? 'SOLICITUD_APROBADA' : 'SOLICITUD_RECHAZADA',
      request.name,
    );
    _refreshTeacherCount();
    return _snapshot();
  }

  @override
  Future<InstitutionAdministration> inviteMember({
    required String email,
    required InstitutionMemberRole role,
  }) async {
    _sentInvitations.add(
      InstitutionSentInvitation(
        id: 'demo-invitation-${++_sequence}',
        email: email.trim().toLowerCase(),
        role: role,
        invitedBy: 'Profesor demo',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      ),
    );
    _addAudit('INVITACION_CREADA', email.trim().toLowerCase());
    return _snapshot();
  }

  @override
  Future<InstitutionAdministration> cancelInvitation(
    String invitationId,
  ) async {
    final index = _sentInvitations.indexWhere(
      (item) => item.id == invitationId,
    );
    if (index < 0) throw StateError('La invitación ya no está pendiente.');
    final invitation = _sentInvitations.removeAt(index);
    _addAudit('INVITACION_CANCELADA', invitation.email);
    return _snapshot();
  }

  @override
  Future<InstitutionAdministration> changeMemberRole({
    required String membershipId,
    required InstitutionMemberRole role,
  }) async {
    final index = _members.indexWhere(
      (item) => item.membershipId == membershipId,
    );
    if (index < 0 || _members[index].role == InstitutionMemberRole.owner) {
      throw StateError('No se puede cambiar ese miembro.');
    }
    final previous = _members[index];
    _members[index] = InstitutionTeamMember(
      membershipId: previous.membershipId,
      userId: previous.userId,
      name: previous.name,
      email: previous.email,
      role: role,
      joinedAt: previous.joinedAt,
    );
    _addAudit('ROL_ACTUALIZADO', previous.name);
    return _snapshot();
  }

  @override
  Future<InstitutionAdministration> removeMember(String membershipId) async {
    final index = _members.indexWhere(
      (item) => item.membershipId == membershipId,
    );
    if (index < 0 || _members[index].role == InstitutionMemberRole.owner) {
      throw StateError('No se puede retirar ese miembro.');
    }
    final removed = _members.removeAt(index);
    _addAudit('MIEMBRO_RETIRADO', removed.name);
    _refreshTeacherCount();
    return _snapshot();
  }

  @override
  Future<InstitutionAdministration> transferOwnership({
    required String membershipId,
    required String confirmationCode,
  }) async {
    if (confirmationCode.trim().toUpperCase() !=
        _context.institution?.teacherCode) {
      throw StateError('El código de confirmación no coincide.');
    }
    final ownerIndex = _members.indexWhere(
      (item) => item.role == InstitutionMemberRole.owner,
    );
    final targetIndex = _members.indexWhere(
      (item) => item.membershipId == membershipId,
    );
    if (ownerIndex < 0 || targetIndex < 0 || ownerIndex == targetIndex) {
      throw StateError('Selecciona otro miembro del equipo.');
    }
    _members[ownerIndex] = _copyMember(
      _members[ownerIndex],
      InstitutionMemberRole.administrator,
    );
    _members[targetIndex] = _copyMember(
      _members[targetIndex],
      InstitutionMemberRole.owner,
    );
    _context = TeacherInstitutionContext(
      status: _context.status,
      institution: _context.institution,
      memberRole: InstitutionMemberRole.administrator,
    );
    _addAudit('PROPIEDAD_TRANSFERIDA', _members[targetIndex].name);
    return _snapshot();
  }

  InstitutionAdministration _snapshot() {
    final institution = _context.institution;
    final role = _context.memberRole;
    if (institution == null || role == null || !role.canManage) {
      throw StateError('No tienes permisos para administrar el equipo.');
    }
    final owner = role == InstitutionMemberRole.owner;
    return InstitutionAdministration(
      institutionId: institution.id,
      institutionName: institution.name,
      institutionCode: institution.teacherCode,
      myRole: role,
      permissions: InstitutionPermissionSet(
        reviewRequests: true,
        inviteTeachers: true,
        manageAdministrators: owner,
        removeTeachers: true,
        transferOwnership: owner,
        viewAudit: true,
      ),
      members: List.unmodifiable(_members),
      requests: List.unmodifiable(_requests),
      invitations: List.unmodifiable(_sentInvitations),
      audit: List.unmodifiable(_audit.reversed),
    );
  }

  InstitutionTeamMember _copyMember(
    InstitutionTeamMember value,
    InstitutionMemberRole role,
  ) => InstitutionTeamMember(
    membershipId: value.membershipId,
    userId: value.userId,
    name: value.name,
    email: value.email,
    role: role,
    joinedAt: value.joinedAt,
  );

  void _addAudit(String action, String affectedName) {
    _audit.add(
      InstitutionAuditEntry(
        id: 'demo-audit-${++_sequence}',
        action: action,
        actorName: 'Profesor demo',
        affectedName: affectedName,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _refreshTeacherCount() {
    final institution = _context.institution;
    if (institution == null) return;
    _context = TeacherInstitutionContext(
      status: _context.status,
      memberRole: _context.memberRole,
      institution: TeacherInstitution(
        id: institution.id,
        name: institution.name,
        teacherCode: institution.teacherCode,
        plan: institution.plan,
        totalStudents: institution.totalStudents,
        totalGroups: institution.totalGroups,
        totalTeachers: _members.length,
        studentLimit: institution.studentLimit,
        welcomeMessage: institution.welcomeMessage,
      ),
    );
  }
}
