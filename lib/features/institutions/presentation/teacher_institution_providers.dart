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
}

final teacherInstitutionControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      TeacherInstitutionController,
      TeacherInstitutionContext
    >(TeacherInstitutionController.new);
