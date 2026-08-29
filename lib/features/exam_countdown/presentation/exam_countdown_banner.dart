import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/preferences/app_preferences_controller.dart';
import '../../academic/presentation/academic_home_controller.dart';
import '../domain/exam_countdown_models.dart';
import 'exam_countdown_clock.dart';

class ExamCountdownBanner extends ConsumerWidget {
  const ExamCountdownBanner({this.includeBottomSafeArea = false, super.key});

  final bool includeBottomSafeArea;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      bottom: includeBottomSafeArea,
      child: Material(
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
                  onMinimize: preferences == null
                      ? null
                      : () => _setMinimized(context, ref, true),
                ),
        ),
      ),
    );
  }

  Future<void> _setMinimized(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    try {
      await ref
          .read(appPreferencesControllerProvider.notifier)
          .setExamCountdownMinimized(value);
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos guardar esta preferencia.')),
      );
    }
  }
}

class _ExpandedCountdown extends StatelessWidget {
  const _ExpandedCountdown({required this.countdown, required this.onMinimize});

  final ExamCountdown countdown;
  final VoidCallback? onMinimize;

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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
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
