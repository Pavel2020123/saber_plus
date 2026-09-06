import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ghost_character.dart';

class GhostRacePanel extends StatelessWidget {
  const GhostRacePanel({
    required this.currentScore,
    required this.ghostScore,
    required this.recordScore,
    super.key,
  });

  final int currentScore;
  final int? ghostScore;
  final int? recordScore;

  @override
  Widget build(BuildContext context) {
    final ghost = ghostScore;
    final difference = currentScore - (ghost ?? 0);
    final theme = Theme.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final duration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 420);
    // Both lanes always use the SAME points scale, including beyond the record.
    final ceiling =
        math.max(
          100,
          math.max(currentScore, math.max(ghost ?? 0, recordScore ?? 0)),
        ) *
        1.12;
    final message = switch ((ghost, difference)) {
      (null, _) => 'Primera partida: estás creando tu fantasma',
      (_, > 0) => 'Vas $difference puntos delante de tu fantasma',
      (_, < 0) => 'Tu fantasma lleva ${difference.abs()} puntos de ventaja',
      _ => 'Van empatados',
    };
    return Container(
      key: const Key('ghost-race-status'),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.brightness == Brightness.dark
            ? const Color(0xff282039)
            : const Color(0xfff6f2fd),
        border: Border.all(
          color: const Color(0xff9875ca).withValues(alpha: .3),
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recordScore == null
                ? 'Tu primer fantasma'
                : 'Tu récord anterior · $recordScore pts',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          if (ghost != null) ...[
            _RaceLane(
              label: 'Tú · $currentScore pts',
              position: (currentScore / ceiling).clamp(0, 1),
              duration: duration,
              markerKey: const Key('ghost-player-marker'),
              color: const Color(0xff26a49b),
              marker: const _PlayerToken(),
            ),
            _RaceLane(
              label: 'Fantasma · $ghost pts',
              position: (ghost / ceiling).clamp(0, 1),
              duration: duration,
              markerKey: const Key('ghost-record-marker'),
              color: const Color(0xff9875ca),
              marker: GhostCharacter(
                size: 46,
                mood: difference > 0 ? GhostMood.surprised : GhostMood.friendly,
              ),
            ),
          ] else
            const Align(
              alignment: Alignment.center,
              child: GhostCharacter(
                size: 76,
                forming: true,
                label: 'Tu fantasma se está formando',
              ),
            ),
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(message, style: theme.textTheme.labelLarge),
          ),
        ],
      ),
    );
  }
}

class _RaceLane extends StatelessWidget {
  const _RaceLane({
    required this.label,
    required this.position,
    required this.duration,
    required this.markerKey,
    required this.color,
    required this.marker,
  });
  final String label;
  final double position;
  final Duration duration;
  final Key markerKey;
  final Color color;
  final Widget marker;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      SizedBox(
        height: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              height: 4,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            AnimatedAlign(
              key: markerKey,
              alignment: Alignment(-1 + position * 2, 0),
              duration: duration,
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: 46,
                height: 42,
                child: Center(child: marker),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _PlayerToken extends StatelessWidget {
  const _PlayerToken();

  @override
  Widget build(BuildContext context) => Container(
    width: 31,
    height: 31,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        colors: [Color(0xff48bfb1), Color(0xff188378)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xff168b7e).withValues(alpha: .25),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: const Icon(Icons.person_rounded, size: 22, color: Colors.white),
  );
}
