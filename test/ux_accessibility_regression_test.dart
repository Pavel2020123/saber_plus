import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/theme.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/academic/presentation/academic_home_controller.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/auth_form_scaffold.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/dashboard/presentation/student_dashboard_page.dart';
import 'package:saber_plus/features/resume/presentation/learning_resume_providers.dart';

class _Session extends SessionController {
  @override
  SessionState build() => const SessionState.authenticated(
    UserSession(
      id: 'ux-test',
      firstName: 'María Fernanda',
      role: AppRole.student,
      isDemo: true,
    ),
  );
}

class _Home extends AcademicHomeController {
  @override
  Future<AcademicHomeData> build() async => AcademicHomeData.demo;
}

Widget _dashboard(ThemeData theme, double scale) => ProviderScope(
  overrides: [
    sessionControllerProvider.overrideWith(_Session.new),
    academicHomeControllerProvider.overrideWith(_Home.new),
    learningResumeProvider.overrideWith((ref) => Stream.value(null)),
  ],
  child: MaterialApp(
    theme: theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const StudentDashboardPage(),
  ),
);

void main() {
  for (final dark in [false, true]) {
    testWidgets('contraste de la actividad principal, modo oscuro: $dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        _dashboard(dark ? SaberPlusTheme.dark : SaberPlusTheme.light, 1),
      );
      await tester.pumpAndSettle();
      final card = find.byKey(const Key('home-primary-action-card'));
      final decoration =
          tester.widget<Container>(card).decoration! as BoxDecoration;
      final background = decoration.color!;
      final labels = find.descendant(of: card, matching: find.byType(Text));
      for (final label in tester.widgetList<Text>(labels)) {
        if (label.style?.color case final foreground?) {
          final a = foreground.computeLuminance();
          final b = background.computeLuminance();
          final ratio =
              (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
          expect(ratio, greaterThanOrEqualTo(4.5), reason: label.data);
        }
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('contraseña no ofrece sugerencias al alternar visibilidad', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PasswordField(controller: controller)),
      ),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).autocorrect,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).enableSuggestions,
      isFalse,
    );
    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isFalse);
    expect(field.autocorrect, isFalse);
    expect(field.enableSuggestions, isFalse);
  });
  for (final dark in [false, true]) {
    testWidgets('inicio con texto al 200 % a 320 px, modo oscuro: $dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _dashboard(dark ? SaberPlusTheme.dark : SaberPlusTheme.light, 2),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('SIGUIENTE ACTIVIDAD'), findsOneWidget);
      // Check the lazily laid out content below the first viewport, too.
      for (var scroll = 0; scroll < 5; scroll++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets(
    'error de acceso anuncia el mensaje a tecnologías de asistencia',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SaberPlusTheme.light,
          home: const Scaffold(
            body: AuthErrorBanner(message: 'Revisa el correo'),
          ),
        ),
      );
      final semantics = tester.ensureSemantics();
      try {
        expect(
          tester.getSemantics(find.byKey(const Key('auth-error-banner'))),
          matchesSemantics(label: 'Revisa el correo', isLiveRegion: true),
        );
      } finally {
        semantics.dispose();
      }
    },
  );
}
