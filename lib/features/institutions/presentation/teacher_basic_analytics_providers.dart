import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_teacher_basic_analytics_repository.dart';
import '../data/remote_teacher_basic_analytics_repository.dart';
import '../domain/teacher_basic_analytics_models.dart';
import '../domain/teacher_basic_analytics_repository.dart';

final teacherBasicAnalyticsRepositoryProvider =
    Provider<TeacherBasicAnalyticsRepository>((ref) {
      final demo = ref.watch(
        sessionControllerProvider.select(
          (session) => session.user?.isDemo ?? false,
        ),
      );
      return demo
          ? DemoTeacherBasicAnalyticsRepository()
          : RemoteTeacherBasicAnalyticsRepository(ref.watch(dioProvider));
    });

class TeacherBasicAnalyticsController
    extends AutoDisposeAsyncNotifier<TeacherBasicAnalytics> {
  @override
  Future<TeacherBasicAnalytics> build() =>
      ref.watch(teacherBasicAnalyticsRepositoryProvider).load();

  Future<void> reload() async {
    state = const AsyncLoading<TeacherBasicAnalytics>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(teacherBasicAnalyticsRepositoryProvider).load(),
    );
  }
}

final teacherBasicAnalyticsControllerProvider =
    AutoDisposeAsyncNotifierProvider<
      TeacherBasicAnalyticsController,
      TeacherBasicAnalytics
    >(TeacherBasicAnalyticsController.new);
