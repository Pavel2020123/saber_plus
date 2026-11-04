import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saber_plus/app/router.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/domain/institutional_access.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';

class _MutableSession extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(id: 'student', firstName: 'Ana', role: AppRole.student),
  );

  void expireInstitution() {
    state = SessionState.authenticated(
      UserSession(
        id: 'student',
        firstName: 'Ana',
        role: AppRole.student,
        institutionalAccess: InstitutionalAccess(
          institutionId: 'school',
          state: InstitutionalLicenseState.expired,
          managedAccount: true,
          hasAssignment: true,
          practiceAllowed: false,
          historyAllowed: true,
          validatedAt: DateTime.utc(2026, 11, 3),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'cambio de licencia no reconstruye el router ni desecha su navegación',
    () {
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWith(_MutableSession.new),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(appRouterProvider);
      (container.read(sessionControllerProvider.notifier) as _MutableSession)
          .expireInstitution();
      expect(container.read(appRouterProvider), same(router));
      expect(
        container
            .read(sessionControllerProvider)
            .user
            ?.institutionalAccess
            ?.historyAllowed,
        isTrue,
      );
    },
  );
}
