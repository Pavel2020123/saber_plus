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

    final center = Offset(size.width / 2 + shift, y + sag * 0.75);
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
