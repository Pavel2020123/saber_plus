import 'teacher_institution_models.dart';

abstract interface class TeacherInstitutionRepository {
  Future<TeacherInstitutionContext> loadContext();

  Future<TeacherInstitutionContext> createInstitution({
    required String name,
    String? welcomeMessage,
  });

  Future<TeacherInstitutionContext> requestJoin({
    required String institutionCode,
    String? message,
  });

  Future<TeacherInstitutionContext> cancelJoinRequest();

  Future<TeacherInstitutionContext> respondInvitation({
    required String invitationId,
    required bool accept,
  });

  Future<InstitutionAdministration> loadAdministration();

  Future<InstitutionAdministration> reviewRequest({
    required String requestId,
    required bool approve,
  });

  Future<InstitutionAdministration> inviteMember({
    required String email,
    required InstitutionMemberRole role,
  });

  Future<InstitutionAdministration> cancelInvitation(String invitationId);

  Future<InstitutionAdministration> changeMemberRole({
    required String membershipId,
    required InstitutionMemberRole role,
  });

  Future<InstitutionAdministration> removeMember(String membershipId);

  Future<InstitutionAdministration> transferOwnership({
    required String membershipId,
    required String confirmationCode,
  });
}
