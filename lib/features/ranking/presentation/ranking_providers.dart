import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_ranking_repository.dart';
import '../data/remote_ranking_repository.dart';
import '../domain/ranking_models.dart';
import '../domain/ranking_repository.dart';

typedef RankingQuery = ({RankingScope scope, RankingPeriod period});

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  final isDemo = ref.watch(
    sessionControllerProvider.select(
      (session) => session.user?.isDemo ?? false,
    ),
  );
  if (isDemo) return DemoRankingRepository();
  return RemoteRankingRepository(ref.watch(dioProvider));
});

final rankingBoardProvider = FutureProvider.autoDispose
    .family<RankingBoard, RankingQuery>(
      (ref, query) => ref
          .watch(rankingRepositoryProvider)
          .load(scope: query.scope, period: query.period),
    );
