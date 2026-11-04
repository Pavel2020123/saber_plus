import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/domain/personal_return_eligibility.dart';

void main() {
  Map<String, dynamic> valid() => {
    'puedeVolver': true,
    'gestionada': false,
    'asignacionId': 'assignment',
    'versionAsignacion': '2026-11-03T12:00:00.000Z',
  };

  test(
    'accepts an explicit backend decision without consulting device time',
    () {
      final result = PersonalReturnEligibility.fromJson(valid());
      expect(result.allowed, isTrue);
      expect(result.assignmentVersion, '2026-11-03T12:00:00.000Z');
    },
  );

  test('allows read-only managed snapshot with no assignment', () {
    final result = PersonalReturnEligibility.fromJson({
      'puedeVolver': false,
      'gestionada': true,
      'asignacionId': null,
      'versionAsignacion': null,
    });
    expect(result.allowed, isFalse);
    expect(result.managed, isTrue);
  });

  for (final mutation in <Map<String, dynamic>>[
    {'gestionada': true},
    {'puedeVolver': 'true'},
    {'asignacionId': null},
    {'versionAsignacion': null},
    {'versionAsignacion': '2026-11-03T12:00:00'},
    {'versionAsignacion': 'invalid'},
  ]) {
    test('rejects inconsistent permission $mutation', () {
      expect(
        () => PersonalReturnEligibility.fromJson({...valid(), ...mutation}),
        throwsFormatException,
      );
    });
  }
}
