import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/profile/domain/official_opportunity.dart';

void main() {
  test('el catálogo usa únicamente fuentes oficiales seguras', () {
    expect(officialOpportunityCatalog, isNotEmpty);
    for (final opportunity in officialOpportunityCatalog) {
      expect(isTrustedOfficialOpportunityUri(opportunity.officialUri), isTrue);
      expect(opportunity.verifiedOn, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    }
  });

  test('rechaza enlaces inseguros o dominios parecidos', () {
    expect(
      isTrustedOfficialOpportunityUri(
        Uri.parse('http://web.icetex.gov.co/convocatoria'),
      ),
      isFalse,
    );
    expect(
      isTrustedOfficialOpportunityUri(
        Uri.parse('https://web.icetex.gov.co.ejemplo.com/convocatoria'),
      ),
      isFalse,
    );
  });

  test('identifica el subsidio Andrés Bello como oportunidad por mérito', () {
    final merit = filterOfficialOpportunities(
      officialOpportunityCatalog,
      OpportunityCategory.merit,
    );

    expect(merit, hasLength(1));
    expect(merit.single.id, 'best-saber-11-results');
    expect(merit.single.eligibility.join(' '), contains('resolución oficial'));
    expect(merit.single.summary, contains('Distinción Andrés Bello'));
  });

  test('el filtro general conserva todas las oportunidades', () {
    final all = filterOfficialOpportunities(
      officialOpportunityCatalog,
      OpportunityCategory.all,
    );

    expect(all, hasLength(officialOpportunityCatalog.length));
  });
}
