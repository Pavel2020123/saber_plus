import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_teacher_detailed_analytics_repository.dart';
import '../data/remote_teacher_detailed_analytics_repository.dart';
import '../domain/teacher_detailed_analytics_models.dart';
import '../domain/teacher_detailed_analytics_repository.dart';

final teacherDetailedAnalyticsRepositoryProvider =
    Provider<TeacherDetailedAnalyticsRepository>((ref) {
      final demo = ref.watch(
        sessionControllerProvider.select(
          (session) => session.user?.isDemo ?? false,
        ),
      );
      return demo
          ? DemoTeacherDetailedAnalyticsRepository()
          : RemoteTeacherDetailedAnalyticsRepository(ref.watch(dioProvider));
    });

class TeacherDetailedAnalyticsController
    extends AutoDisposeAsyncNotifier<TeacherDetailedDashboard> {
  @override
  Future<TeacherDetailedDashboard> build() =>
      ref.watch(teacherDetailedAnalyticsRepositoryProvider).load();

  Future<void> reload() async {
    state = const AsyncLoading<TeacherDetailedDashboard>().copyWithPrevious(
      state,
    );
    state = await AsyncValue.guard(
      () => ref.read(teacherDetailedAnalyticsRepositoryProvider).load(),
    );
  }
}

final teacherDetailedAnalyticsControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      TeacherDetailedAnalyticsController,
      TeacherDetailedDashboard
    >(TeacherDetailedAnalyticsController.new);
