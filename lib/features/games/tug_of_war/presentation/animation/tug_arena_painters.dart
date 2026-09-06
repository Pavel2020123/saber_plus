import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/tug_of_war_models.dart';

class TugRopePainter extends CustomPainter {
  const TugRopePainter({
    required this.ropePosition,
    required this.tension,
    required this.vibration,
    required this.colorScheme,
  });

  final double ropePosition;
  final double tension;
  final double vibration;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final marksWidth = size.width * 0.40;
    final markSpacing = marksWidth / 8;
    final shift = -ropePosition * markSpacing;
    final y = size.height * 0.49 + vibration;
    final left = size.width * 0.23 + shift;
    final right = size.width * 0.77 + shift;
    final sag = 4 * (1 - tension);
    final ropePath = Path()
      ..moveTo(left, y)
      ..cubicTo(
        size.width * 0.39 + shift,
        y + sag,
        size.width * 0.61 + shift,
        y + sag,
        right,
        y,
      );

    canvas.drawPath(
      ropePath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      ropePath,
      Paint()
        ..color = const Color(0xFF8B5A2B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      ropePath,
      Paint()
        ..color = const Color(0xFFD7A86E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );

    // Follow the actual sag with a braided texture instead of a flat line.
    final braidPaint = Paint()
      ..color = const Color(0xFF704321).withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final metric = ropePath.computeMetrics().first;
    for (var distance = 3.0; distance < metric.length; distance += 7) {
      final tangent = metric.getTangentForOffset(distance)!;
      final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
      canvas.drawLine(
        tangent.position - normal * 2.2 - tangent.vector * 1.6,
        tangent.position + normal * 2.2 + tangent.vector * 1.6,
        braidPaint,
      );
    }

    final center = Offset(size.width / 2 + shift, y + sag * 0.75);
    final ribbon = Path()
      ..moveTo(center.dx - 4, center.dy + 3)
      ..lineTo(center.dx + 6 + vibration, center.dy + 24)
      ..lineTo(center.dx, center.dy + 20)
      ..lineTo(center.dx - 6, center.dy + 25)
      ..close();
    canvas.drawPath(ribbon, Paint()..color = colorScheme.tertiary);
    canvas.drawLine(
      center.translate(0, 7),
      center.translate(vibration, 18),
      Paint()
        ..color = colorScheme.onTertiary.withValues(alpha: 0.45)
        ..strokeWidth = 1.2,
    );
    final knotPaint = Paint()..color = colorScheme.tertiary;
    canvas
      ..drawCircle(center, 8.5, knotPaint)
      ..drawCircle(center, 5, Paint()..color = colorScheme.tertiaryContainer);
    canvas.drawLine(
      center.translate(-4, -5),
      center.translate(4, 5),
      Paint()
        ..color = colorScheme.onTertiaryContainer.withValues(alpha: 0.65)
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(TugRopePainter oldDelegate) =>
      oldDelegate.ropePosition != ropePosition ||
      oldDelegate.tension != tension ||
      oldDelegate.vibration != vibration ||
      oldDelegate.colorScheme != colorScheme;
}

class TugArenaEffectsPainter extends CustomPainter {
  const TugArenaEffectsPainter({
    required this.pullProgress,
    required this.celebrationProgress,
    required this.direction,
    required this.strongPull,
    required this.winner,
    required this.colorScheme,
  });

  final double pullProgress;
  final double celebrationProgress;
  final int direction;
  final bool strongPull;
  final TugWinner? winner;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    if (direction != 0 && pullProgress > 0 && pullProgress < 1) {
      final opacity = math.sin(pullProgress * math.pi);
      final motionInk = Paint()
        ..color = colorScheme.onSurface.withValues(alpha: opacity * 0.5)
        ..strokeWidth = strongPull ? 2.5 : 1.5
        ..strokeCap = StrokeCap.round;
      final center = Offset(size.width * 0.5, size.height * 0.49);
      for (var i = 0; i < 3; i++) {
        final y = center.dy - 15 - i * 7;
        final start = center.dx + direction * (16 + i * 8);
        canvas.drawLine(
          Offset(start, y),
          Offset(start - direction * (12 + opacity * 18), y),
          motionInk,
        );
      }
    }
    if (strongPull && pullProgress > 0 && pullProgress < 0.92) {
      final opacity = math.sin(pullProgress * math.pi).clamp(0.0, 1.0);
      final loserX = direction > 0 ? size.width * 0.77 : size.width * 0.23;
      final dustPaint = Paint()
        ..color = const Color(0xFFC9A36C).withValues(alpha: opacity * 0.55);
      for (var index = 0; index < 7; index++) {
        final angle = (index - 3) * 0.42;
        final distance = 8 + index * 2.5;
        canvas.drawCircle(
          Offset(
            loserX + math.cos(angle) * distance * -direction,
            size.height * 0.79 - math.sin(angle).abs() * 12,
          ),
          1.8 + (index % 3),
          dustPaint,
        );
      }
    }

    if (winner != null && celebrationProgress > 0) {
      final eased = Curves.easeOut.transform(celebrationProgress);
      final confettiColors = [
        colorScheme.primary,
        colorScheme.tertiary,
        colorScheme.secondary,
        const Color(0xFFFFB020),
      ];
      for (var index = 0; index < 24; index++) {
        final seedX = ((index * 47) % 101) / 100;
        final delay = (index % 6) * 0.055;
        final local = ((eased - delay) / (1 - delay)).clamp(0.0, 1.0);
        if (local <= 0) continue;
        final sway = math.sin(index * 1.7 + local * math.pi * 3) * 9;
        final x = seedX * size.width + sway;
        final y = -8 + local * size.height * 0.78;
        final paint = Paint()
          ..color = confettiColors[index % confettiColors.length].withValues(
            alpha: (1 - local * 0.45).clamp(0.0, 1.0),
          );
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(index * 0.7 + local * math.pi * 2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-2.5, -5, 5, 10),
            const Radius.circular(1.5),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(TugArenaEffectsPainter oldDelegate) =>
      oldDelegate.pullProgress != pullProgress ||
      oldDelegate.celebrationProgress != celebrationProgress ||
      oldDelegate.direction != direction ||
      oldDelegate.strongPull != strongPull ||
      oldDelegate.winner != winner ||
      oldDelegate.colorScheme != colorScheme;
}

enum TugFighterReaction { neutral, effort, surprised }

/// Comic reaction marks complement the existing illustrated characters.
/// They are driven exclusively by a resolved round, never by a pending answer.
class TugFighterReactionPainter extends CustomPainter {
  const TugFighterReactionPainter({
    required this.reaction,
    required this.progress,
    required this.celebration,
  });

  final TugFighterReaction reaction;
  final double progress;
  final double celebration;

  @override
  void paint(Canvas canvas, Size size) {
    if (reaction != TugFighterReaction.neutral && progress > 0) {
      final center = Offset(size.width * 0.72, size.height * 0.12);
      final ink = Paint()
        ..color =
            (reaction == TugFighterReaction.surprised
                    ? const Color(0xFF2898D1)
                    : const Color(0xFFFFBD49))
                .withValues(alpha: progress.clamp(0, 1));
      if (reaction == TugFighterReaction.surprised) {
        final drop = Path()
          ..moveTo(center.dx, center.dy - 6)
          ..cubicTo(
            center.dx + 8,
            center.dy + 2,
            center.dx + 4,
            center.dy + 8,
            center.dx,
            center.dy + 7,
          )
          ..cubicTo(
            center.dx - 5,
            center.dy + 6,
            center.dx - 5,
            center.dy + 1,
            center.dx,
            center.dy - 6,
          )
          ..close();
        canvas.drawPath(drop, ink);
        canvas.drawCircle(
          center.translate(0, 2),
          1.4,
          Paint()..color = Colors.white.withValues(alpha: progress),
        );
      } else {
        ink
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 3; i++) {
          final angle = -math.pi / 3 + i * math.pi / 5;
          final vector = Offset(math.cos(angle), math.sin(angle));
          canvas.drawLine(center + vector * 4, center + vector * 11, ink);
        }
      }
    }
    if (celebration > 0) {
      final crown = Path()
        ..moveTo(size.width * 0.4, size.height * 0.04)
        ..lineTo(size.width * 0.37, 0)
        ..lineTo(size.width * 0.46, size.height * 0.015)
        ..lineTo(size.width * 0.5, -size.height * 0.015)
        ..lineTo(size.width * 0.55, size.height * 0.015)
        ..lineTo(size.width * 0.63, 0)
        ..lineTo(size.width * 0.6, size.height * 0.04)
        ..close();
      canvas.drawPath(crown, Paint()..color = const Color(0xFFFFCA55));
      canvas.drawPath(
        crown,
        Paint()
          ..color = const Color(0xFFA26515)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(TugFighterReactionPainter oldDelegate) =>
      reaction != oldDelegate.reaction ||
      progress != oldDelegate.progress ||
      celebration != oldDelegate.celebration;
}
