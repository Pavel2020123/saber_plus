import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/gamification_models.dart';
import 'gamification_providers.dart';

class GamificationPage extends ConsumerWidget {
  const GamificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(gamificationSummaryProvider);
    final xp = ref.watch(sessionControllerProvider).user?.xpTotal ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logros y actividad'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _GamificationError(
          message: _messageFor(error),
          onRetry: () => ref.invalidate(gamificationSummaryProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: _GamificationContent(summary: data, xp: xp),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait<void>([
      ref.read(sessionControllerProvider.notifier).refreshProfile(),
      ref.refresh(gamificationSummaryProvider.future).then((_) {}),
    ]);
  }
}

class _GamificationContent extends StatelessWidget {
  const _GamificationContent({required this.summary, required this.xp});

  final GamificationSummary summary;
  final int xp;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('gamification-list'),
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
    children: [
      _StatusCard(streak: summary.streak, xp: xp),
      const SizedBox(height: 24),
      Text('Tu actividad', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(
        'Cada respuesta, simulacro o tema estudiado cuenta.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 12),
      _WeeklyActivityCard(summary: summary),
      const SizedBox(height: 24),
      _AchievementHeader(totals: summary.totals),
      const SizedBox(height: 12),
      if (summary.achievements.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text('Todavía no hay logros configurados.'),
          ),
        )
      else
        ...summary.achievements.map(
          (achievement) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AchievementCard(achievement: achievement),
          ),
        ),
    ],
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.streak, required this.xp});

  final StudyStreak streak;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('gamification-status-card'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8A00), Color(0xFFE34D2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  streak.current == 1
                      ? '1 día de racha'
                      : '${streak.current} días de racha',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _streakMessage(streak),
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatusMetric(
                  label: 'XP total',
                  value: _formatInteger(xp),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatusMetric(
                  label: 'Mejor racha',
                  value: '${streak.best} días',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _streakMessage(StudyStreak value) {
    if (value.activeToday) return 'Tu actividad de hoy ya protegió la racha.';
    if (value.current > 0) return 'Haz una actividad hoy para mantenerla viva.';
    if (value.lastActivity != null) {
      return 'Empieza una nueva racha con una actividad hoy.';
    }
    return 'Tu primera actividad iniciará la racha.';
  }
}

class _StatusMetric extends StatelessWidget {
  const _StatusMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    ),
  );
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({required this.summary});

  final GamificationSummary summary;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(today.year, today.month, today.day - (6 - index)),
    );
    final counts = days.map(summary.activityOn).toList(growable: false);
    final maximum = math.max(1, counts.fold(0, math.max));
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
        child: SizedBox(
          height: 154,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < days.length; index++)
                Expanded(
                  child: Semantics(
                    label:
                        '${_weekday(days[index])}: ${counts[index]} actividades',
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${counts[index]}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 5),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: counts[index] == 0
                              ? 5
                              : 82 * counts[index] / maximum,
                          width: 22,
                          decoration: BoxDecoration(
                            color: counts[index] == 0
                                ? colors.surfaceContainerHighest
                                : SaberPlusColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _weekday(days[index]),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementHeader extends StatelessWidget {
  const _AchievementHeader({required this.totals});

  final AchievementTotals totals;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Logros',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Text(
            '${totals.unlocked} de ${totals.total}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
      const SizedBox(height: 9),
      LinearProgressIndicator(
        key: const Key('achievement-total-progress'),
        value: totals.completion,
        minHeight: 8,
        borderRadius: BorderRadius.circular(8),
      ),
      const SizedBox(height: 6),
      Text('${totals.answeredQuestions} preguntas respondidas'),
    ],
  );
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: Key('achievement-${achievement.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: achievement.unlocked
                  ? const Color(0xFFFFE3A3)
                  : colors.surfaceContainerHighest,
              foregroundColor: achievement.unlocked
                  ? const Color(0xFF9A5800)
                  : colors.onSurfaceVariant,
              child: Icon(_achievementIcon(achievement.category)),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (achievement.unlocked)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: SaberPlusColors.success,
                          size: 20,
                        ),
                    ],
                  ),
                  Text(
                    achievement.category.label,
                    style: TextStyle(color: colors.primary, fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(achievement.description),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: achievement.percentage / 100,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    achievement.unlocked
                        ? 'Desbloqueado'
                        : '${achievement.progress} de ${achievement.goal}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GamificationError extends StatelessWidget {
  const _GamificationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 52),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Intentar nuevamente'),
          ),
        ],
      ),
    ),
  );
}

IconData _achievementIcon(AchievementCategory category) => switch (category) {
  AchievementCategory.practice => Icons.quiz_outlined,
  AchievementCategory.precision => Icons.gps_fixed_rounded,
  AchievementCategory.simulations => Icons.timer_outlined,
  AchievementCategory.study => Icons.menu_book_outlined,
  AchievementCategory.streak => Icons.local_fire_department_outlined,
  AchievementCategory.battles => Icons.sports_martial_arts_outlined,
  AchievementCategory.other => Icons.emoji_events_outlined,
};

String _weekday(DateTime date) =>
    const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][date.weekday - 1];

String _formatInteger(int value) {
  final digits = value.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
    output.write(digits[index]);
  }
  return output.toString();
}

String _messageFor(Object error) => error is ApiError
    ? error.message
    : 'No pudimos cargar tu actividad y logros.';
