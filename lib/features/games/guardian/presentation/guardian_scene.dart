import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../trivia_rush/presentation/game_scene_motion.dart';

/// Arte vectorial: la animación reacciona al resultado, nunca lo calcula.
class GuardianScene extends StatelessWidget {
  const GuardianScene({
    super.key,
    this.energy = 6,
    this.shield = 3,
    this.turn = 0,
    this.lastCorrect,
    this.victory = false,
  });
  final int energy;
  final int shield;
  final int turn;
  final bool? lastCorrect;
  final bool victory;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Guardián: $energy de 6 de energía. Tu escudo: $shield de 3.',
    image: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff2f9f7), Color(0xfffaf4e7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: GameSceneMotion(
          builder: (context, phase) => GameSceneMotion(
            key: ValueKey('guardian-impact-$turn'),
            repeat: false,
            duration: const Duration(milliseconds: 800),
            builder: (context, impact) => CustomPaint(
              key: const Key('guardian-scene'),
              painter: GuardianPainter(
                phase: phase,
                impact: turn == 0 ? 1 : impact,
                energy: energy,
                shield: shield,
                correct: lastCorrect,
                victory: victory,
              ),
              child: const SizedBox(width: double.infinity, height: 240),
            ),
          ),
        ),
      ),
    ),
  );
}

