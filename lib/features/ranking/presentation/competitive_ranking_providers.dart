import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/competitive_ranking_repository.dart';
import '../domain/competitive_ranking_models.dart';

typedef CompetitiveQuery = ({CompetitiveGame game, int season});

final competitiveRankingRepositoryProvider =
    Provider<CompetitiveRankingRepository>((ref) {
      final user = ref.watch(sessionControllerProvider.select((s) => s.user));
      return user?.isDemo == true
          ? _DemoUnavailable()
          : RemoteCompetitiveRankingRepository(ref.watch(dioProvider));
    });
final competitiveBoardProvider = FutureProvider.autoDispose
    .family<CompetitiveBoard, CompetitiveQuery>(
      (ref, query) => ref
          .watch(competitiveRankingRepositoryProvider)
          .load(game: query.game, season: query.season),
    );

class _DemoUnavailable implements CompetitiveRankingRepository {
  @override
  Future<CompetitiveBoard> load({
    required CompetitiveGame game,
    required int season,
  }) async {
    throw const ApiError(
      code: 'demo_unavailable',
      message:
          'Inicia sesión con una cuenta de estudiante para consultar el ranking competitivo.',
    );
  }
}
