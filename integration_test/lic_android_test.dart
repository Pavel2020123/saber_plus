// Dedicated test entrypoint: real Android, real local API, no production driver.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:saber_plus/app/app.dart';
import 'package:saber_plus/app/router.dart';
import 'package:saber_plus/core/config/environment.dart';
import 'package:saber_plus/features/auth/domain/institutional_access.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'LIC Android: temporary login, priorities, privacy, expiry and return',
    (tester) async {
      expect(Platform.isAndroid, isTrue);
      expect(const bool.fromEnvironment('LIC_ANDROID_LOCAL'), isTrue);
      expect(AppConfig.current.apiBaseUrl, 'http://127.0.0.1:43187');
      expect(AppConfig.current.demoMode, isFalse);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SaberPlusApp(),
        ),
      );
      Future<void> until(bool Function() condition, String stage) async {
        final watch = Stopwatch()..start();
        while (!condition()) {
          if (watch.elapsed > const Duration(seconds: 60)) {
            fail('Timed out at $stage');
          }
          await tester.pump(const Duration(milliseconds: 200));
        }
        await tester.pump(const Duration(milliseconds: 400));
      }

      Future<void> visible(Finder finder) async {
        final watch = Stopwatch()..start();
        var frames = 0;
        while (finder.evaluate().isEmpty) {
          if (watch.elapsed > const Duration(seconds: 60)) {
            fail('Control did not appear: $finder');
          }
          await tester.pump(const Duration(milliseconds: 200));
          frames++;
          if (frames % 6 == 0 && find.byType(ListView).evaluate().isNotEmpty) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -180),
            );
          }
        }
        await tester.ensureVisible(finder.first);
        await tester.pump(const Duration(milliseconds: 300));
      }

      Future<void> tapText(String text) async {
        final finder = find.text(text);
        await visible(finder);
        await tester.tap(finder.first);
        await tester.pump(const Duration(milliseconds: 400));
      }

      Future<void> route(String path) async {
        container.read(appRouterProvider).go(path);
        await tester.pump(const Duration(milliseconds: 600));
      }

      var surfaceConverted = false;
      Future<void> screenshot(String name) async {
        if (!surfaceConverted) {
          await binding.convertFlutterSurfaceToImage();
          surfaceConverted = true;
        }
        await tester.pump();
        await binding.takeScreenshot(name);
      }

      Future<void> login(String username, String password) async {
        await route('/login');
        await until(
          () => find.byType(TextFormField).evaluate().length == 2,
          'login form',
        );
        await tester.enterText(find.byType(TextFormField).at(0), username);
        await tester.enterText(find.byType(TextFormField).at(1), password);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await visible(find.byKey(const Key('login-button')));
        await tester.tap(find.byKey(const Key('login-button')));
        await until(
          () => container.read(sessionControllerProvider).user != null,
          'authenticated session',
        );
      }

      Future<void> logout() async {
        await route('/student/more');
        await tapText('Cerrar sesión');
        await until(
          () => container.read(sessionControllerProvider).user == null,
          'logout',
        );
      }

      await until(
        () => !container.read(sessionControllerProvider).isLoading,
        'session restored',
      );
      await container.read(sessionControllerProvider.notifier).signOut();
      await login(
        const String.fromEnvironment('LIC_MANAGED_USER'),
        const String.fromEnvironment('LIC_TEMP_PASSWORD'),
      );
      await until(
        () => find.text('Protege tu cuenta').evaluate().isNotEmpty,
        'forced password change',
      );
      expect(
        container.read(sessionControllerProvider).user!.mustChangePassword,
        isTrue,
      );
      await tester.enterText(
        find.byType(TextFormField).at(0),
        const String.fromEnvironment('LIC_NEW_PASSWORD'),
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        const String.fromEnvironment('LIC_NEW_PASSWORD'),
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tapText('Actualizar y continuar');
      await until(
        () =>
            container
                .read(sessionControllerProvider)
                .user
                ?.mustChangePassword ==
            false,
        'new session after password change',
      );
      expect(
        container
            .read(sessionControllerProvider)
            .user!
            .institutionalAccess!
            .canStartPractice,
        isTrue,
      );
      await route('/student/home');
      await visible(find.text('Licencia activa'));
      await screenshot('lic-android-active');
      await tapText('Consultar retorno a modalidad personal');
      await visible(
        find.textContaining('Esta cuenta fue creada por el colegio.'),
      );
      expect(find.text('Volver a modalidad personal'), findsNothing);
      await screenshot('lic-android-managed-no-conversion');
      await tester.pageBack();
      await route('/student/practice/priorities');
      await visible(find.text('Prioridad Android LIC'));
      await screenshot('lic-android-priority');
      await route('/student/more');
      await tapText('Privacidad de mi cuenta');
      await visible(find.byType(TextField));
      await tester.enterText(
        find.byType(TextField),
        'Solicitud propia de validación Android local.',
      );
      await tapText('Solicitar revisión');
      await tapText('Enviar solicitud');
      await visible(find.text('Pendiente de revisión'));
      await screenshot('lic-android-privacy-pending');
      expect(
        container.read(sessionControllerProvider).user!.id,
        const String.fromEnvironment('LIC_MANAGED_ID'),
      );
      await tester.pageBack();
      await logout();
      await login(
        const String.fromEnvironment('LIC_SUSPENDED_USER'),
        const String.fromEnvironment('LIC_PASSWORD'),
      );
      await route('/student/home');
      await visible(find.text('Licencia suspendida'));
      expect(
        container
            .read(sessionControllerProvider)
            .user!
            .institutionalAccess!
            .canStartPractice,
        isFalse,
      );
      await screenshot('lic-android-suspended');
      await logout();
      await login(
        const String.fromEnvironment('LIC_PERSONAL_USER'),
        const String.fromEnvironment('LIC_PASSWORD'),
      );
      await route('/student/home');
      await visible(find.text('Licencia vencida'));
      expect(
        container
            .read(sessionControllerProvider)
            .user!
            .institutionalAccess!
            .state,
        InstitutionalLicenseState.expired,
      );
      await screenshot('lic-android-expired');
      await tapText('Consultar retorno a modalidad personal');
      await tapText('Volver a modalidad personal');
      await tapText('Confirmar salida');
      await until(
        () =>
            container.read(sessionControllerProvider).user?.institutionId ==
            null,
        'personal return profile',
      );
      expect(
        container.read(sessionControllerProvider).user!.id,
        const String.fromEnvironment('LIC_PERSONAL_ID'),
      );
      await screenshot('lic-android-personal-return');
      await tester.pageBack();
      await logout();
      await login(
        const String.fromEnvironment('LIC_OWNER_USER'),
        const String.fromEnvironment('LIC_PASSWORD'),
      );
      await visible(find.text('Espacio del profesor'));
      await screenshot('lic-android-teacher');
      await route('/teacher/groups');
      await visible(find.text('11 Android LIC'));
      await screenshot('lic-android-teacher-groups');
      await route(
        '/teacher/groups/${const String.fromEnvironment('LIC_GROUP')}/priorities',
      );
      await visible(find.text('Prioridad Android LIC'));
      await screenshot('lic-android-teacher-priority');
      expect(tester.takeException(), isNull);
      debugPrint('LIC_ANDROID_REAL_API_COMPLETE');
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}
