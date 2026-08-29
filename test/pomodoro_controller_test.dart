import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/focus/domain/pomodoro_models.dart';
import 'package:saber_plus/features/focus/presentation/pomodoro_controller.dart';
import 'package:saber_plus/features/study_time/domain/study_time_models.dart';
import 'package:saber_plus/features/study_time/domain/study_time_repository.dart';
import 'package:saber_plus/features/study_time/presentation/study_time_providers.dart';

void main() {
  test('inicia, pausa, continúa y completa un bloque de 25 minutos', () async {
    var now = DateTime.utc(2026, 8, 28, 10);
    final studyTime = _MemoryStudyTimeRepository();
    final container = ProviderContainer(
      overrides: [
        pomodoroOwnerProvider.overrideWithValue('student-1'),
        pomodoroNowProvider.overrideWithValue(() => now),
        studyTimeRepositoryProvider.overrideWithValue(studyTime),
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
    await Future<void>.delayed(Duration.zero);
    expect(studyTime.records, hasLength(1));
    expect(studyTime.records.single.source, StudyTimeSource.pomodoro);
    expect(studyTime.records.single.durationSeconds, 25 * 60);

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

class _MemoryStudyTimeRepository implements StudyTimeRepository {
  final records = <StudyTimeRecord>[];

  @override
  Future<void> record(StudyTimeRecord entry) async => records.add(entry);

  @override
  Stream<List<StudyTimeRecord>> watchAll(String userId) =>
      Stream.value(records.where((entry) => entry.userId == userId).toList());
}
