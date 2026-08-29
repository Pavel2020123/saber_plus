import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_controller.dart';
import '../domain/pomodoro_models.dart';

typedef PomodoroNow = DateTime Function();

final pomodoroNowProvider = Provider<PomodoroNow>((ref) => DateTime.now);

final pomodoroOwnerProvider = Provider<String?>((ref) {
  return ref.watch(
    sessionControllerProvider.select((session) => session.user?.id),
  );
});

class PomodoroController extends Notifier<PomodoroState> {
  Timer? _ticker;
  String? _ownerId;

  @override
  PomodoroState build() {
    final ownerId = ref.watch(pomodoroOwnerProvider);
    if (_ownerId != ownerId) _ticker?.cancel();
    _ownerId = ownerId;
    ref.onDispose(() => _ticker?.cancel());
    return const PomodoroState.initial();
  }

  void toggle() => state.isRunning ? pause() : start();

  void start() {
    if (_ownerId == null || state.isRunning) return;
    final remaining = state.status == PomodoroStatus.completed
        ? pomodoroFocusDuration
        : state.remaining;
    final deadline = ref.read(pomodoroNowProvider)().add(remaining);
    state = PomodoroState(
      status: PomodoroStatus.running,
      remaining: remaining,
      deadline: deadline,
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => synchronize());
  }

  void pause() {
    if (!state.isRunning) return;
    synchronize();
    if (!state.isRunning) return;
    _ticker?.cancel();
    state = PomodoroState(
      status: PomodoroStatus.paused,
      remaining: state.remaining,
    );
  }

  void reset() {
    _ticker?.cancel();
    state = const PomodoroState.initial();
  }

  void synchronize() {
    final deadline = state.deadline;
    if (!state.isRunning || deadline == null) return;
    final milliseconds = deadline
        .difference(ref.read(pomodoroNowProvider)())
        .inMilliseconds;
    if (milliseconds <= 0) {
      _ticker?.cancel();
      state = const PomodoroState(
        status: PomodoroStatus.completed,
        remaining: Duration.zero,
      );
      return;
    }
    final seconds = (milliseconds / 1000).ceil();
    final remaining = Duration(seconds: seconds);
    if (remaining == state.remaining) return;
    state = PomodoroState(
      status: PomodoroStatus.running,
      remaining: remaining,
      deadline: deadline,
    );
  }
}

final pomodoroControllerProvider =
    NotifierProvider<PomodoroController, PomodoroState>(PomodoroController.new);
