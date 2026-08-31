import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/session_controller.dart';
import '../data/shared_preferences_ghost_duel_repository.dart';
import '../domain/ghost_duel_repository.dart';

final ghostDuelRepositoryProvider = Provider<GhostDuelRepository>(
  (ref) => SharedPreferencesGhostDuelRepository(),
);

final ghostDuelUserIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionControllerProvider).user?.id;
});
