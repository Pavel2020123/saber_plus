import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/trivia_rush_models.dart';
import 'game_scene_motion.dart';

class TriviaRushHud extends StatelessWidget {
  const TriviaRushHud({
    required this.seconds,
    required this.score,
    required this.shieldActive,
    required this.assisted,
    this.feedback,
    this.feedbackPositive = true,
    this.feedbackId = 0,
    super.key,
  });

  final int seconds;
  final TriviaRushScore score;
  final bool shieldActive;
  final bool assisted;
  final String? feedback;
  final bool feedbackPositive;
  final int feedbackId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final nextCombo = switch (score.combo) {
      < 3 => 3,
      < 6 => 6,
      < 10 => 10,
      _ => null,
    };
    final reduced = MediaQuery.disableAnimationsOf(context);
    final positiveColor = dark
        ? const Color(0xff91e6c8)
        : const Color(0xff157653);
    final text = feedback ?? 'Encadena aciertos para aumentar el multiplicador';
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _HudTile(
                label: 'TIEMPO',
                icon: Icons.timer_outlined,
                value: '$seconds s',
                color: seconds <= 10
                    ? theme.colorScheme.error
                    : theme.colorScheme.onSurface,
                background: seconds <= 10
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.surfaceContainerLow,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _HudTile(
                label: 'PUNTOS',
                icon: Icons.stars_rounded,
                value: '${score.points} pts',
                color: dark ? const Color(0xfff6d58a) : const Color(0xff925b13),
                background: dark
                    ? const Color(0xff362c1e)
                    : const Color(0xfffff6df),
                pulseKey: score.points,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _HudTile(
                label: shieldActive ? 'PROTEGIDO' : 'COMBO',
                icon: shieldActive ? Icons.shield_rounded : Icons.bolt_rounded,
                value: 'x${score.multiplier} · ${score.combo}',
                color: dark ? const Color(0xffc8b4ff) : const Color(0xff6343a1),
                background: dark
                    ? const Color(0xff2e2540)
                    : const Color(0xfff3edff),
                pulseKey: score.combo,
                shield: shieldActive,
                subtitle: nextCombo == null
                    ? '¡Combo máximo!'
                    : '${nextCombo - score.combo} para x${score.multiplier + 1}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // A stable, non-modal slot: updates never cover or delay a question.
        Semantics(
          liveRegion: feedback != null,
          child: AnimatedSwitcher(
            duration: reduced
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: Row(
              key: ValueKey(feedbackId),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  feedback == null
                      ? Icons.auto_awesome_rounded
                      : feedbackPositive
                      ? Icons.check_circle_rounded
                      : Icons.tips_and_updates_outlined,
                  size: 16,
                  color: feedback == null
                      ? theme.colorScheme.onSurfaceVariant
                      : feedbackPositive
                      ? positiveColor
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    text,
                    key: const Key('trivia-answer-feedback'),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: feedback == null
                          ? theme.colorScheme.onSurfaceVariant
                          : feedbackPositive
                          ? positiveColor
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
                if (assisted)
                  const Tooltip(
                    message: 'Ronda asistida',
                    child: Icon(Icons.auto_fix_high_rounded, size: 16),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HudTile extends StatelessWidget {
  const _HudTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
    this.pulseKey = 0,
    this.shield = false,
    this.subtitle,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final int pulseKey;
  final bool shield;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: shield ? color.withValues(alpha: .65) : Colors.transparent,
        width: 1.5,
      ),
      boxShadow: shield
          ? [
              BoxShadow(
                color: color.withValues(alpha: .14),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ]
          : null,
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .3,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GameSceneMotion(
          key: ValueKey(pulseKey),
          repeat: false,
          duration: const Duration(milliseconds: 350),
          builder: (context, phase) => Transform.scale(
            scale: pulseKey == 0 ? 1 : 1 + math.sin(phase * math.pi) * .08,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: color),
          ),
      ],
    ),
  );
}
