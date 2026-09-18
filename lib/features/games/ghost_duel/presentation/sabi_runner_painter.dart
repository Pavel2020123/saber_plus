import 'dart:math' as math;

import 'package:flutter/material.dart';

/// First vector adaptation of Sabi, not a tracing or a set of PNG frames.
/// One periodic pose drives fixed geometry; it never changes game state.
class SabiRunnerPainter extends CustomPainter {
  const SabiRunnerPainter({required this.phase});

  final double phase;
  static const skin = Color(0xff2bb9d9);
  static const light = Color(0xffa8e6ed);
  static const ink = Color(0xff102c55);
  static const coral = Color(0xffff7773);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 250);
    final wave = phase * math.pi * 2;
    final bounce = -2.5 * (1 - math.cos(wave * 2));
    canvas.translate(0, bounce);

    // Tail stays attached at the pelvis; the tip follows the stride.
    final tip = math.sin(wave - .5) * 5;
    final tail = Path()
      ..moveTo(96, 163)
      ..cubicTo(69, 179, 44, 181, 27, 157 + tip)
      ..cubicTo(22, 150 + tip, 17, 153 + tip, 22, 169 + tip)
      ..cubicTo(32, 199, 72, 200, 108, 179)
      ..close();
    _fill(canvas, tail, skin);
    _line(
      canvas,
      Path()
        ..moveTo(28, 171 + tip)
        ..quadraticBezierTo(53, 192, 88, 177),
      light,
      5,
    );

    _leg(canvas, phase + .5, bounce, far: true);
    _arm(canvas, wave + math.pi, far: true);
    _leg(canvas, phase, bounce, far: false);

    _fill(
      canvas,
      Path()
        ..moveTo(75, 112)
        ..quadraticBezierTo(106, 103, 132, 119)
        ..lineTo(144, 148)
        ..lineTo(130, 154)
        ..lineTo(132, 179)
        ..quadraticBezierTo(102, 188, 74, 174)
        ..lineTo(78, 144)
        ..lineTo(65, 142)
        ..close(),
      const Color(0xff173d75),
    );
    _line(
      canvas,
      Path()
        ..moveTo(78, 171)
        ..quadraticBezierTo(106, 181, 128, 175),
      const Color(0xff25558c),
      3,
    );
    // A stable geometric S+ emblem, never mirrored or redrawn by AI.
    canvas.save();
    canvas.translate(92, 138);
    canvas.rotate(.08);
    _line(
      canvas,
      Path()
        ..moveTo(23, 2)
        ..cubicTo(2, -4, -3, 10, 14, 12)
        ..cubicTo(34, 15, 23, 31, 3, 24),
      Colors.white,
      5.5,
    );
    _line(
      canvas,
      Path()
        ..moveTo(32, -2)
        ..lineTo(32, 8)
        ..moveTo(27, 3)
        ..lineTo(37, 3),
      Colors.white,
      3.7,
    );
    canvas.restore();
    _arm(canvas, wave, far: false);

    canvas.save();
    canvas.translate(0, math.sin(wave * 2) * .8);
    // Six branquias retain their shape; only the attachment rotation changes.
    for (final far in [true, false]) {
      for (var i = 0; i < 3; i++) {
        final anchor = Offset(far ? 151 : 57, 49 + i * 21.0);
        canvas.save();
        canvas.translate(anchor.dx, anchor.dy);
        canvas.rotate((far ? .15 : -.15) + math.sin(wave - i * .3) * .05);
        final side = far ? 1.0 : -1.0;
        _fill(
          canvas,
          Path()
            ..moveTo(0, 8)
            ..cubicTo(side * 14, 10, side * 38, -7, side * 29, -23)
            ..cubicTo(side * 17, -32, side * 7, -6, 0, -6)
            ..close(),
          coral,
        );
        _line(
          canvas,
          Path()
            ..moveTo(side * 5, 1)
            ..quadraticBezierTo(side * 18, -7, side * 23, -17),
          const Color(0xffee5b64),
          5,
        );
        canvas.restore();
      }
    }
    final head = Path()
      ..moveTo(53, 62)
      ..cubicTo(52, 27, 80, 17, 110, 22)
      ..cubicTo(143, 20, 168, 34, 170, 63)
      ..lineTo(174, 87)
      ..cubicTo(177, 118, 148, 125, 111, 123)
      ..cubicTo(74, 125, 49, 116, 50, 91)
      ..close();
    _fill(canvas, head, skin);
    _fill(
      canvas,
      Path()
        ..moveTo(85, 27)
        ..cubicTo(62, 8, 76, 4, 94, 17)
        ..cubicTo(76, -5, 94, -3, 115, 23)
        ..close(),
      skin,
    );
    _fill(
      canvas,
      Path()
        ..moveTo(65, 94)
        ..cubicTo(61, 83, 80, 81, 102, 89)
        ..quadraticBezierTo(116, 80, 140, 88)
        ..cubicTo(164, 80, 176, 89, 164, 106)
        ..cubicTo(149, 123, 85, 127, 64, 106)
        ..close(),
      light,
    );
    _eye(canvas, const Offset(101, 67), 14, 20);
    _eye(canvas, const Offset(146, 65), 11, 18);
    _line(
      canvas,
      Path()
        ..moveTo(85, 41)
        ..quadraticBezierTo(96, 34, 106, 40),
      ink,
      4.5,
    );
    _line(
      canvas,
      Path()
        ..moveTo(138, 39)
        ..quadraticBezierTo(147, 33, 155, 39),
      ink,
      4,
    );
    canvas.drawOval(const Rect.fromLTWH(120, 86, 3, 5), Paint()..color = ink);
    canvas.drawOval(const Rect.fromLTWH(130, 85, 3, 5), Paint()..color = ink);
    _line(
      canvas,
      Path()
        ..moveTo(105, 99)
        ..quadraticBezierTo(130, 114, 151, 94),
      ink,
      2.7,
    );
    canvas.restore();
    canvas.restore();
  }

  void _eye(Canvas c, Offset center, double rx, double ry) {
    c.drawOval(
      Rect.fromCenter(center: center, width: rx * 2 + 4, height: ry * 2 + 5),
      Paint()..color = ink,
    );
    c.drawOval(
      Rect.fromCenter(
        center: center + const Offset(0, 2),
        width: rx * 2,
        height: ry * 2,
      ),
      Paint()..color = Colors.white,
    );
    c.drawOval(
      Rect.fromCenter(
        center: center + const Offset(4, 3),
        width: rx * 1.5,
        height: ry * 1.75,
      ),
      Paint()..color = const Color(0xff17568c),
    );
    c.drawOval(
      Rect.fromCenter(
        center: center + const Offset(5, 2),
        width: rx * 1.15,
        height: ry * 1.45,
      ),
      Paint()..color = ink,
    );
    c.drawCircle(
      center + const Offset(6, -6),
      3.8,
      Paint()..color = Colors.white,
    );
  }

  void _leg(Canvas c, double t, double bounce, {required bool far}) {
    t %= 1;
    // First half: planted foot moves back. Second half: lifted recovery.
    final stance = t < .5;
    final u = stance ? t * 2 : (t - .5) * 2;
    final foot = Offset(
      stance ? 132 - u * 58 : 74 + u * 58,
      234 - bounce - (stance ? 0 : math.sin(u * math.pi) * 27),
    );
    final hip = Offset(far ? 113 : 92, 170);
    final delta = foot - hip;
    final distance = delta.distance;
    const length = 40.0;
    final middle = (hip + foot) / 2;
    final bend = math.sqrt(
      math.max(0, length * length - distance * distance / 4),
    );
    final knee = middle + Offset(delta.dy, -delta.dx) / distance * bend;
    final color = far ? const Color(0xff2295bb) : skin;
    _line(
      c,
      Path()
        ..moveTo(hip.dx, hip.dy)
        ..lineTo(knee.dx, knee.dy)
        ..lineTo(foot.dx, foot.dy - 4),
      color,
      far ? 17 : 20,
    );
    c.drawOval(
      Rect.fromCenter(
        center: foot + const Offset(6, -2),
        width: 32,
        height: 13,
      ),
      Paint()..color = color,
    );
    if (!far) {
      _line(
        c,
        Path()
          ..moveTo(knee.dx - 3, knee.dy + 2)
          ..lineTo(foot.dx - 3, foot.dy - 8),
        const Color(0xff63cede),
        4,
      );
      _line(
        c,
        Path()
          ..moveTo(foot.dx + 12, foot.dy - 5)
          ..lineTo(foot.dx + 14, foot.dy),
        const Color(0xff1b92b9),
        1.5,
      );
    }
  }

  void _arm(Canvas c, double wave, {required bool far}) {
    final shoulder = Offset(far ? 126 : 78, 129);
    final angle = math.sin(wave) * .7;
    final elbow = shoulder + Offset(math.sin(angle) * 29, math.cos(angle) * 29);
    final hand =
        elbow + Offset(math.cos(angle) * 21, -9 + math.sin(angle) * 16);
    final color = far ? const Color(0xff2295bb) : skin;
    _line(
      c,
      Path()
        ..moveTo(shoulder.dx, shoulder.dy)
        ..lineTo(elbow.dx, elbow.dy)
        ..lineTo(hand.dx, hand.dy),
      color,
      15,
    );
    c.drawOval(
      Rect.fromCenter(center: hand, width: 20, height: 17),
      Paint()..color = color,
    );
    if (!far) {
      _line(
        c,
        Path()
          ..moveTo(hand.dx + 3, hand.dy - 4)
          ..quadraticBezierTo(hand.dx + 7, hand.dy, hand.dx + 2, hand.dy + 4),
        const Color(0xff1688af),
        1.6,
      );
    }
  }

  void _fill(Canvas c, Path path, Color color) =>
      c.drawPath(path, Paint()..color = color);

  void _line(Canvas c, Path path, Color color, double width) => c.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );

  @override
  bool shouldRepaint(SabiRunnerPainter oldDelegate) =>
      phase != oldDelegate.phase;
}
