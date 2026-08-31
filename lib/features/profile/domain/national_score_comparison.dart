enum Saber11Calendar {
  calendarA('Calendario A'),
  calendarB('Calendario B');

  const Saber11Calendar(this.label);

  final String label;
}

class NationalScoreReference {
  const NationalScoreReference({
    required this.calendar,
    required this.year,
    required this.averageGlobalScore,
    required this.verifiedOn,
    required this.sourceUrl,
  });

  final Saber11Calendar calendar;
  final int year;
  final double averageGlobalScore;
  final String verifiedOn;
  final String sourceUrl;

  Uri get sourceUri => Uri.parse(sourceUrl);
}

class NationalScoreComparison {
  const NationalScoreComparison({
    required this.estimatedScore,
    required this.reference,
  });

  final int estimatedScore;
  final NationalScoreReference reference;

  double get difference => estimatedScore - reference.averageGlobalScore;
  bool get isAboveReference => difference > 0;
  bool get isBelowReference => difference < 0;
}

const trustedNationalStatisticsHosts = <String>{'www.icfes.gov.co'};

bool isTrustedNationalStatisticsUri(Uri uri) =>
    uri.scheme == 'https' &&
    uri.userInfo.isEmpty &&
    !uri.hasPort &&
    trustedNationalStatisticsHosts.contains(uri.host);

const nationalScoreReferences = <NationalScoreReference>[
  NationalScoreReference(
    calendar: Saber11Calendar.calendarA,
    year: 2025,
    averageGlobalScore: 263.5,
    verifiedOn: '2026-08-30',
    sourceUrl: 'https://www.icfes.gov.co/estadisticas-oficiales/',
  ),
  NationalScoreReference(
    calendar: Saber11Calendar.calendarB,
    year: 2025,
    averageGlobalScore: 318.6,
    verifiedOn: '2026-08-30',
    sourceUrl: 'https://www.icfes.gov.co/estadisticas-oficiales/',
  ),
];

NationalScoreReference referenceForCalendar(Saber11Calendar calendar) =>
    nationalScoreReferences.firstWhere((item) => item.calendar == calendar);
