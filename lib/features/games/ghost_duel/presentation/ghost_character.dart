import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../trivia_rush/presentation/game_scene_motion.dart';

enum GhostMood { friendly, surprised, celebrating }

/// The record's mascot, drawn locally: no downloaded or licensed art needed.
class GhostCharacter extends StatelessWidget {
  const GhostCharacter({
    this.size = 100,
    this.mood = GhostMood.friendly,
    this.label = 'Fantasma de tu récord anterior',
    this.forming = false,
    super.key,
  });

  final double size;
  final GhostMood mood;
  final String label;
  final bool forming;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: RepaintBoundary(
      child: SizedBox.square(
        dimension: size,
        child: GameSceneMotion(
          builder: (context, phase) => CustomPaint(
            painter: GhostCharacterPainter(
              phase: phase,
              mood: mood,
              forming: forming,
            ),
          ),
        ),
      ),
    ),
  );
}

class GhostCharacterPainter extends CustomPainter {
  const GhostCharacterPainter({
    required this.phase,
    required this.mood,
    required this.forming,
  });

  final double phase;
  final GhostMood mood;
  final bool forming;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final wave = phase * math.pi * 2;
    final hover = math.sin(wave) * 3;
    const ink = Color(0xff31265c);
    const purple = Color(0xff9970e8);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(51, 90),
        width: 44 - hover * 1.2,
        height: 7,
      ),
      Paint()..color = purple.withValues(alpha: .14),
    );
    for (var i = 0; i < 5; i++) {
      final orbit = wave * .5 + i * 1.6;
      final center = Offset(
        50 + math.cos(orbit) * 40,
        49 + math.sin(orbit) * 32,
      );
      canvas.drawCircle(
        center,
        i.isEven ? 1.6 : 1,
        Paint()..color = purple.withValues(alpha: forming ? .32 : .22),
      );
    }
    canvas.translate(0, hover);
    // A trailing glow and three fins make the silhouette read as a ghost.
    final trail = Path()
      ..moveTo(30, 62)
      ..quadraticBezierTo(8, 69 + hover, 13, 44)
      ..quadraticBezierTo(20, 60, 31, 43)
      ..close();
    canvas.drawPath(trail, Paint()..color = purple.withValues(alpha: .14));
    final body = Path()
      ..moveTo(23, 49)
      ..cubicTo(20, 8, 76, 2, 79, 47)
      ..cubicTo(79, 56, 84, 64, 88, 67)
      ..quadraticBezierTo(78, 73, 72, 64)
      ..lineTo(72, 80 + hover * .4)
      ..quadraticBezierTo(64, 84, 60, 74 - hover * .5)
      ..quadraticBezierTo(53, 88, 46, 77 + hover * .4)
      ..quadraticBezierTo(37, 86, 32, 75)
      ..lineTo(28, 64)
      ..quadraticBezierTo(15, 71, 14, 63)
      ..quadraticBezierTo(21, 56, 23, 49)
      ..close();
    canvas.drawShadow(body, purple.withValues(alpha: .24), 5, false);
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: forming
              ? [const Color(0xfff8f4ff), const Color(0xffe4dcf5)]
              : [
                  Colors.white,
                  const Color(0xfff2eafe),
                  const Color(0xffd2bafa),
                ],
        ).createShader(const Rect.fromLTWH(20, 10, 63, 78)),
    );
    canvas.drawPath(
      body,
      Paint()
        ..color = const Color(0xffa58bcd)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(31, 35)
        ..quadraticBezierTo(32, 23, 43, 21),
      Paint()
        ..color = Colors.white.withValues(alpha: .9)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    final blinking = phase > .46 && phase < .49;
    final delighted = mood == GhostMood.celebrating;
    final surprised = mood == GhostMood.surprised;
    for (final x in [40.0, 61.0]) {
      if (blinking || delighted) {
        canvas.drawPath(
          Path()
            ..moveTo(x - 4, 43)
            ..quadraticBezierTo(x, delighted ? 35 : 44, x + 4, 43),
          Paint()
            ..color = ink
            ..strokeWidth = 2.6
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x, 42),
            width: surprised ? 10 : 8,
            height: surprised ? 15 : 12,
          ),
          Paint()..color = ink,
        );
        canvas.drawCircle(
          Offset(x + 1.5, 39),
          1.7,
          Paint()..color = Colors.white,
        );
      }
    }
    for (final x in [33.0, 69.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 52), width: 10, height: 4),
        Paint()..color = const Color(0xffe88cab).withValues(alpha: .48),
      );
    }
    if (surprised) {
      canvas.drawOval(const Rect.fromLTWH(47, 54, 7, 9), Paint()..color = ink);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(45, 55)
          ..quadraticBezierTo(51, delighted ? 66 : 61, 57, 55),
        Paint()
          ..color = ink
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
    if (delighted) {
      final sparkle = Paint()..color = const Color(0xffefba4b);
      for (var i = 0; i < 4; i++) {
        final x = 12.0 + i * 25;
        final y = 16.0 + math.sin(wave + i) * 5;
        canvas.drawPath(
          Path()
            ..moveTo(x, y - 4)
            ..lineTo(x + 1.5, y - 1.5)
            ..lineTo(x + 4, y)
            ..lineTo(x + 1.5, y + 1.5)
            ..lineTo(x, y + 4)
            ..lineTo(x - 1.5, y + 1.5)
            ..lineTo(x - 4, y)
            ..lineTo(x - 1.5, y - 1.5)
            ..close(),
          sparkle,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(GhostCharacterPainter oldDelegate) =>
      phase != oldDelegate.phase ||
      mood != oldDelegate.mood ||
      forming != oldDelegate.forming;
}
