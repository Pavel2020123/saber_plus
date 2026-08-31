import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/profile/domain/national_score_comparison.dart';

void main() {
  test('conserva referencias separadas para los calendarios A y B', () {
    final calendarA = referenceForCalendar(Saber11Calendar.calendarA);
    final calendarB = referenceForCalendar(Saber11Calendar.calendarB);

    expect(calendarA.year, 2025);
    expect(calendarA.averageGlobalScore, 263.5);
    expect(calendarB.year, 2025);
    expect(calendarB.averageGlobalScore, 318.6);
  });

  test('calcula la diferencia sin convertirla en percentil', () {
    final comparison = NationalScoreComparison(
      estimatedScore: 352,
      reference: referenceForCalendar(Saber11Calendar.calendarA),
    );

    expect(comparison.difference, 88.5);
    expect(comparison.isAboveReference, isTrue);
    expect(comparison.isBelowReference, isFalse);
  });

  test('acepta únicamente la fuente HTTPS oficial del ICFES', () {
    for (final reference in nationalScoreReferences) {
      expect(isTrustedNationalStatisticsUri(reference.sourceUri), isTrue);
      expect(reference.verifiedOn, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    }
    expect(
      isTrustedNationalStatisticsUri(
        Uri.parse('https://www.icfes.gov.co.ejemplo.com/estadisticas'),
      ),
      isFalse,
    );
  });
}
