import '../domain/institution_group_models.dart';
import '../domain/institution_group_repository.dart';
import '../domain/teacher_institution_models.dart';

class DemoInstitutionGroupRepository implements InstitutionGroupRepository {
  DemoInstitutionGroupRepository()
    : _teacherGroups = [
        InstitutionGroup(
          id: 'demo-group-1',
          name: 'Once A',
          grade: InstitutionGrade.eleventh,
          studentCount: 0,
          teachers: const [
            AssignedGroupTeacher(
              membershipId: 'demo-owner',
              userId: 'demo-teacher',
              name: 'Profe Andrea',
              email: 'andrea@saberplus.demo',
              role: InstitutionMemberRole.owner,
            ),
          ],
          codes: const [],
        ),
      ];

  List<InstitutionGroup> _teacherGroups;
  StudentInstitutionGroups _studentGroups = const StudentInstitutionGroups(
    groups: [],
  );
  var _sequence = 1;

  @override
  Future<List<InstitutionGroup>> loadTeacherGroups() async =>
      List.unmodifiable(_teacherGroups);

  @override
  Future<List<InstitutionGroup>> createGroup({
    required String name,
    required InstitutionGrade grade,
  }) async {
    _teacherGroups = [
      ..._teacherGroups,
      InstitutionGroup(
        id: 'demo-group-${++_sequence}',
        name: name.trim(),
        grade: grade,
        studentCount: 0,
        teachers: const [
          AssignedGroupTeacher(
            membershipId: 'demo-owner',
            userId: 'demo-teacher',
            name: 'Profe Andrea',
            email: 'andrea@saberplus.demo',
            role: InstitutionMemberRole.owner,
          ),
        ],
        codes: const [],
      ),
    ];
    return loadTeacherGroups();
  }

  @override
  Future<List<InstitutionGroup>> deleteGroup(String groupId) async {
    _teacherGroups = _teacherGroups
        .where((group) => group.id != groupId)
        .toList(growable: false);
    return loadTeacherGroups();
  }

  @override
  Future<CreatedTemporaryGroupCode> createTemporaryCode({
    required String groupId,
    required int durationMinutes,
    required int maximumUses,
  }) async {
    final now = DateTime.now();
    final digit = ((++_sequence % 8) + 2).toString();
    final code = 'GRP-DEMO${List.filled(4, digit).join()}';
    final created = CreatedTemporaryGroupCode(
      id: 'demo-code-$_sequence',
      suffix: code.substring(code.length - 4),
      uses: 0,
      maximumUses: maximumUses,
      expiresAt: now.add(Duration(minutes: durationMinutes)),
      createdAt: now,
      code: code,
    );
    _replaceGroup(
      groupId,
      (group) => _copyGroup(
        group,
        codes: [
          ...group.codes,
          TemporaryGroupCode(
            id: created.id,
            suffix: created.suffix,
            uses: created.uses,
            maximumUses: created.maximumUses,
            expiresAt: created.expiresAt,
            createdAt: created.createdAt,
          ),
        ],
      ),
    );
    return created;
  }

  @override
  Future<List<InstitutionGroup>> revokeTemporaryCode({
    required String groupId,
    required String codeId,
  }) async {
    _replaceGroup(
      groupId,
      (group) => _copyGroup(
        group,
        codes: group.codes
            .where((code) => code.id != codeId)
            .toList(growable: false),
      ),
    );
    return loadTeacherGroups();
  }

  @override
  Future<List<InstitutionGroup>> assignTeacher({
    required String groupId,
    required String membershipId,
  }) async {
    _replaceGroup(
      groupId,
      (group) => _copyGroup(
        group,
        teachers: [
          ...group.teachers,
          AssignedGroupTeacher(
            membershipId: membershipId,
            userId: 'demo-user-$membershipId',
            name: 'Docente invitado',
            email: 'docente@saberplus.demo',
            role: InstitutionMemberRole.teacher,
          ),
        ],
      ),
    );
    return loadTeacherGroups();
  }

  @override
  Future<List<InstitutionGroup>> removeTeacher({
    required String groupId,
    required String membershipId,
  }) async {
    _replaceGroup(
      groupId,
      (group) => _copyGroup(
        group,
        teachers: group.teachers
            .where((teacher) => teacher.membershipId != membershipId)
            .toList(growable: false),
      ),
    );
    return loadTeacherGroups();
  }

  @override
  Future<StudentInstitutionGroups> loadStudentGroups() async => _studentGroups;

  @override
  Future<StudentGroupPreview> previewCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (!RegExp(r'^GRP-[A-Z2-9]{8}$').hasMatch(normalized)) {
      throw StateError('El código no existe, expiró o ya fue usado.');
    }
    return StudentGroupPreview(
      status: _studentGroups.groups.any((group) => group.id == 'demo-group-1')
          ? StudentGroupPreviewStatus.alreadyLinked
          : StudentGroupPreviewStatus.available,
      canJoin: !_studentGroups.groups.any(
        (group) => group.id == 'demo-group-1',
      ),
      requiresAcceptance: true,
      groupId: 'demo-group-1',
      groupName: 'Once A',
      grade: InstitutionGrade.eleventh,
      institutionId: 'demo-institution-1',
      institutionName: 'Colegio demostrativo',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      availableUses: 39,
    );
  }

  @override
  Future<StudentInstitutionGroups> acceptCode(String code) async {
    final preview = await previewCode(code);
    if (!preview.canJoin) throw StateError('Ya perteneces a ese grupo.');
    _studentGroups = StudentInstitutionGroups(
      institutionId: preview.institutionId,
      groups: [
        StudentInstitutionGroup(
          id: preview.groupId,
          name: preview.groupName,
          grade: preview.grade,
          institutionId: preview.institutionId,
          institutionName: preview.institutionName,
          joinedAt: DateTime.now(),
          explicitlyAccepted: true,
        ),
      ],
    );
    return _studentGroups;
  }

  void _replaceGroup(
    String groupId,
    InstitutionGroup Function(InstitutionGroup) update,
  ) {
    _teacherGroups = _teacherGroups
        .map((group) => group.id == groupId ? update(group) : group)
        .toList(growable: false);
  }

  InstitutionGroup _copyGroup(
    InstitutionGroup group, {
    List<AssignedGroupTeacher>? teachers,
    List<TemporaryGroupCode>? codes,
  }) => InstitutionGroup(
    id: group.id,
    name: group.name,
    grade: group.grade,
    studentCount: group.studentCount,
    teachers: teachers ?? group.teachers,
    codes: codes ?? group.codes,
  );
}
