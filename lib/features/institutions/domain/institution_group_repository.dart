import 'institution_group_models.dart';

abstract interface class InstitutionGroupRepository {
  Future<List<InstitutionGroup>> loadTeacherGroups();

  Future<List<InstitutionGroup>> createGroup({
    required String name,
    required InstitutionGrade grade,
  });

  Future<List<InstitutionGroup>> deleteGroup(String groupId);

  Future<CreatedTemporaryGroupCode> createTemporaryCode({
    required String groupId,
    required int durationMinutes,
    required int maximumUses,
  });

  Future<List<InstitutionGroup>> revokeTemporaryCode({
    required String groupId,
    required String codeId,
  });

  Future<List<InstitutionGroup>> assignTeacher({
    required String groupId,
    required String membershipId,
  });

  Future<List<InstitutionGroup>> removeTeacher({
    required String groupId,
    required String membershipId,
  });

  Future<StudentInstitutionGroups> loadStudentGroups();

  Future<StudentGroupPreview> previewCode(String code);

  Future<StudentInstitutionGroups> acceptCode(String code);
}
