import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../app/theme.dart';
import '../../../core/network/api_error.dart';
import '../../../core/widgets/animated_streak_flame.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/gamification_models.dart';
import 'gamification_providers.dart';
import 'streak_flame_style.dart';

enum _StreakPreviewState { active, frozen, lost }

class GamificationPage extends ConsumerStatefulWidget {
  const GamificationPage({super.key});

  @override
  ConsumerState<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends ConsumerState<GamificationPage> {
  final Map<String, AchievementCertificate> _certificates = {};
  final Set<String> _checkedCertificates = {};
  final Set<String> _downloadingCertificates = {};
  int? _previewStreakDays;
  var _previewStreakState = _StreakPreviewState.active;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(gamificationSummaryProvider);
    final session = ref.watch(sessionControllerProvider);
    final xp = session.user?.xpTotal ?? 0;

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
        data: (data) {
          _checkExistingCertificates(data.achievements);
          final demoPreview = session.user?.isDemo ?? false;
          final displayedStreak = demoPreview
              ? _previewStreak(data.streak)
              : data.streak;
          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: _GamificationContent(
              summary: data,
              displayedStreak: displayedStreak,
              xp: xp,
              previewEnabled: demoPreview,
              previewDays: _previewStreakDays ?? data.streak.current,
              previewState: _previewStreakState,
              onAdvancePreview: () => _advancePreview(data.streak.current),
              onPreviewState: (value) =>
                  _changePreviewState(value, data.streak.current),
              onResetPreview: _resetPreview,
              certificates: _certificates,
              downloadingCertificates: _downloadingCertificates,
              onCertificate: _downloadOrOpenCertificate,
            ),
          );
        },
      ),
    );
  }

  StudyStreak _previewStreak(StudyStreak source) {
    if (_previewStreakDays == null &&
        _previewStreakState == _StreakPreviewState.active) {
      return source;
    }
    final days = _previewStreakDays ?? source.current;
    return switch (_previewStreakState) {
      _StreakPreviewState.active => StudyStreak(
        current: days,
        best: math.max(source.best, days),
        activeToday: true,
        lastActivity: DateTime.now(),
      ),
      _StreakPreviewState.frozen => StudyStreak(
        current: days,
        best: math.max(source.best, days),
        activeToday: false,
        lastActivity: DateTime.now().subtract(const Duration(days: 1)),
      ),
      _StreakPreviewState.lost => StudyStreak(
        current: 0,
        best: math.max(source.best, days),
        activeToday: false,
        lastActivity: DateTime.now().subtract(const Duration(days: 2)),
      ),
    };
  }

  void _advancePreview(int currentDays) {
    setState(() {
      _previewStreakDays = (_previewStreakDays ?? currentDays) + 10;
      _previewStreakState = _StreakPreviewState.active;
    });
  }

  void _changePreviewState(_StreakPreviewState state, int currentDays) {
    setState(() {
      _previewStreakDays ??= currentDays;
      _previewStreakState = state;
    });
  }

  void _resetPreview() {
    setState(() {
      _previewStreakDays = null;
      _previewStreakState = _StreakPreviewState.active;
    });
  }

  void _checkExistingCertificates(List<Achievement> achievements) {
    final userId = ref.read(sessionControllerProvider).user?.id;
    if (userId == null) return;
    final repository = ref.read(gamificationRepositoryProvider);
    for (final achievement in achievements) {
      if (!achievement.unlocked || !_checkedCertificates.add(achievement.id)) {
        continue;
      }
      Future<void>(() async {
        final certificate = await repository.findCertificate(
          userId: userId,
          achievement: achievement,
        );
        if (mounted && certificate != null) {
          setState(() => _certificates[achievement.id] = certificate);
        }
      }).onError((_, _) {});
    }
  }

  Future<void> _downloadOrOpenCertificate(Achievement achievement) async {
    final userId = ref.read(sessionControllerProvider).user?.id;
    if (userId == null || _downloadingCertificates.contains(achievement.id)) {
      return;
    }
    setState(() => _downloadingCertificates.add(achievement.id));
    try {
      final repository = ref.read(gamificationRepositoryProvider);
      var certificate = await repository.findCertificate(
        userId: userId,
        achievement: achievement,
      );
      final downloadedNow = certificate == null;
      certificate ??= await repository.downloadCertificate(
        userId: userId,
        achievement: achievement,
      );
      if (!mounted) return;
      setState(() => _certificates[achievement.id] = certificate!);
      final result = await OpenFilex.open(
        certificate.localPath,
        type: 'application/pdf',
      );
      if (!mounted) return;
      if (result.type == ResultType.done) {
        if (downloadedNow) {
          _showMessage('Certificado guardado como ${certificate.fileName}.');
        }
      } else {
        _showMessage(
          'El certificado se guardó, pero no encontramos una aplicación para abrir PDF.',
        );
      }
    } on Object catch (error) {
      if (mounted) _showMessage(_messageFor(error));
    } finally {
      if (mounted) {
        setState(() => _downloadingCertificates.remove(achievement.id));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait<void>([
      ref.read(sessionControllerProvider.notifier).refreshProfile(),
      ref.refresh(gamificationSummaryProvider.future).then((_) {}),
    ]);
  }
}

class _GamificationContent extends StatelessWidget {
  const _GamificationContent({
    required this.summary,
    required this.displayedStreak,
    required this.xp,
    required this.previewEnabled,
    required this.previewDays,
    required this.previewState,
    required this.onAdvancePreview,
    required this.onPreviewState,
    required this.onResetPreview,
    required this.certificates,
    required this.downloadingCertificates,
    required this.onCertificate,
  });

  final GamificationSummary summary;
  final StudyStreak displayedStreak;
  final int xp;
  final bool previewEnabled;
  final int previewDays;
  final _StreakPreviewState previewState;
  final VoidCallback onAdvancePreview;
  final ValueChanged<_StreakPreviewState> onPreviewState;
  final VoidCallback onResetPreview;
  final Map<String, AchievementCertificate> certificates;
  final Set<String> downloadingCertificates;
  final ValueChanged<Achievement> onCertificate;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('gamification-list'),
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
    children: [
      _StatusCard(streak: displayedStreak, xp: xp),
      if (previewEnabled) ...[
        const SizedBox(height: 12),
        _StreakPreviewControls(
          days: previewDays,
          state: previewState,
          onAdvance: onAdvancePreview,
          onStateChanged: onPreviewState,
          onReset: onResetPreview,
        ),
      ],
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
            child: _AchievementCard(
              achievement: achievement,
              certificate: certificates[achievement.id],
              downloading: downloadingCertificates.contains(achievement.id),
              onCertificate: () => onCertificate(achievement),
            ),
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
    final flame = StreakFlameStyle.fromStreak(streak);
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
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: flame.color.withValues(alpha: 0.5),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedStreakFlame(
                      key: const Key('gamification-streak-flame'),
                      color: flame.color,
                      size: 39,
                      animate: flame.burns,
                      continuous: flame.burns,
                      semanticLabel:
                          '${flame.statusLabel}, ${streak.current} días',
                    ),
                    if (flame.state == StreakFlameState.frozen)
                      const Positioned(
                        right: 4,
                        bottom: 4,
                        child: Icon(
                          Icons.ac_unit_rounded,
                          key: Key('frozen-streak-indicator'),
                          color: Color(0xFF0284C7),
                          size: 17,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      streak.current == 1
                          ? '1 día de racha'
                          : '${streak.current} días de racha',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      flame.statusLabel,
                      key: const Key('streak-flame-status'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
    if (value.current > 0) {
      return 'Tu llama está congelada. Haz una actividad hoy para salvarla.';
    }
    if (value.lastActivity != null) {
      return 'Empieza una nueva racha con una actividad hoy.';
    }
    return 'Tu primera actividad iniciará la racha.';
  }
}

class _StreakPreviewControls extends StatelessWidget {
  const _StreakPreviewControls({
    required this.days,
    required this.state,
    required this.onAdvance,
    required this.onStateChanged,
    required this.onReset,
  });

  final int days;
  final _StreakPreviewState state;
  final VoidCallback onAdvance;
  final ValueChanged<_StreakPreviewState> onStateChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('streak-preview-controls'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vista previa de la racha',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text('Solo cambia la demostración visual.'),
                  ],
                ),
              ),
              IconButton(
                key: const Key('reset-streak-preview'),
                tooltip: 'Restablecer vista previa',
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('$days días preparados')),
              FilledButton.tonalIcon(
                key: const Key('advance-streak-preview'),
                style: FilledButton.styleFrom(minimumSize: const Size(116, 48)),
                onPressed: onAdvance,
                icon: const Icon(Icons.fast_forward_rounded),
                label: const Text('+10 días'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_StreakPreviewState>(
              key: const Key('streak-state-preview'),
              segments: const [
                ButtonSegment(
                  value: _StreakPreviewState.active,
                  label: Text('Activa'),
                ),
                ButtonSegment(
                  value: _StreakPreviewState.frozen,
                  label: Text('Congelada'),
                ),
                ButtonSegment(
                  value: _StreakPreviewState.lost,
                  label: Text('Perdida'),
                ),
              ],
              selected: {state},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  onStateChanged(selection.first),
            ),
          ),
        ],
      ),
    ),
  );
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
  const _AchievementCard({
    required this.achievement,
    required this.certificate,
    required this.downloading,
    required this.onCertificate,
  });

  final Achievement achievement;
  final AchievementCertificate? certificate;
  final bool downloading;
  final VoidCallback onCertificate;

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
                  if (achievement.unlocked) ...[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      key: Key('certificate-${achievement.id}'),
                      onPressed: downloading ? null : onCertificate,
                      icon: downloading
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              certificate == null
                                  ? Icons.download_rounded
                                  : Icons.picture_as_pdf_outlined,
                            ),
                      label: Text(
                        certificate == null
                            ? 'Descargar certificado'
                            : 'Abrir certificado',
                      ),
                    ),
                  ],
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
