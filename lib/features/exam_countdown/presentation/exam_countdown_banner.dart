import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/app_preferences_controller.dart';
import '../../academic/presentation/academic_home_controller.dart';
import '../domain/exam_countdown_models.dart';
import 'exam_countdown_clock.dart';

class ExamCountdownBanner extends ConsumerStatefulWidget {
  const ExamCountdownBanner({this.includeBottomSafeArea = false, super.key});

  final bool includeBottomSafeArea;

  @override
  ConsumerState<ExamCountdownBanner> createState() =>
      _ExamCountdownBannerState();
}

class _ExamCountdownBannerState extends ConsumerState<ExamCountdownBanner> {
  bool _docked = false;

  @override
  Widget build(BuildContext context) {
    final exam = ref
        .watch(academicHomeControllerProvider)
        .valueOrNull
        ?.activeExam;
    if (exam == null) return const SizedBox.shrink();
    final now =
        ref.watch(examCountdownClockProvider).valueOrNull ?? DateTime.now();
    final countdown = ExamCountdown.calculate(exam: exam, now: now);
    final preferences = ref.watch(appPreferencesControllerProvider).valueOrNull;
    final minimized = preferences?.examCountdownMinimized ?? false;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return SafeArea(
      top: false,
      bottom: widget.includeBottomSafeArea,
      child: AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: _docked
            ? Align(
                key: const Key('docked-exam-countdown'),
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: true,
                  label: 'Restaurar calendario ICFES',
                  hint: 'Toca dos veces para devolver la barra abajo',
                  onTap: () => setState(() => _docked = false),
                  child: Tooltip(
                    message: 'Doble toque para restaurar el calendario ICFES',
                    child: Material(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16),
                      ),
                      child: InkWell(
                        key: const Key('restore-exam-countdown'),
                        excludeFromSemantics: true,
                        onDoubleTap: () => setState(() => _docked = false),
                        child: const SizedBox(
                          width: 56,
                          height: 48,
                          child: Icon(Icons.event_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : Material(
                key: const Key('exam-countdown-banner'),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: AnimatedSize(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: minimized
                      ? _MinimizedCountdown(
                          countdown: countdown,
                          onExpand: preferences == null
                              ? null
                              : () => _setMinimized(context, ref, false),
                        )
                      : _ExpandedCountdown(
                          countdown: countdown,
                          onClose: preferences == null
                              ? null
                              : () async {
                                  final saved = await _setMinimized(
                                    context,
                                    ref,
                                    true,
                                  );
                                  if (mounted && saved) {
                                    setState(() => _docked = true);
                                  }
                                },
                          onMinimize: preferences == null
                              ? null
                              : () => _setMinimized(context, ref, true),
                        ),
                ),
              ),
      ),
    );
  }

  Future<bool> _setMinimized(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      await ref
          .read(appPreferencesControllerProvider.notifier)
          .setExamCountdownMinimized(value);
      return true;
    } on Object {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar esta preferencia.')),
      );
      return false;
    }
  }
}

class _ExpandedCountdown extends StatelessWidget {
  const _ExpandedCountdown({
    required this.countdown,
    required this.onMinimize,
    required this.onClose,
  });

  final ExamCountdown countdown;
  final VoidCallback? onMinimize;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '${countdown.headline}. ${countdown.detail}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 9, 8, 9),
        child: Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              child: const Icon(Icons.event_available_rounded, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    countdown.headline,
                    key: const Key('exam-countdown-headline'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    countdown.detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consulta tu citación para conocer el horario.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const Key('close-exam-countdown'),
              tooltip: 'Recoger calendario a la izquierda',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
            IconButton(
              key: const Key('minimize-exam-countdown'),
              tooltip: 'Minimizar contador del examen',
              onPressed: onMinimize,
              icon: const Icon(Icons.expand_more_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimizedCountdown extends StatelessWidget {
  const _MinimizedCountdown({required this.countdown, required this.onExpand});

  final ExamCountdown countdown;
  final VoidCallback? onExpand;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('expand-exam-countdown'),
    onTap: onExpand,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_outlined, size: 18),
          const SizedBox(width: 8),
          Text(
            countdown.compactLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(width: 4),
          const Icon(Icons.expand_less_rounded, size: 19),
        ],
      ),
    ),
  );
}
