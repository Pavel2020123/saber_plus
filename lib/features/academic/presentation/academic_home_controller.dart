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

  Future<DiagnosticSummary> finishDiagnostic(
    List<DiagnosticAnswer> answers,
  ) async {
    final repository = ref.read(academicRepositoryProvider);
    var completed = await repository.finishDiagnostic(answers);

    // La calificación ya quedó guardada. Si falla el cuaderno, conservamos el
    // resultado para evitar que la interfaz sugiera enviar el intento otra vez.
    try {
      final weakTopics = await repository.loadWeakTopics();
      completed = completed.copyWith(weakTopics: weakTopics);
    } on Object {
      // El resultado por área sigue disponible aunque este complemento falle.
    }
    return completed;
  }

  void acceptDiagnosticResult(DiagnosticSummary diagnostic) {
    _replaceDiagnostic(diagnostic);
  }

  void _replaceDiagnostic(DiagnosticSummary diagnostic) {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(diagnostic: diagnostic));
    }
  }
}

final academicHomeControllerProvider =
    AutoDisposeAsyncNotifierProvider<AcademicHomeController, AcademicHomeData>(
      AcademicHomeController.new,
    );

final diagnosticWeakTopicsProvider =
    FutureProvider.autoDispose<List<WeakTopic>>((ref) async {
      final user = ref.watch(sessionControllerProvider).user;
      if (user?.isDemo ?? false) return const [];
      return ref.watch(academicRepositoryProvider).loadWeakTopics();
    });
