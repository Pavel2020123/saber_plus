import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/session_controller.dart';
import '../data/remote_ghost_duel_repository.dart';
import '../data/shared_preferences_ghost_duel_repository.dart';
import '../domain/ghost_duel_repository.dart';

final ghostDuelRepositoryProvider = Provider<GhostDuelRepository>((ref) {
  final isDemo = ref.watch(sessionControllerProvider).user?.isDemo ?? false;
  if (isDemo) return SharedPreferencesGhostDuelRepository();
  return RemoteGhostDuelRepository(ref.watch(dioProvider));
});

final ghostDuelUserIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionControllerProvider).user?.id;
});
