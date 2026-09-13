import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_teacher_priority_repository.dart';
import '../data/teacher_priority_repository.dart';
import '../domain/teacher_priority.dart';

final teacherPriorityRepositoryProvider = Provider<TeacherPriorityRepository>((
  ref,
) {
  final identity = ref.watch(
    sessionControllerProvider.select(
      (s) => (s.user?.id, s.user?.role, s.user?.isDemo),
    ),
  );
  return identity.$3 == true
      ? DemoTeacherPriorityRepository()
      : RemoteTeacherPriorityRepository(ref.watch(dioProvider));
});
final teacherPriorityProvider = FutureProvider.autoDispose
    .family<PriorityBundle, PriorityQuery>((ref, query) async {
      final session = ref.watch(sessionControllerProvider);
      final expected = query.view == PriorityView.student
          ? AppRole.student
          : AppRole.teacher;
      if (session.user?.role != expected) {
        throw const ApiError(
          code: 'priority_session_required',
          message:
              'Inicia sesión con el rol correspondiente para consultar prioridades.',
        );
      }
      final cancel = CancelToken();
      ref.onDispose(() => cancel.cancel());
      return ref
          .watch(teacherPriorityRepositoryProvider)
          .load(query, cancelToken: cancel);
    });
