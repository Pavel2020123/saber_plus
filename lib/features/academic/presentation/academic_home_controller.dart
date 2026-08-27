import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_controller.dart';
import '../data/remote_academic_repository.dart';
import '../domain/academic_models.dart';

class AcademicHomeController
    extends AutoDisposeAsyncNotifier<AcademicHomeData> {
  @override
  Future<AcademicHomeData> build() async {
    final user = ref.watch(sessionControllerProvider).user;
    if (user?.isDemo ?? false) return AcademicHomeData.demo;
    return ref.watch(academicRepositoryProvider).loadHome();
  }

  Future<void> reload() async {
    state = const AsyncLoading<AcademicHomeData>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(academicRepositoryProvider).loadHome(),
    );
  }

  Future<bool> startDiagnostic() async {
    final previous = state.valueOrNull;
    state = const AsyncLoading<AcademicHomeData>().copyWithPrevious(state);
    try {
      final diagnostic = await ref
          .read(academicRepositoryProvider)
          .startDiagnostic();
      if (previous == null) {
        state = AsyncData(
          await ref.read(academicRepositoryProvider).loadHome(),
        );
      } else {
        state = AsyncData(previous.copyWith(diagnostic: diagnostic));
      }
      return true;
    } on Object catch (error, stackTrace) {
      state = AsyncError<AcademicHomeData>(
        error,
        stackTrace,
      ).copyWithPrevious(state);
      return false;
    }
  }
}

final academicHomeControllerProvider =
    AutoDisposeAsyncNotifierProvider<AcademicHomeController, AcademicHomeData>(
      AcademicHomeController.new,
    );
