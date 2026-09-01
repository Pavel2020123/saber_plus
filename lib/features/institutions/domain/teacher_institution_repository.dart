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
}
