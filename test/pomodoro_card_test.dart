import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/focus/domain/pomodoro_models.dart';
import 'package:saber_plus/features/focus/presentation/pomodoro_card.dart';
import 'package:saber_plus/features/focus/presentation/pomodoro_controller.dart';

void main() {
  testWidgets(
    'start collapses; clock toggles panel without pausing; ring follows actual time',
    (tester) async {
      var now = DateTime.utc(2026, 10, 27);
      final container = ProviderContainer(
        overrides: [
          pomodoroOwnerProvider.overrideWithValue('student'),
          pomodoroNowProvider.overrideWithValue(() => now),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: PomodoroCard())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('25:00'), findsOneWidget);
      final clockPosition = tester.getTopLeft(
        find.byKey(const Key('pomodoro-expand')),
      );
      await tester.tap(find.byKey(const Key('pomodoro-toggle')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(find.byKey(const Key('pomodoro-expand')), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('pomodoro-expand'))),
        clockPosition,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const Key('pomodoro-expand'))),
        clockPosition,
      );
      expect(find.byKey(const Key('pomodoro-collapsed')), findsOneWidget);
      expect(find.text('25 minutos sin interrupciones'), findsNothing);
      now = now.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 900));
      final ring = tester.widget<CircularProgressIndicator>(
        find.byKey(const Key('pomodoro-clock-progress')),
      );
      expect(ring.value, closeTo(.2, .001));
      await tester.tap(find.byKey(const Key('pomodoro-expand')));
      await tester.pumpAndSettle();
      expect(find.text('20:00'), findsOneWidget);
      expect(
        container.read(pomodoroControllerProvider).status,
        PomodoroStatus.running,
      );
      await tester.tap(find.byKey(const Key('pomodoro-toggle')));
      await tester.pumpAndSettle();
      expect(
        container.read(pomodoroControllerProvider).status,
        PomodoroStatus.paused,
      );
      await tester.tap(find.byKey(const Key('pomodoro-expand')));
      await tester.pumpAndSettle();
      now = now.add(const Duration(minutes: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(
        container.read(pomodoroControllerProvider).remaining,
        const Duration(minutes: 20),
      );
      await tester.tap(find.byKey(const Key('pomodoro-expand')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('pomodoro-reset')));
      await tester.pumpAndSettle();
      expect(find.text('25:00'), findsOneWidget);
      expect(
        container.read(pomodoroControllerProvider).status,
        PomodoroStatus.idle,
      );
    },
  );

  testWidgets('320px with text 200% and reduced motion has usable controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pomodoroOwnerProvider.overrideWithValue('student')],
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              disableAnimations: true,
              textScaler: TextScaler.linear(2),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(child: PomodoroCard()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final clockPosition = tester.getTopLeft(
      find.byKey(const Key('pomodoro-expand')),
    );
    await tester.tap(find.byKey(const Key('pomodoro-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pomodoro-collapsed')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('pomodoro-expand')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(
      tester.getTopLeft(find.byKey(const Key('pomodoro-expand'))),
      clockPosition,
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pausar Pomodoro'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
