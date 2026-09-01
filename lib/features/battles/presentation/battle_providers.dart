import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_battle_repository.dart';
import '../data/remote_battle_repository.dart';
import '../domain/battle_models.dart';
import '../domain/battle_repository.dart';

final battleRepositoryProvider = Provider<BattleRepository>((ref) {
  final isDemo = ref.watch(
    sessionControllerProvider.select(
      (session) => session.user?.isDemo ?? false,
    ),
  );
  if (isDemo) return DemoBattleRepository();
  return RemoteBattleRepository(ref.watch(dioProvider));
});

final battleDashboardProvider = FutureProvider.autoDispose<BattleDashboard>(
  (ref) => ref.watch(battleRepositoryProvider).loadDashboard(),
);

final battleDetailProvider = FutureProvider.autoDispose
    .family<BattleDetail, String>(
      (ref, battleId) =>
          ref.watch(battleRepositoryProvider).loadDetail(battleId),
    );

final blockedRivalsProvider = FutureProvider.autoDispose<List<BlockedRival>>(
  (ref) => ref.watch(battleRepositoryProvider).loadBlocks(),
);
