import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide DiagnosticLevel;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:saber_plus/app/theme.dart';
import 'package:saber_plus/features/academic/data/remote_academic_repository.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/academic/domain/academic_repository.dart';
import 'package:saber_plus/features/academic/presentation/academic_home_controller.dart';
import 'package:saber_plus/features/auth/domain/session.dart';
import 'package:saber_plus/features/auth/presentation/session_controller.dart';
import 'package:saber_plus/features/dashboard/presentation/student_dashboard_page.dart';
import 'package:saber_plus/features/resume/presentation/learning_resume_providers.dart';

class _Session extends SessionController {
  _Session({this.demo = true});
  final bool demo;
  @override
  SessionState build() => SessionState.authenticated(
    UserSession(
      id: 'presentation-student',
      firstName: 'Santiago',
      role: AppRole.student,
      isDemo: demo,
      xpTotal: 1240,
    ),
  );
}

class _Home extends AcademicHomeController {
  _Home(this.data);
  final AcademicHomeData data;
  @override
  Future<AcademicHomeData> build() async => data;
}

class _NetworkCounter implements AcademicRepository {
  int homeCalls = 0;
  @override
  Future<AcademicHomeData> loadHome() async {
    homeCalls++;
    return AcademicHomeData.demo;
  }

  @override
  Future<DiagnosticSummary> startDiagnostic() async =>
      throw StateError('Not part of this test');
  @override
  Future<DiagnosticSummary> finishDiagnostic(
    List<DiagnosticAnswer> answers,
  ) async => throw StateError('Not part of this test');
  @override
  Future<List<WeakTopic>> loadWeakTopics() async => [];
}

Widget _page(
  AcademicHomeData data, {
  bool demo = true,
  bool dark = false,
  double scale = 1,
  GoRouter? router,
}) => ProviderScope(
  overrides: [
    sessionControllerProvider.overrideWith(() => _Session(demo: demo)),
    academicHomeControllerProvider.overrideWith(() => _Home(data)),
    learningResumeProvider.overrideWith((ref) => Stream.value(null)),
  ],
  child: MaterialApp.router(
    theme: _previewTheme(dark),
    routerConfig:
        router ??
        GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, _) => const StudentDashboardPage()),
          ],
        ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: RepaintBoundary(
        key: const Key('dashboard-preview'),
        child: child!,
      ),
    ),
  ),
);

