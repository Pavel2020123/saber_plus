import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/session_controller.dart';
import 'drift_safe_sync_repository.dart';
import 'safe_sync_models.dart';

final syncOperationsProvider = StreamProvider<List<SyncOperation>>((ref) {
  final user = ref.watch(sessionControllerProvider).user;
  if (user == null || user.isDemo) return Stream.value(const []);
  return ref.watch(safeSyncRepositoryProvider).watchOperations(user.id);
});

class SafeSyncState {
  const SafeSyncState({this.isSyncing = false, this.lastReport, this.error});

  final bool isSyncing;
  final SyncReport? lastReport;
  final String? error;
}

class SafeSyncController extends Notifier<SafeSyncState> {
  @override
  SafeSyncState build() => const SafeSyncState();

  Future<void> synchronize() async {
    final user = ref.read(sessionControllerProvider).user;
    if (user == null || user.isDemo || state.isSyncing) return;
    state = SafeSyncState(isSyncing: true, lastReport: state.lastReport);
    try {
      final report = await ref
          .read(safeSyncRepositoryProvider)
          .synchronize(user.id);
      state = SafeSyncState(lastReport: report);
    } on Object {
      state = SafeSyncState(
        lastReport: state.lastReport,
        error: 'No pudimos revisar la cola de sincronización.',
      );
    }
  }

  Future<void> retry(String operationId) async {
    final user = ref.read(sessionControllerProvider).user;
    if (user == null || user.isDemo || state.isSyncing) return;
    state = SafeSyncState(isSyncing: true, lastReport: state.lastReport);
    try {
      final report = await ref
          .read(safeSyncRepositoryProvider)
          .retry(user.id, operationId);
      state = SafeSyncState(lastReport: report);
    } on Object {
      state = SafeSyncState(
        lastReport: state.lastReport,
        error: 'No pudimos reintentar esta operación.',
      );
    }
  }

  Future<void> discard(String operationId) async {
    final user = ref.read(sessionControllerProvider).user;
    if (user == null || user.isDemo) return;
    try {
      await ref.read(safeSyncRepositoryProvider).discard(user.id, operationId);
    } on Object {
      state = SafeSyncState(
        lastReport: state.lastReport,
        error: 'No pudimos descartar esta operación.',
      );
    }
  }
}

final safeSyncControllerProvider =
    NotifierProvider<SafeSyncController, SafeSyncState>(SafeSyncController.new);
