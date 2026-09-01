import '../domain/ranking_models.dart';
import '../domain/ranking_repository.dart';

class DemoRankingRepository implements RankingRepository {
  @override
  Future<RankingBoard> load({
    required RankingScope scope,
    required RankingPeriod period,
  }) async {
    final multiplier = switch (period) {
      RankingPeriod.week => 1,
      RankingPeriod.month => 4,
      RankingPeriod.total => 12,
    };
    final baseEntries = [
      const RankingEntry(
        position: 1,
        alias: 'Estudiante Cóndor 184527',
        xp: 980,
        isCurrentUser: false,
      ),
      const RankingEntry(
        position: 2,
        alias: 'Estudiante Colibrí 527416',
        xp: 820,
        isCurrentUser: false,
      ),
      const RankingEntry(
        position: 3,
        alias: 'Estudiante Jaguar 306842',
        xp: 730,
        isCurrentUser: false,
      ),
      const RankingEntry(
        position: 4,
        alias: 'Tú',
        xp: 620,
        isCurrentUser: true,
      ),
      const RankingEntry(
        position: 5,
        alias: 'Estudiante Zorro 941305',
        xp: 510,
        isCurrentUser: false,
      ),
    ];
    final entries = baseEntries
        .map(
          (entry) => RankingEntry(
            position: entry.position,
            alias: entry.alias,
            xp: entry.xp * multiplier,
            isCurrentUser: entry.isCurrentUser,
          ),
        )
        .toList(growable: false);
    return RankingBoard(
      scope: scope,
      period: period,
      scopeName: scope == RankingScope.global ? 'SaberPlus' : 'Mi institución',
      institutionAvailable: true,
      totalParticipants: scope == RankingScope.global ? 2847 : 36,
      updatedAt: DateTime.now(),
      entries: entries,
      myPosition: entries.firstWhere((entry) => entry.isCurrentUser),
      identitiesProtected: true,
    );
  }
}
