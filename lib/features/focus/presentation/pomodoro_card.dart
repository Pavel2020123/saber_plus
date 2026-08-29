import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pomodoro_models.dart';
import 'pomodoro_controller.dart';

class PomodoroCard extends ConsumerWidget {
  const PomodoroCard({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroControllerProvider);
    final controller = ref.read(pomodoroControllerProvider.notifier);
    final title = switch (state.status) {
      PomodoroStatus.idle => 'Pomodoro de enfoque',
      PomodoroStatus.running => 'Enfoque en curso',
      PomodoroStatus.paused => 'Enfoque pausado',
      PomodoroStatus.completed => 'Bloque completado',
    };
    final toggleTooltip = switch (state.status) {
      PomodoroStatus.idle => 'Iniciar Pomodoro',
      PomodoroStatus.running => 'Pausar Pomodoro',
      PomodoroStatus.paused => 'Continuar Pomodoro',
      PomodoroStatus.completed => 'Iniciar otro Pomodoro',
    };
    return Card(
      key: const Key('pomodoro-card'),
      color: Theme.of(
        context,
      ).colorScheme.tertiaryContainer.withValues(alpha: 0.42),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          compact ? 10 : 14,
          10,
          compact ? 8 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      if (!compact) const Text('25 minutos sin interrupciones'),
                    ],
                  ),
                ),
                Text(
                  formatPomodoroTime(state.remaining),
                  key: const Key('pomodoro-time'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  key: const Key('pomodoro-toggle'),
                  tooltip: toggleTooltip,
                  onPressed: controller.toggle,
                  icon: Icon(
                    state.isRunning
                        ? Icons.pause_rounded
                        : state.status == PomodoroStatus.completed
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                if (state.status != PomodoroStatus.idle)
                  IconButton(
                    key: const Key('pomodoro-reset'),
                    tooltip: 'Reiniciar Pomodoro',
                    onPressed: controller.reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: state.progress,
              minHeight: 5,
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
      ),
    );
  }
}
