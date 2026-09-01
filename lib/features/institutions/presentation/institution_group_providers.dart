import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_institution_group_repository.dart';
import '../data/remote_institution_group_repository.dart';
import '../domain/institution_group_models.dart';
import '../domain/institution_group_repository.dart';

final institutionGroupRepositoryProvider = Provider<InstitutionGroupRepository>(
  (ref) {
    final demo = ref.watch(
      sessionControllerProvider.select((state) => state.user?.isDemo ?? false),
    );
    return demo
        ? DemoInstitutionGroupRepository()
        : RemoteInstitutionGroupRepository(ref.watch(dioProvider));
  },
);

class InstitutionGroupsController
    extends AutoDisposeAsyncNotifier<List<InstitutionGroup>> {
  @override
  Future<List<InstitutionGroup>> build() =>
      ref.watch(institutionGroupRepositoryProvider).loadTeacherGroups();

  Future<void> reload() async {
    state = const AsyncLoading<List<InstitutionGroup>>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(
      () => ref.read(institutionGroupRepositoryProvider).loadTeacherGroups(),
    );
  }

  Future<void> createGroup({
    required String name,
    required InstitutionGrade grade,
  }) => _replace(
    ref
        .read(institutionGroupRepositoryProvider)
        .createGroup(name: name, grade: grade),
  );

  Future<void> deleteGroup(String groupId) => _replace(
    ref.read(institutionGroupRepositoryProvider).deleteGroup(groupId),
  );

  Future<CreatedTemporaryGroupCode> createTemporaryCode({
    required String groupId,
    required int durationMinutes,
    required int maximumUses,
  }) async {
    final repository = ref.read(institutionGroupRepositoryProvider);
    final code = await repository.createTemporaryCode(
      groupId: groupId,
      durationMinutes: durationMinutes,
      maximumUses: maximumUses,
    );
    state = AsyncData(await repository.loadTeacherGroups());
    return code;
  }

  Future<void> revokeTemporaryCode({
    required String groupId,
    required String codeId,
  }) => _replace(
    ref
        .read(institutionGroupRepositoryProvider)
        .revokeTemporaryCode(groupId: groupId, codeId: codeId),
  );

  Future<void> assignTeacher({
    required String groupId,
    required String membershipId,
  }) => _replace(
    ref
        .read(institutionGroupRepositoryProvider)
        .assignTeacher(groupId: groupId, membershipId: membershipId),
  );

  Future<void> removeTeacher({
    required String groupId,
    required String membershipId,
  }) => _replace(
    ref
        .read(institutionGroupRepositoryProvider)
        .removeTeacher(groupId: groupId, membershipId: membershipId),
  );

  Future<void> _replace(Future<List<InstitutionGroup>> operation) async {
    state = AsyncData(await operation);
  }
}

final institutionGroupsControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      InstitutionGroupsController,
      List<InstitutionGroup>
    >(InstitutionGroupsController.new);

class StudentGroupsController
    extends AutoDisposeAsyncNotifier<StudentInstitutionGroups> {
  @override
  Future<StudentInstitutionGroups> build() =>
      ref.watch(institutionGroupRepositoryProvider).loadStudentGroups();

  Future<void> reload() async {
    state = const AsyncLoading<StudentInstitutionGroups>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(
      () => ref.read(institutionGroupRepositoryProvider).loadStudentGroups(),
    );
  }

  Future<StudentGroupPreview> previewCode(String code) => ref
      .read(institutionGroupRepositoryProvider)
      .previewCode(code.trim().toUpperCase());

  Future<void> acceptCode(String code) async {
    final groups = await ref
        .read(institutionGroupRepositoryProvider)
        .acceptCode(code.trim().toUpperCase());
    state = AsyncData(groups);
  }
}

final studentGroupsControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      StudentGroupsController,
      StudentInstitutionGroups
    >(StudentGroupsController.new);
