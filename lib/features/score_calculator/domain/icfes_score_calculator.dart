class IcfesAreaScores {
  const IcfesAreaScores({
    required this.criticalReading,
    required this.mathematics,
    required this.socialSciences,
    required this.naturalSciences,
    required this.english,
  });

  final int criticalReading;
  final int mathematics;
  final int socialSciences;
  final int naturalSciences;
  final int english;

  Iterable<int> get values => [
    criticalReading,
    mathematics,
    socialSciences,
    naturalSciences,
    english,
  ];

  bool get isValid => values.every((score) => score >= 0 && score <= 100);
}

class IcfesScoreCalculator {
  const IcfesScoreCalculator._();

  static int? globalScore(IcfesAreaScores scores) {
    if (!scores.isValid) return null;
    final weightedTotal =
        3 * scores.criticalReading +
        3 * scores.mathematics +
        3 * scores.socialSciences +
        3 * scores.naturalSciences +
        scores.english;
    return ((weightedTotal / 13) * 5).round().clamp(0, 500);
  }
}
