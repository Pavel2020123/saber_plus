import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_teacher_institution_repository.dart';
import '../data/remote_teacher_institution_repository.dart';
import '../domain/teacher_institution_models.dart';
import '../domain/teacher_institution_repository.dart';

final teacherInstitutionRepositoryProvider =
    Provider<TeacherInstitutionRepository>((ref) {
      final isDemo = ref.watch(
        sessionControllerProvider.select(
          (session) => session.user?.isDemo ?? false,
        ),
      );
      if (isDemo) return DemoTeacherInstitutionRepository();
      return RemoteTeacherInstitutionRepository(ref.watch(dioProvider));
    });

class TeacherInstitutionController
    extends AutoDisposeAsyncNotifier<TeacherInstitutionContext> {
  @override
  Future<TeacherInstitutionContext> build() =>
      ref.watch(teacherInstitutionRepositoryProvider).loadContext();

  Future<void> reload() async {
    state = const AsyncLoading<TeacherInstitutionContext>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(
      () => ref.read(teacherInstitutionRepositoryProvider).loadContext(),
    );
  }

  Future<void> createInstitution({
    required String name,
    String? welcomeMessage,
  }) async {
    final context = await ref
        .read(teacherInstitutionRepositoryProvider)
        .createInstitution(name: name, welcomeMessage: welcomeMessage);
    state = AsyncData(context);
  }

  Future<void> requestJoin({
    required String institutionCode,
    String? message,
  }) async {
    final context = await ref
        .read(teacherInstitutionRepositoryProvider)
        .requestJoin(institutionCode: institutionCode, message: message);
    state = AsyncData(context);
  }

  Future<void> cancelJoinRequest() async {
    final context = await ref
        .read(teacherInstitutionRepositoryProvider)
        .cancelJoinRequest();
    state = AsyncData(context);
  }

  Future<void> respondInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    final context = await ref
        .read(teacherInstitutionRepositoryProvider)
        .respondInvitation(invitationId: invitationId, accept: accept);
    state = AsyncData(context);
  }
}

final teacherInstitutionControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      TeacherInstitutionController,
      TeacherInstitutionContext
    >(TeacherInstitutionController.new);

class InstitutionAdministrationController
    extends AutoDisposeAsyncNotifier<InstitutionAdministration> {
  @override
  Future<InstitutionAdministration> build() =>
      ref.watch(teacherInstitutionRepositoryProvider).loadAdministration();

  Future<void> reload() async {
    state = const AsyncLoading<InstitutionAdministration>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(
      () => ref.read(teacherInstitutionRepositoryProvider).loadAdministration(),
    );
  }

  Future<void> reviewRequest({
    required String requestId,
    required bool approve,
  }) => _replace(
    ref
        .read(teacherInstitutionRepositoryProvider)
        .reviewRequest(requestId: requestId, approve: approve),
  );

  Future<void> inviteMember({
    required String email,
    required InstitutionMemberRole role,
  }) => _replace(
    ref
        .read(teacherInstitutionRepositoryProvider)
        .inviteMember(email: email, role: role),
  );

  Future<void> cancelInvitation(String invitationId) => _replace(
    ref
        .read(teacherInstitutionRepositoryProvider)
        .cancelInvitation(invitationId),
  );

  Future<void> changeMemberRole({
    required String membershipId,
    required InstitutionMemberRole role,
  }) => _replace(
    ref
        .read(teacherInstitutionRepositoryProvider)
        .changeMemberRole(membershipId: membershipId, role: role),
  );

  Future<void> removeMember(String membershipId) => _replace(
    ref.read(teacherInstitutionRepositoryProvider).removeMember(membershipId),
  );

  Future<void> transferOwnership({
    required String membershipId,
    required String confirmationCode,
  }) => _replace(
    ref
        .read(teacherInstitutionRepositoryProvider)
        .transferOwnership(
          membershipId: membershipId,
          confirmationCode: confirmationCode,
        ),
  );

  Future<void> _replace(Future<InstitutionAdministration> operation) async {
    state = AsyncData(await operation);
  }
}

final institutionAdministrationControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      InstitutionAdministrationController,
      InstitutionAdministration
    >(InstitutionAdministrationController.new);
