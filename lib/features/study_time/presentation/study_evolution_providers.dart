import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/access_token_store.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../../core/sync/safe_sync_models.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/pomodoro_sync_worker.dart';
import '../data/study_evolution_repository.dart';
import '../domain/study_evolution.dart';

typedef StudyEvolutionQuery = ({int days, String? studentId});
final studyEvolutionRepositoryProvider = Provider<StudyEvolutionRepository>(
  (ref) =>
      ref.watch(sessionControllerProvider.select((s) => s.user?.isDemo)) == true
      ? DemoStudyEvolutionRepository()
      : RemoteStudyEvolutionRepository(ref.watch(dioProvider)),
);
final studyEvolutionProvider = FutureProvider.autoDispose
    .family<StudyEvolution, StudyEvolutionQuery>((ref, query) async {
      final user = ref.watch(sessionControllerProvider).user;
      final expectedRole = query.studentId == null
          ? AppRole.student
          : AppRole.teacher;
      if (user?.role != expectedRole) {
        throw const ApiError(
          code: 'study_time_session',
          message:
              'Inicia sesión con el rol correspondiente para consultar el informe.',
        );
      }
      final cancel = CancelToken();
      ref.onDispose(() => cancel.cancel());
      return ref
          .watch(studyEvolutionRepositoryProvider)
          .load(query.days, studentId: query.studentId, cancelToken: cancel);
    });

final pomodoroSyncWorkerProvider = Provider<PomodoroSyncWorker>((ref) {
  ref.watch(
    sessionControllerProvider.select(
      (s) => (s.user?.id, s.user?.role, s.user?.isDemo),
    ),
  );
  var disposed = false;
  final worker = PomodoroSyncWorker(
    ref.watch(appDatabaseProvider),
    ref.watch(dioProvider),
    currentSession: () {
      if (disposed) return null;
      final user = ref.read(sessionControllerProvider).user;
      final tokens = ref.read(accessTokenStoreProvider);
      if (user == null ||
          user.isDemo ||
          user.role != AppRole.student ||
          tokens.accessToken == null) {
        return null;
      }
      return SyncSessionSnapshot(userId: user.id, revision: tokens.revision);
    },
  );
  ref.onDispose(() {
    disposed = true;
    worker.dispose();
  });
  return worker;
});
final pomodoroQueueProvider =
    StreamProvider.autoDispose<List<PomodoroSyncEntry>>((ref) {
      final user = ref.watch(sessionControllerProvider).user;
      if (user == null || user.isDemo || user.role != AppRole.student) {
        return Stream.value([]);
      }
      return ref.watch(appDatabaseProvider).watchPomodoroQueue(user.id);
    });

// Reconexión sin plugin adicional: al entrar y hasta una vez por minuto mientras
// está en primer plano. No se transmite telemetría de pantallas abiertas.
final studyTimeAutoSyncProvider = Provider<void>((ref) {
  final user = ref.watch(
    sessionControllerProvider.select(
      (s) => (s.user?.id, s.user?.role, s.user?.isDemo),
    ),
  );
  if (user.$1 == null || user.$2 != AppRole.student || user.$3 != false) return;
  final worker = ref.watch(pomodoroSyncWorkerProvider);
  var disposed = false;
  Future<void> tick() async {
    if (disposed) return;
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;
    try {
      final count = await worker.synchronize();
      if (!disposed && count > 0) ref.invalidate(studyEvolutionProvider);
    } on Object {
      /* La cola persiste; el botón manual informa errores de disco. */
    }
  }

  final timer = Timer.periodic(
    const Duration(minutes: 1),
    (_) => unawaited(tick()),
  );
  ref.onDispose(() {
    disposed = true;
    timer.cancel();
  });
  unawaited(Future<void>.microtask(tick));
});
