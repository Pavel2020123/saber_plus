import 'ranking_models.dart';

abstract interface class RankingRepository {
  Future<RankingBoard> load({
    required RankingScope scope,
    required RankingPeriod period,
  });
}