class GuardianPainter extends CustomPainter {
  const GuardianPainter({
    required this.phase,
    required this.impact,
    required this.energy,
    required this.shield,
    required this.correct,
    required this.victory,
  });
  final double phase;
  final double impact;
  final int energy;
  final int shield;
  final bool? correct;
  final bool victory;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate((size.width - 320) / 2, 0);
    const ink = Color(0xff254a4c);
    const gold = Color(0xffb78935);
    const teal = Color(0xff2f9e8f);
    final wave = math.sin(phase * math.pi * 2);
    final pulse = math.sin(impact * math.pi) * (1 - impact);
    final bodyX =
        177 +
        (correct == true ? math.sin(impact * math.pi * 6) * pulse * 12 : 0.0);
    final bodyY = 100 + wave * 3;
    final halo = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x402f9e8f), Color(0x002f9e8f)],
      ).createShader(Rect.fromCircle(center: Offset(bodyX, 116), radius: 100));
    canvas.drawCircle(Offset(bodyX, 116), 100, halo);
    canvas.drawOval(
      const Rect.fromLTWH(107, 214, 146, 12),
      Paint()..color = const Color(0x18254a4c),
    );
    // Órbita de seis runas: cada acierto apaga una, sin ocultar el marcador textual.
    for (var i = 0; i < 6; i++) {
      final angle = math.pi * (1.10 + i * .16);
      final c = Offset(177 + math.cos(angle) * 113, 130 + math.sin(angle) * 98);
      final lit = i < energy;
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(math.pi / 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-7, -7, 14, 14),
          const Radius.circular(3),
        ),
        Paint()..color = lit ? gold : const Color(0xffd9dfda),
      );
      canvas.drawLine(
        const Offset(-3, 0),
        const Offset(3, 0),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2,
      );
      canvas.restore();
    }
    canvas.save();
    canvas.translate(bodyX, bodyY);
    void plate(Rect rect, Color fill, {double radius = 14}) {
      final r = RRect.fromRectAndRadius(rect, Radius.circular(radius));
      canvas.drawRRect(
        r.shift(const Offset(0, 4)),
        Paint()..color = const Color(0xff98afaa),
      );
      canvas.drawRRect(r, Paint()..color = fill);
      canvas.drawRRect(
        r,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    plate(const Rect.fromLTWH(-38, 38, 31, 68), const Color(0xffccd8cf));
    plate(const Rect.fromLTWH(7, 38, 31, 68), const Color(0xffccd8cf));
    plate(Rect.fromLTWH(-80, 12 - wave * 2, 29, 53), const Color(0xffdce3d7));
    plate(Rect.fromLTWH(51, 12 + wave * 2, 29, 53), const Color(0xffdce3d7));
    plate(
      const Rect.fromLTWH(-50, 0, 100, 69),
      const Color(0xffdde7dd),
      radius: 20,
    );
    final breast = Path()
      ..moveTo(-30, 15)
      ..lineTo(0, 4)
      ..lineTo(30, 15)
      ..lineTo(23, 49)
      ..lineTo(0, 62)
      ..lineTo(-23, 49)
      ..close();
    canvas.drawPath(breast, Paint()..color = gold);
    final gem = Path()
      ..moveTo(0, 15)
      ..lineTo(14, 32)
      ..lineTo(0, 49)
      ..lineTo(-14, 32)
      ..close();
    canvas.drawPath(
      gem,
      Paint()..color = victory ? const Color(0xff81cbb3) : teal,
    );
    canvas.drawLine(
      const Offset(0, 19),
      const Offset(-7, 31),
      Paint()
        ..color = const Color(0xffd3fff0)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    plate(
      const Rect.fromLTWH(-43, -55, 86, 55),
      const Color(0xffeaf0e3),
      radius: 18,
    );
    // Placa frontal y cejas dan expresión sin necesitar imágenes descargadas.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-32, -38, 64, 25),
        const Radius.circular(9),
      ),
      Paint()..color = ink,
    );
    final eye = Paint()
      ..color = const Color(0xffa5f3cf)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final x in [-17.0, 17.0]) {
      if (victory) {
        canvas.drawArc(
          Rect.fromCenter(center: Offset(x, -24), width: 11, height: 8),
          math.pi,
          math.pi,
          false,
          eye..style = PaintingStyle.stroke,
        );
      } else {
        canvas.drawLine(Offset(x, -30), Offset(x, -23), eye);
      }
    }
    final crown = Path()
      ..moveTo(-25, -54)
      ..lineTo(-29, -69)
      ..lineTo(-9, -62)
      ..lineTo(0, -76)
      ..lineTo(9, -62)
      ..lineTo(29, -69)
      ..lineTo(25, -54)
      ..close();
    canvas.drawPath(crown, Paint()..color = gold);
    canvas.drawCircle(
      const Offset(0, -63),
      3,
      Paint()..color = const Color(0xffe7fbe9),
    );
    canvas.restore();
    // Escudo del estudiante y proyectil ornamental tras una respuesta confirmada.
    final shieldX =
        50.0 +
        (correct == false ? math.sin(impact * math.pi * 6) * pulse * 10 : 0);
    final shieldPath = Path()
      ..moveTo(shieldX - 22, 160)
      ..lineTo(shieldX, 150)
      ..lineTo(shieldX + 22, 160)
      ..lineTo(shieldX + 18, 193)
      ..quadraticBezierTo(shieldX, 213, shieldX, 213)
      ..quadraticBezierTo(shieldX - 18, 202, shieldX - 18, 193)
      ..close();
    canvas.drawPath(
      shieldPath,
      Paint()..color = shield > 0 ? teal : const Color(0xffa8b5b3),
    );
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(shieldX, 163),
      Offset(shieldX, 197),
      Paint()
        ..color = const Color(0xffc3e4d4)
        ..strokeWidth = 3,
    );
    if (impact > 0 && impact < 1 && correct != null) {
      final p = Curves.easeOut.transform(impact);
      final a = correct! ? Offset(shieldX, 166) : Offset(bodyX, bodyY + 30);
      final b = correct! ? Offset(bodyX, bodyY + 30) : Offset(shieldX, 166);
      final pos = Offset.lerp(a, b, p)!;
      canvas.drawCircle(
        pos,
        6 + pulse * 4,
        Paint()
          ..color = (correct! ? gold : const Color(0xffce855a)).withValues(
            alpha: 1 - impact,
          ),
      );
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final end =
            b + Offset(math.cos(angle), math.sin(angle)) * (8 + impact * 28);
        canvas.drawCircle(
          end,
          2.5,
          Paint()..color = gold.withValues(alpha: pulse.clamp(0, 1)),
        );
      }
    }
    for (var i = 0; i < 8; i++) {
      final x = 70.0 + i * 27;
      final y = 50 + ((i * 19 + phase * 25) % 140);
      canvas.drawCircle(
        Offset(x, y),
        i.isEven ? 1.8 : 1,
        Paint()..color = gold.withValues(alpha: .3),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(GuardianPainter oldDelegate) =>
      phase != oldDelegate.phase ||
      impact != oldDelegate.impact ||
      energy != oldDelegate.energy ||
      shield != oldDelegate.shield ||
      correct != oldDelegate.correct ||
      victory != oldDelegate.victory;
}