ThemeData _previewTheme(bool dark) {
  final base = dark ? SaberPlusTheme.dark : SaberPlusTheme.light;
  if (!const bool.fromEnvironment('RENDER_DASHBOARD_PREVIEW')) return base;
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'PresentationPreview'),
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamily: 'PresentationPreview',
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: 'PresentationPreview',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('example exam year matches the displayed example date', () {
    final exam = AcademicHomeData.demo.activeExam!;
    expect(exam.year, exam.examDate.year);
  });
  for (final status in DiagnosticStatus.values) {
    testWidgets('primary activity keeps diagnostic state: $status', (
      tester,
    ) async {
      await tester.pumpWidget(
        _page(
          AcademicHomeData.demo.copyWith(
            diagnostic: DiagnosticSummary(status: status),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final expected = switch (status) {
        DiagnosticStatus.notStarted => 'Descubre tu punto de partida',
        DiagnosticStatus.inProgress => 'Continúa tu diagnóstico',
        DiagnosticStatus.completed => 'Refuerzo de matemáticas',
      };
      expect(find.text(expected), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final demo in [false, true]) {
    testWidgets('shows Sabi, actual XP and accurate demo label: $demo', (
      tester,
    ) async {
      await tester.pumpWidget(_page(AcademicHomeData.demo, demo: demo));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-sabi')), findsOneWidget);
      final sabi = tester.widget<Image>(find.byKey(const Key('home-sabi')));
      final provider = sabi.image is ResizeImage
          ? (sabi.image as ResizeImage).imageProvider
          : sabi.image;
      expect(
        (provider as AssetImage).assetName,
        'assets/images/Sabi_Inicio_Refuerzo.png',
      );
      expect(sabi.fit, BoxFit.contain);
      expect(
        find.byKey(const Key('home-demo-label')),
        demo ? findsOneWidget : findsNothing,
      );
      expect(find.text('1.240 XP'), findsOneWidget);
      expect(find.byTooltip('Notificaciones'), findsNothing);
      expect(find.byTooltip('Preferencias'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 360.0, 390.0, 430.0, 768.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('home B has no overflow at $width px and text $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(_page(AcademicHomeData.demo, scale: scale));
        await tester.pumpAndSettle();
        for (var index = 0; index < 5; index++) {
          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -250),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.textContaining('3 de 5 sesiones'), findsOneWidget);
        expect(find.text('Sesiones de esta semana'), findsNothing);
      });
    }
  }

  for (final target in [
    'study',
    'practice',
    'preferences',
    'gamification',
    'diagnostic',
  ]) {
    testWidgets('home access keeps its destination: $target', (tester) async {
      final destination = switch (target) {
        'study' => '/student/study',
        'practice' => '/student/practice',
        'preferences' => '/student/more/preferences',
        'gamification' => '/student/more/gamification',
        _ => '/student/diagnostic',
      };
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const StudentDashboardPage()),
          GoRoute(
            path: destination,
            builder: (_, _) => Scaffold(body: Text('Destination $target')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final data = AcademicHomeData.demo.copyWith(
        diagnostic: const DiagnosticSummary(
          status: DiagnosticStatus.notStarted,
        ),
      );
      await tester.pumpWidget(_page(data, router: router));
      await tester.pumpAndSettle();
      final control = switch (target) {
        'study' => find.byKey(const Key('home-study-shortcut')),
        'practice' => find.byKey(const Key('home-practice-shortcut')),
        'preferences' => find.byKey(const Key('home-preferences')),
        'gamification' => find.byKey(const Key('open-gamification-from-home')),
        _ => find.widgetWithText(FilledButton, 'Ver diagnóstico'),
      };
      await tester.ensureVisible(control);
      await tester.tap(control);
      await tester.pumpAndSettle();
      expect(find.text('Destination $target'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final demo in [false, true]) {
    test(
      'refresh preserves demo state without network; real account reloads: $demo',
      () async {
        final repository = _NetworkCounter();
        final container = ProviderContainer(
          overrides: [
            sessionControllerProvider.overrideWith(() => _Session(demo: demo)),
            academicRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);
        final subscription = container.listen(
          academicHomeControllerProvider,
          (_, _) {},
        );
        addTearDown(subscription.close);
        final before = await container.read(
          academicHomeControllerProvider.future,
        );
        await container.read(academicHomeControllerProvider.notifier).reload();
        expect(repository.homeCalls, demo ? 0 : 2);
        if (demo) {
          expect(
            container.read(academicHomeControllerProvider).valueOrNull,
            same(before),
          );
        }
      },
    );
  }

  for (final dark in [false, true]) {
    testWidgets('dashboard preview and complete scrolling, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (const bool.fromEnvironment('RENDER_DASHBOARD_PREVIEW')) {
        await tester.runAsync(() async {
          final bytes = await File(
            'C:/flutter_sdk/bin/cache/artifacts/material_fonts/roboto-regular.ttf',
          ).readAsBytes();
          final loader = FontLoader('PresentationPreview')
            ..addFont(Future.value(ByteData.sublistView(bytes)));
          for (final weight in ['medium', 'bold']) {
            final face = await File(
              'C:/flutter_sdk/bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
            ).readAsBytes();
            loader.addFont(Future.value(ByteData.sublistView(face)));
          }
          await loader.load();
          final icons = await File(
            'C:/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytes();
          await (FontLoader(
            'MaterialIcons',
          )..addFont(Future.value(ByteData.sublistView(icons)))).load();
          await (FontLoader('packages/lucide_icons_flutter/Lucide')..addFont(
                rootBundle.load(
                  'packages/lucide_icons_flutter/assets/lucide.ttf',
                ),
              ))
              .load();
        });
      }
      await tester.pumpWidget(_page(AcademicHomeData.demo, dark: dark));
      await tester.pumpAndSettle();
      if (const bool.fromEnvironment('RENDER_DASHBOARD_PREVIEW')) {
        final imageWidget = tester.widget<Image>(
          find.byKey(const Key('home-sabi')),
        );
        await tester.runAsync(
          () => precacheImage(
            imageWidget.image,
            tester.element(find.byKey(const Key('home-sabi'))),
          ),
        );
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('dashboard-preview')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/dashboard-preview').create(recursive: true);
          await File(
            'build/dashboard-preview/${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      for (var n = 0; n < 5; n++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
