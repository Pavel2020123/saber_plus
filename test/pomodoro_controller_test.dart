import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/focus/domain/pomodoro_models.dart';
import 'package:saber_plus/features/focus/presentation/pomodoro_controller.dart';

void main() {
  test('inicia, pausa, continúa y completa un bloque de 25 minutos', () {
    var now = DateTime.utc(2026, 8, 28, 10);
    final container = ProviderContainer(
      overrides: [
        pomodoroOwnerProvider.overrideWithValue('student-1'),
        pomodoroNowProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(pomodoroControllerProvider.notifier);

    controller.start();
    expect(container.read(pomodoroControllerProvider).isRunning, isTrue);
    expect(
      container.read(pomodoroControllerProvider).remaining,
      pomodoroFocusDuration,
    );

    now = now.add(const Duration(minutes: 5, seconds: 30));
    controller.synchronize();
    expect(
      container.read(pomodoroControllerProvider).remaining,
      const Duration(minutes: 19, seconds: 30),
    );

    controller.pause();
    expect(
      container.read(pomodoroControllerProvider).status,
      PomodoroStatus.paused,
    );
    now = now.add(const Duration(minutes: 2));
    controller.synchronize();
    expect(
      container.read(pomodoroControllerProvider).remaining,
      const Duration(minutes: 19, seconds: 30),
    );

    controller.start();
    now = now.add(const Duration(minutes: 19, seconds: 30));
    controller.synchronize();
    expect(
      container.read(pomodoroControllerProvider).status,
      PomodoroStatus.completed,
    );
    expect(container.read(pomodoroControllerProvider).remaining, Duration.zero);

    controller.reset();
    expect(
      container.read(pomodoroControllerProvider),
      isA<PomodoroState>()
          .having((state) => state.status, 'status', PomodoroStatus.idle)
          .having(
            (state) => state.remaining,
            'remaining',
            pomodoroFocusDuration,
          ),
    );
  });

  test('no inicia sin una cuenta y formatea el reloj', () {
    final container = ProviderContainer(
      overrides: [pomodoroOwnerProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);

    container.read(pomodoroControllerProvider.notifier).start();

    expect(
      container.read(pomodoroControllerProvider).status,
      PomodoroStatus.idle,
    );
    expect(formatPomodoroTime(pomodoroFocusDuration), '25:00');
    expect(formatPomodoroTime(const Duration(seconds: 9)), '00:09');
  });
}
