import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/auth/domain/institutional_access.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/question_reports/domain/question_report.dart';

void main() {
  for (final state in InstitutionalLicenseState.values) {
    test('reportar sin correo requiere origen y licencia activa: $state', () {
      final user = UserSession(
        id: 'managed',
        firstName: 'Ana',
        role: AppRole.student,
        emailVerified: false,
        institutionalUsername: 'ana@colegio.example',
        institutionalAccess: InstitutionalAccess(
          institutionId: 'school',
          state: state,
          managedAccount: true,
          hasAssignment: true,
          practiceAllowed: state == InstitutionalLicenseState.active,
          historyAllowed: true,
          validatedAt: DateTime.utc(2026, 11, 3),
        ),
      );
      expect(
        canReportQuestions(user),
        state == InstitutionalLicenseState.active,
      );
      expect(user.emailVerified, isFalse);
    });
  }
  test(
    'FK institucional sola y personal sin correo verificado no habilitan reportes',
    () {
      expect(
        canReportQuestions(
          const UserSession(
            id: 'student',
            firstName: 'Ana',
            role: AppRole.student,
            emailVerified: false,
            institutionId: 'school',
          ),
        ),
        isFalse,
      );
    },
  );
}
