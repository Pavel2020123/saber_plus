/// Artwork catalog only. Ownership and annual awards must come from the server.
enum BadgeGame {
  trivia('Trivia Rush', 'triviarush'),
  ghost('Duelo fantasma', 'duelofantasma'),
  summit('Salto a la cima', 'saltoalacima'),
  tug('Tira y afloja', 'tirayafloja');

  const BadgeGame(this.label, this.filePrefix);
  final String label;
  final String filePrefix;
}

class RankingBadgeArt {
  const RankingBadgeArt(this.game, this.first, this.last);

  final BadgeGame game;
  final int first;
  final int last;

  String get rangeLabel => first == last ? 'TOP $first' : 'TOP $first–$last';

  String get assetPath {
    // Original filenames contain a typo; the supplied artwork says 6–10.
    final suffix = first == last
        ? '$first'
        : first == 6 && (game == BadgeGame.trivia || game == BadgeGame.ghost)
        ? '6-11'
        : '$first-$last';
    return 'assets/characters/sabi/insignias/${game.label}/'
        '${game.filePrefix}_top$suffix.png';
  }

  static List<RankingBadgeArt> forGame(BadgeGame game) => [
    for (var rank = 1; rank <= 5; rank++) RankingBadgeArt(game, rank, rank),
    RankingBadgeArt(game, 6, 10),
    RankingBadgeArt(game, 11, 20),
    RankingBadgeArt(game, 21, 30),
    RankingBadgeArt(game, 31, 40),
    RankingBadgeArt(game, 41, 50),
  ];

  static RankingBadgeArt? forPosition(BadgeGame game, int position) {
    for (final art in forGame(game)) {
      if (position >= art.first && position <= art.last) return art;
    }
    return null;
  }
}
