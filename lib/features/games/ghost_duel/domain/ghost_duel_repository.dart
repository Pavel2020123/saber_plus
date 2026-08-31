import 'ghost_duel_models.dart';

abstract interface class GhostDuelRepository {
  Future<GhostRun?> loadBest({
    required String userId,
    required GhostDuelKey key,
  });

  Future<GhostSaveResult> saveIfBetter(GhostRun run);
}
