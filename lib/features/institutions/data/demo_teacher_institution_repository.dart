import '../domain/teacher_institution_models.dart';
import '../domain/teacher_institution_repository.dart';

class DemoTeacherInstitutionRepository implements TeacherInstitutionRepository {
  TeacherInstitutionContext _context = TeacherInstitutionContext.empty;
  var _sequence = 0;

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
}
