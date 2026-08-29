const pomodoroFocusDuration = Duration(minutes: 25);

enum PomodoroStatus { idle, running, paused, completed }

class PomodoroState {
  const PomodoroState({
    required this.status,
    required this.remaining,
    this.deadline,
  });

  const PomodoroState.initial()
    : status = PomodoroStatus.idle,
      remaining = pomodoroFocusDuration,
      deadline = null;

  final PomodoroStatus status;
  final Duration remaining;
  final DateTime? deadline;

  bool get isRunning => status == PomodoroStatus.running;

  double get progress {
    final total = pomodoroFocusDuration.inMilliseconds;
    if (total == 0) return 0;
    return (1 - remaining.inMilliseconds / total).clamp(0, 1);
  }
}

String formatPomodoroTime(Duration duration) {
  final totalSeconds = duration.inSeconds.clamp(
    0,
    pomodoroFocusDuration.inSeconds,
  );
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
