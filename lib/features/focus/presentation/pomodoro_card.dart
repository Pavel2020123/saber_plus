import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/pomodoro_models.dart';
import 'pomodoro_controller.dart';

class PomodoroCard extends ConsumerStatefulWidget {
  const PomodoroCard({super.key, this.compact = false});
  final bool compact;
  @override
  ConsumerState<PomodoroCard> createState() => _PomodoroCardState();
}

class _PomodoroCardState extends ConsumerState<PomodoroCard> {
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = ref.read(pomodoroControllerProvider).isRunning;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pomodoroControllerProvider);
    final controller = ref.read(pomodoroControllerProvider.notifier);
    ref.listen(pomodoroOwnerProvider, (previous, next) {
      if (previous != next) setState(() => _collapsed = false);
    });
    ref.listen(pomodoroControllerProvider.select((s) => s.status), (_, next) {
      if (next == PomodoroStatus.completed || next == PomodoroStatus.idle) {
        setState(() => _collapsed = false);
      }
    });
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 420);
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
    final colors = Theme.of(context).colorScheme;
    final clock = IconButton(
      key: const Key('pomodoro-expand'),
      tooltip: _collapsed
          ? 'Abrir Pomodoro: ${formatPomodoroTime(state.remaining)} restantes. $title'
          : 'Recoger Pomodoro',
      onPressed: () => setState(() => _collapsed = !_collapsed),
      icon: _ProgressClock(state: state),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
    );
    final presentation = AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [
          for (final child in previous)
            IgnorePointer(child: ExcludeSemantics(child: child)),
          ?current,
        ],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-.05, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: _collapsed
          ? Material(
              key: const Key('pomodoro-collapsed'),
              color: colors.tertiaryContainer.withValues(alpha: .42),
              borderRadius: BorderRadius.circular(24),
              child: const SizedBox.square(dimension: 80),
            )
          : Card(
              key: const Key('pomodoro-expanded'),
              margin: EdgeInsets.zero,
              color: colors.tertiaryContainer.withValues(alpha: .42),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  88,
                  widget.compact ? 12 : 16,
                  14,
                  14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    if (!widget.compact)
                      const Text('25 minutos sin interrupciones'),
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          formatPomodoroTime(state.remaining),
                          key: const Key('pomodoro-time'),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                        IconButton.filledTonal(
                          key: const Key('pomodoro-toggle'),
                          tooltip: toggleTooltip,
                          onPressed: () {
                            controller.toggle();
                            if (ref
                                .read(pomodoroControllerProvider)
                                .isRunning) {
                              setState(() => _collapsed = true);
                            }
                          },
                          icon: Icon(
                            state.isRunning
                                ? LucideIcons.pause
                                : LucideIcons.play,
                          ),
                        ),
                        if (state.status != PomodoroStatus.idle)
                          IconButton(
                            key: const Key('pomodoro-reset'),
                            tooltip: 'Reiniciar Pomodoro',
                            onPressed: controller.reset,
                            icon: const Icon(LucideIcons.rotateCcw),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
    return Align(
      key: const Key('pomodoro-card'),
      alignment: Alignment.topLeft,
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          duration == Duration.zero
              ? presentation
              : AnimatedSize(
                  duration: duration,
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topLeft,
                  child: presentation,
                ),
          Positioned(left: 8, top: 8, child: clock),
        ],
      ),
    );
  }
}

/// Ring and marker follow elapsed time, not an unrelated looping spinner.
class _ProgressClock extends StatelessWidget {
  const _ProgressClock({required this.state});
  final PomodoroState state;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final duration = !state.isRunning || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 800);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: state.progress, end: state.progress),
      duration: duration,
      builder: (_, progress, _) => SizedBox.square(
        dimension: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CircularProgressIndicator(
                key: const Key('pomodoro-clock-progress'),
                value: progress,
                strokeWidth: 2.5,
                color: colors.primary,
                backgroundColor: colors.primary.withValues(alpha: .14),
              ),
            ),
            Icon(
              state.status == PomodoroStatus.completed
                  ? LucideIcons.check
                  : LucideIcons.timer,
              size: 23,
              color: colors.primary,
            ),
            Positioned.fill(
              child: Transform.rotate(
                angle: progress * 2 * math.pi,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox.square(
                    dimension: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
