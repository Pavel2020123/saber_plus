enum CompetitiveGame {
  summit('SUMMIT', 'Cima'),
  guardian('GUARDIAN', 'Guardián'),
  rescue('STAR_RESCUE', 'Rescate de estrellas'),
  trivia('TRIVIA_RUSH', 'Trivia Rush'),
  ghost('GHOST_DUEL', 'Duelo fantasma'),
  tug('TUG_OF_WAR', 'Tira y afloja'),
  memory('MEMORY_MATCH', 'Memoria', available: false),
  battles('BATTLES', 'Batallas', available: false);

  const CompetitiveGame(this.backendValue, this.label, {this.available = true});
  final String backendValue;
  final String label;
  final bool available;
}

enum CompetitiveRankingState { participants, empty, unavailable }

// A UI suggestion only; the server remains authoritative for earned seasons.
int suggestedCompetitiveSeason(DateTime instant) =>
    instant.toUtc().subtract(const Duration(hours: 5)).year;

class CompetitiveEntry {
  const CompetitiveEntry(
    this.position,
    this.alias,
    this.xp,
    this.isCurrentUser,
  );
  final int position;
  final String alias;
  final int xp;
  final bool isCurrentUser;

  factory CompetitiveEntry.parse(Object? raw) {
    final json = _object(raw);
    _keys(json, {'posicion', 'alias', 'xp', 'esUsuarioActual'});
    final position = _integer(json['posicion'], 1, 9007199254740991);
    final xp = _integer(json['xp'], 1, 2147483647);
    final alias = json['alias'];
    final own = json['esUsuarioActual'];
    if (alias is! String || alias.trim().isEmpty || own is! bool) _invalid();
    return CompetitiveEntry(position, alias, xp, own);
  }

  bool sameAs(CompetitiveEntry other) =>
      position == other.position &&
      alias == other.alias &&
      xp == other.xp &&
      isCurrentUser == other.isCurrentUser;
}

class CompetitiveBoard {
  const CompetitiveBoard({
    required this.game,
    required this.season,
    required this.state,
    required this.totalParticipants,
    required this.entries,
    required this.myPosition,
  });
  final CompetitiveGame game;
  final int season;
  final CompetitiveRankingState state;
  final int? totalParticipants;
  final List<CompetitiveEntry> entries;
  final CompetitiveEntry? myPosition;

  factory CompetitiveBoard.parse(Object? raw) {
    final json = _object(raw);
    _keys(json, {
      'juego',
      'temporada',
      'limite',
      'estado',
      'totalParticipantes',
      'ranking',
      'miPosicion',
    });
    final matches = CompetitiveGame.values.where(
      (g) => g.backendValue == json['juego'],
    );
    if (matches.length != 1 || json['limite'] != 50 || json['limite'] is! int) {
      _invalid();
    }
    final game = matches.single;
    final season = _integer(json['temporada'], 1, 9999);
    final state = switch (json['estado']) {
      'CON_PARTICIPANTES' => CompetitiveRankingState.participants,
      'SIN_PARTICIPANTES' => CompetitiveRankingState.empty,
      'NO_DISPONIBLE' => CompetitiveRankingState.unavailable,
      _ => _invalid(),
    };
    final rawEntries = json['ranking'];
    if (rawEntries is! List || rawEntries.length > 50) _invalid();
    final entries = rawEntries.map(CompetitiveEntry.parse).toList();
    final mine = json['miPosicion'] == null
        ? null
        : CompetitiveEntry.parse(json['miPosicion']);
    final total = json['totalParticipantes'];
    if (state == CompetitiveRankingState.unavailable) {
      if (game.available ||
          total != null ||
          entries.isNotEmpty ||
          mine != null) {
        _invalid();
      }
    } else {
      if (!game.available) _invalid();
      final count = _integer(total, 0, 9007199254740991);
      if (state == CompetitiveRankingState.empty) {
        if (count != 0 || entries.isNotEmpty || mine != null) _invalid();
      } else {
        if (count == 0 || entries.length != (count < 50 ? count : 50)) {
          _invalid();
        }
        for (var i = 0; i < entries.length; i++) {
          if (entries[i].position != i + 1) _invalid();
          if (i > 0 && entries[i].xp > entries[i - 1].xp) _invalid();
        }
        final own = entries.where((e) => e.isCurrentUser).toList();
        if (mine == null) {
          if (own.isNotEmpty) _invalid();
        } else {
          if (!mine.isCurrentUser || mine.position > count) _invalid();
          if (mine.position <= entries.length) {
            if (own.length != 1 || !entries[mine.position - 1].sameAs(mine)) {
              _invalid();
            }
          } else if (own.isNotEmpty) {
            _invalid();
          }
        }
      }
    }
    return CompetitiveBoard(
      game: game,
      season: season,
      state: state,
      totalParticipants: total as int?,
      entries: List.unmodifiable(entries),
      myPosition: mine,
    );
  }
}

Map<String, dynamic> _object(Object? raw) {
  if (raw is! Map<String, dynamic>) _invalid();
  return raw;
}

void _keys(Map<String, dynamic> json, Set<String> keys) {
  if (json.length != keys.length || !json.keys.every(keys.contains)) _invalid();
}

int _integer(Object? value, int min, int max) {
  if (value is! int || value < min || value > max) _invalid();
  return value;
}

Never _invalid() =>
    throw const FormatException('Respuesta competitiva inválida.');
