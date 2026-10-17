import 'package:flutter/material.dart';

/// Visual catalog only. Family/result assignment belongs to OV-1D3.
enum SabiProfession {
  medicine,
  nursing,
  psychology,
  law,
  software,
  industrialEngineering,
  civilEngineering,
  administration,
  accounting,
  education,
  design,
  environmentalAgro,
}

/// A native, static overlay on the unmodified canonical Sabi PNG.
///
/// Painters in this file draw only garments, professional objects and confetti.
/// Sabi's head, face, gills, body, hands, feet and tail always come from the PNG.
class SabiProfessionIllustration extends StatelessWidget {
  const SabiProfessionIllustration({super.key, required this.profession});

  static const canonicalAsset =
      'assets/characters/sabi/reference/sabi_front.png';
  static const sourceSize = Size(1230, 1278);

  final SabiProfession profession;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: switch (profession) {
      SabiProfession.medicine => 'Sabi con bata médica y estetoscopio',
      SabiProfession.nursing =>
        'Sabi de enfermería con uniforme clínico y tablero de cuidados',
      SabiProfession.psychology =>
        'Sabi de psicología con cuaderno y burbujas de conversación',
      SabiProfession.law =>
        'Sabi de derecho con traje y libro jurídico con balanza',
      SabiProfession.software => 'Sabi con portátil de software',
      SabiProfession.industrialEngineering =>
        'Sabi de ingeniería industrial con chaleco y diagrama de procesos',
      SabiProfession.civilEngineering =>
        'Sabi de ingeniería civil con chaleco y plano de un puente',
      SabiProfession.administration =>
        'Sabi de administración con chaqueta y tablero de planificación',
      SabiProfession.accounting =>
        'Sabi de contaduría con chaleco, calculadora y registro de cuentas',
      SabiProfession.education =>
        'Sabi de educación con cardigan, libro y pizarra de formas',
      SabiProfession.design =>
        'Sabi de diseño con chaqueta creativa, tableta gráfica y lápiz',
      SabiProfession.environmentalAgro =>
        'Sabi con vestimenta de campo, planta y libreta',
    },
    child: ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: sourceSize.width / sourceSize.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _SabiBackdropPainter(profession)),
            Image.asset(canonicalAsset, fit: BoxFit.fill),
            CustomPaint(painter: _SabiGarmentPainter(profession)),
          ],
        ),
      ),
    ),
  );
}

abstract class _SabiOverlayPainter extends CustomPainter {
  const _SabiOverlayPainter(this.profession);

  final SabiProfession profession;

  void drawOverlay(Canvas canvas, Size size);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(
      size.width / SabiProfessionIllustration.sourceSize.width,
      size.height / SabiProfessionIllustration.sourceSize.height,
    );
    drawOverlay(canvas, SabiProfessionIllustration.sourceSize);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SabiOverlayPainter oldDelegate) =>
      oldDelegate.profession != profession;

  void fill(Canvas canvas, Path path, Color color) =>
      canvas.drawPath(path, Paint()..color = color);

  void stroke(Canvas canvas, Path path, Color color, double width) =>
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

  void rounded(Canvas canvas, Rect rect, Color color, {double radius = 10}) =>
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        Paint()..color = color,
      );

  void line(
    Canvas canvas,
    Offset from,
    Offset to,
    Color color, [
    double width = 6,
  ]) => stroke(
    canvas,
    Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy),
    color,
    width,
  );
}

class _SabiBackdropPainter extends _SabiOverlayPainter {
  const _SabiBackdropPainter(super.profession);

  @override
  void drawOverlay(Canvas canvas, Size size) {
    _confetti(canvas);
    switch (profession) {
      case SabiProfession.medicine:
        break;
      case SabiProfession.nursing:
        _careBoard(canvas);
      case SabiProfession.psychology:
        _book(canvas, const Color(0xFF8A638D));
        _conversation(canvas);
      case SabiProfession.law:
        _legalBook(canvas);
      case SabiProfession.software:
        _laptop(canvas);
      case SabiProfession.industrialEngineering:
        _processBoard(canvas);
      case SabiProfession.civilEngineering:
        _bridgePlan(canvas);
      case SabiProfession.administration:
        _planningBoard(canvas);
      case SabiProfession.accounting:
        _book(canvas, const Color(0xFF456B69), ledger: true);
        _calculator(canvas);
      case SabiProfession.education:
        _openBook(canvas);
        _chalkboard(canvas);
      case SabiProfession.design:
        _drawingTablet(canvas);
      case SabiProfession.environmentalAgro:
        _notebook(canvas);
        _plant(canvas);
    }
  }

  // Props sit behind the unmodified hands, with their main marks in the
  // exposed portion. No helmet covers the canonical crest or gills.
  void _careBoard(Canvas canvas) {
    canvas.save();
    canvas.translate(877, 695);
    canvas.rotate(.07);
    rounded(
      canvas,
      const Rect.fromLTWH(0, 0, 250, 290),
      const Color(0xFF468D98),
    );
    rounded(
      canvas,
      const Rect.fromLTWH(14, 20, 222, 250),
      const Color(0xFFF5FBF6),
    );
    rounded(
      canvas,
      const Rect.fromLTWH(79, -12, 97, 37),
      const Color(0xFFB4CCD2),
    );
    final heart = Path()
      ..moveTo(141, 107)
      ..cubicTo(66, 67, 112, 25, 141, 58)
      ..cubicTo(175, 25, 212, 69, 141, 107)
      ..close();
    fill(canvas, heart, const Color(0xFFDC8190));
    for (var row = 0; row < 3; row++) {
      final y = 143.0 + row * 39;
      stroke(
        canvas,
        Path()
          ..moveTo(73, y)
          ..lineTo(82, y + 9)
          ..lineTo(98, y - 10),
        const Color(0xFF418985),
        6,
      );
      line(canvas, Offset(117, y), Offset(204, y), const Color(0xFF9BB9BC), 5);
    }
    canvas.restore();
  }

  void _book(Canvas canvas, Color cover, {bool ledger = false}) {
    canvas.save();
    canvas.translate(127, 783);
    canvas.rotate(.08);
    rounded(canvas, const Rect.fromLTWH(0, 0, 240, 228), cover, radius: 6);
    rounded(
      canvas,
      const Rect.fromLTWH(17, 13, 209, 201),
      const Color(0xFFF5EAD9),
      radius: 4,
    );
    rounded(
      canvas,
      const Rect.fromLTWH(0, 0, 21, 228),
      cover.withValues(alpha: .9),
      radius: 4,
    );
    if (ledger) {
      for (var row = 0; row < 5; row++) {
        line(
          canvas,
          Offset(38, 47.0 + row * 32),
          Offset(210, 47.0 + row * 32),
          const Color(0xFF9FB6A7),
          3,
        );
      }
      for (final x in [96.0, 153.0]) {
        line(canvas, Offset(x, 30), Offset(x, 193), const Color(0xFF9FB6A7), 3);
      }
    } else {
      for (var row = 0; row < 5; row++) {
        line(
          canvas,
          Offset(43, 51.0 + row * 30),
          Offset(row.isEven ? 191 : 163, 51.0 + row * 30),
          const Color(0xFFB5A4B5),
          4,
        );
      }
      rounded(
        canvas,
        const Rect.fromLTWH(172, 0, 16, 54),
        const Color(0xFFE3AE70),
        radius: 1,
      );
    }
    canvas.restore();
  }

  void _conversation(Canvas canvas) {
    canvas.save();
    canvas.translate(882, 658);
    final back = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(38, 0, 239, 133),
          const Radius.circular(35),
        ),
      )
      ..moveTo(195, 117)
      ..lineTo(241, 161)
      ..lineTo(238, 111)
      ..close();
    fill(canvas, back, const Color(0xFF9E8EC8));
    final front = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(0, 106, 219, 133),
          const Radius.circular(35),
        ),
      )
      ..moveTo(67, 224)
      ..lineTo(24, 268)
      ..lineTo(28, 216)
      ..close();
    fill(canvas, front, const Color(0xFF78BEBA));
    // Empty speech bubbles are intentional: no words, diagnosis or symbols.
    canvas.restore();
  }

  void _legalBook(Canvas canvas) {
    canvas.save();
    canvas.translate(878, 683);
    canvas.rotate(.07);
    rounded(
      canvas,
      const Rect.fromLTWH(0, 0, 260, 300),
      const Color(0xFF39455D),
      radius: 8,
    );
    rounded(
      canvas,
      const Rect.fromLTWH(23, 20, 221, 262),
      const Color(0xFF6D3F4C),
      radius: 4,
    );
    rounded(
      canvas,
      const Rect.fromLTWH(7, 15, 13, 270),
      const Color(0xFFCFB782),
      radius: 2,
    );
    const gold = Color(0xFFE4C98C);
    line(canvas, const Offset(147, 77), const Offset(147, 229), gold, 9);
    line(canvas, const Offset(91, 231), const Offset(204, 231), gold, 9);
    line(canvas, const Offset(68, 109), const Offset(225, 109), gold, 7);
    for (final x in [88.0, 205.0]) {
      line(canvas, Offset(x, 110), Offset(x - 26, 172), gold, 4);
      line(canvas, Offset(x, 110), Offset(x + 26, 172), gold, 4);
      fill(
        canvas,
        Path()
          ..moveTo(x - 31, 172)
          ..quadraticBezierTo(x, 214, x + 31, 172)
          ..close(),
        gold,
      );
    }
    canvas.drawCircle(const Offset(147, 76), 10, Paint()..color = gold);
    canvas.restore();
  }

  void _processBoard(Canvas canvas) {
    canvas.save();
    canvas.translate(857, 692);
    canvas.rotate(.04);
    rounded(
      canvas,
      const Rect.fromLTWH(0, 0, 305, 278),
      const Color(0xFF45596A),
    );
    rounded(
      canvas,
      const Rect.fromLTWH(13, 15, 279, 249),
      const Color(0xFFF2F1E7),
    );
    rounded(
      canvas,
      const Rect.fromLTWH(102, -13, 103, 34),
      const Color(0xFFB5BEC4),
    );
    const ink = Color(0xFF516B79);
    for (final y in [95.0, 177.0]) {
      line(canvas, Offset(195, y - 28), Offset(195, y + 8), ink, 6);
      stroke(
        canvas,
        Path()
          ..moveTo(187, y)
          ..lineTo(195, y + 9)
          ..lineTo(203, y),
        ink,
        5,
      );
    }
    rounded(
      canvas,
      const Rect.fromLTWH(144, 37, 102, 40),
      const Color(0xFFE9A25E),
    );
    fill(
      canvas,
      Path()
        ..moveTo(195, 108)
        ..lineTo(240, 137)
        ..lineTo(195, 166)
        ..lineTo(150, 137)
        ..close(),
      const Color(0xFF83B1BF),
    );
    rounded(
      canvas,
      const Rect.fromLTWH(143, 202, 104, 37),
      const Color(0xFF82AE8C),
    );
    stroke(
      canvas,
      Path()
        ..moveTo(151, 137)
        ..lineTo(100, 137)
        ..lineTo(100, 57)
        ..lineTo(135, 57),
      ink,
      5,
    );
    canvas.restore();
  }

  void _bridgePlan(Canvas canvas) {
    canvas.save();
    canvas.translate(853, 693);
    canvas.rotate(.04);
    rounded(
      canvas,
      const Rect.fromLTWH(0, 0, 315, 275),
      const Color(0xFF356F99),
      radius: 5,
    );
    for (var x = 24.0; x < 315; x += 30) {
      line(canvas, Offset(x, 18), Offset(x, 255), const Color(0xFF5688AB), 2);
    }
    for (var y = 26.0; y < 265; y += 30) {
      line(canvas, Offset(10, y), Offset(300, y), const Color(0xFF5688AB), 2);
    }
    const chalk = Color(0xFFE4F4F5);
    line(canvas, const Offset(67, 177), const Offset(285, 177), chalk, 7);
    line(canvas, const Offset(95, 91), const Offset(95, 215), chalk, 7);
    line(canvas, const Offset(258, 91), const Offset(258, 215), chalk, 7);
    stroke(
      canvas,
      Path()
        ..moveTo(70, 160)
        ..lineTo(95, 99)
        ..quadraticBezierTo(176, 215, 258, 99)
        ..lineTo(284, 160),
      chalk,
      5,
    );
    for (final point in [
      const Offset(126, 137),
      const Offset(159, 154),
      const Offset(193, 154),
      const Offset(226, 136),
    ]) {
      line(canvas, point, Offset(point.dx, 177), chalk, 4);
    }
    rounded(
      canvas,
      const Rect.fromLTWH(5, -9, 309, 22),
      const Color(0xFFDAE7DE),
      radius: 11,
    );
    canvas.drawOval(
      const Rect.fromLTWH(298, -9, 21, 22),
      Paint()..color = const Color(0xFF9DB8BD),
    );
    canvas.restore();
  }

  void _planningBoard(Canvas canvas) {
    canvas.save();
    canvas.translate(857, 680);
    canvas.rotate(.05);
    rounded(
      canvas,
      const Rect.fromLTWH(0, 0, 308, 292),
      const Color(0xFF386C78),
    );
    rounded(
      canvas,
      const Rect.fromLTWH(14, 17, 280, 257),
      const Color(0xFFE8F1EF),
    );
    const colors = [Color(0xFF599C9E), Color(0xFFE3AE6C), Color(0xFF9989B8)];
    for (var column = 0; column < 3; column++) {
      final x = 35.0 + column * 83;
      rounded(canvas, Rect.fromLTWH(x, 35, 62, 13), colors[column], radius: 4);
      for (var row = 0; row < 3 - column; row++) {
        rounded(
          canvas,
          Rect.fromLTWH(x, 67.0 + row * 64, 62, 46),
          colors[column].withValues(alpha: .75),
          radius: 5,
        );
      }
    }
    canvas.restore();
  }

  void _calculator(Canvas canvas) {
    canvas.save();
    canvas.translate(904, 682);
    canvas.rotate(.06);
    rounded(
      canvas,
      const Rect.fromLTWH(0, 0, 219, 300),
      const Color(0xFF324C60),
      radius: 21,
    );
    rounded(
      canvas,
      const Rect.fromLTWH(20, 20, 179, 67),
      const Color(0xFFB6CEBC),
      radius: 7,
    );
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 3; column++) {
        rounded(
          canvas,
          Rect.fromLTWH(22.0 + column * 62, 109.0 + row * 43, 49, 31),
          column == 2 ? const Color(0xFFDDA76E) : const Color(0xFFD2DEE1),
          radius: 6,
        );
      }
    }
    canvas.restore();
  }

  void _openBook(Canvas canvas) {
    canvas.save();
    canvas.translate(105, 815);
    canvas.rotate(-.07);
    final pages = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(74, -21, 142, 14)
      ..quadraticBezierTo(213, -21, 284, 0)
      ..lineTo(284, 184)
      ..quadraticBezierTo(211, 171, 142, 202)
      ..quadraticBezierTo(74, 171, 0, 184)
      ..close();
    fill(canvas, pages, const Color(0xFFFFF2D6));
    stroke(canvas, pages, const Color(0xFFB37855), 8);
    line(
      canvas,
      const Offset(142, 17),
      const Offset(142, 196),
      const Color(0xFFCFB78C),
      4,
    );
    for (var i = 0; i < 4; i++) {
      line(
        canvas,
        Offset(23, 45.0 + i * 31),
        Offset(116, 54.0 + i * 31),
        const Color(0xFFBEAD8D),
        4,
      );
    }
    canvas.restore();
  }

  void _chalkboard(Canvas canvas) {
    canvas.save();
    canvas.translate(855, 700);
    canvas.rotate(.04);
    rounded(
      canvas,
      const Rect.fromLTWH(0, 0, 303, 254),
      const Color(0xFFBA8B5D),
    );
    rounded(
      canvas,
      const Rect.fromLTWH(15, 15, 273, 224),
      const Color(0xFF346F64),
      radius: 4,
    );
    canvas.drawCircle(
      const Offset(126, 79),
      32,
      Paint()..color = const Color(0xFFF5D67A),
    );
    stroke(
      canvas,
      Path()
        ..moveTo(212, 45)
        ..lineTo(254, 112)
        ..lineTo(173, 112)
        ..close(),
      const Color(0xFFFAEBDD),
      6,
    );
    rounded(
      canvas,
      const Rect.fromLTWH(105, 146, 72, 66),
      const Color(0xFF88BEC7),
      radius: 2,
    );
    line(
      canvas,
      const Offset(218, 168),
      const Offset(260, 168),
      const Color(0xFFFAEBDD),
      6,
    );
    line(
      canvas,
      const Offset(239, 146),
      const Offset(239, 190),
      const Color(0xFFFAEBDD),
      6,
    );
    canvas.restore();
  }

  void _drawingTablet(Canvas canvas) {
    canvas.save();
    canvas.translate(854, 710);
    canvas.rotate(.05);
    rounded(
      canvas,
      const Rect.fromLTWH(0, 0, 293, 255),
      const Color(0xFF45415D),
      radius: 19,
    );
    rounded(
      canvas,
      const Rect.fromLTWH(21, 20, 249, 211),
      const Color(0xFFECE5F2),
      radius: 9,
    );
    stroke(
      canvas,
      Path()
        ..moveTo(86, 172)
        ..cubicTo(111, 56, 217, 53, 234, 158),
      const Color(0xFF9976B5),
      10,
    );
    line(
      canvas,
      const Offset(86, 172),
      const Offset(117, 70),
      const Color(0xFFB4A4BB),
      3,
    );
    line(
      canvas,
      const Offset(234, 158),
      const Offset(209, 67),
      const Color(0xFFB4A4BB),
      3,
    );
    for (final p in [const Offset(86, 172), const Offset(234, 158)]) {
      rounded(
        canvas,
        Rect.fromCenter(center: p, width: 14, height: 14),
        const Color(0xFF9976B5),
        radius: 1,
      );
    }
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(133.0 + i * 39, 198),
        12,
        Paint()
          ..color = const [
            Color(0xFFE89E85),
            Color(0xFF74BDB8),
            Color(0xFFCC9FC6),
          ][i],
      );
    }
    // Stylus runs beside the tablet and ends near the original hand.
    line(
      canvas,
      const Offset(300, 17),
      const Offset(275, 220),
      const Color(0xFF664C78),
      14,
    );
    fill(
      canvas,
      Path()
        ..moveTo(269, 213)
        ..lineTo(281, 215)
        ..lineTo(272, 242)
        ..close(),
      const Color(0xFFC5C3CF),
    );
    canvas.restore();
  }

  void _confetti(Canvas canvas) {
    const pieces = <(double, double, double, Color)>[
      (75, 140, -.28, Color(0xFFFFBE31)),
      (125, 355, .32, Color(0xFF42BBA1)),
      (75, 590, -.45, Color(0xFFFD7587)),
      (200, 70, .27, Color(0xFF6B9FED)),
      (1060, 55, .39, Color(0xFFFFBE31)),
      (1150, 250, -.36, Color(0xFF42BBA1)),
      (1080, 485, .25, Color(0xFFFD7587)),
      (1165, 650, -.21, Color(0xFF8C81DE)),
      (145, 1080, .33, Color(0xFF8C81DE)),
      (1115, 1110, -.3, Color(0xFFFFBE31)),
    ];
    for (final (x, y, angle, color) in pieces) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-9, -19, 18, 38),
          const Radius.circular(4),
        ),
        Paint()..color = color,
      );
      canvas.restore();
    }
  }

  void _laptop(Canvas canvas) {
    // Present the laptop just behind the original right hand. The hand stays
    // entirely in the canonical PNG; no replacement fingers are drawn.
    canvas.save();
    canvas.translate(-70, -20);
    canvas.scale(1.02);
    final screen = Path()
      ..moveTo(908, 672)
      ..lineTo(1193, 705)
      ..lineTo(1168, 928)
      ..lineTo(882, 895)
      ..close();
    fill(canvas, screen, const Color(0xFF193657));
    stroke(canvas, screen, const Color(0xFF75DCE3), 11);
    final glass = Path()
      ..moveTo(929, 698)
      ..lineTo(1164, 725)
      ..lineTo(1147, 894)
      ..lineTo(912, 869)
      ..close();
    fill(canvas, glass, const Color(0xFF225E81));
    // Abstract code geometry: no letters or embedded text.
    stroke(
      canvas,
      Path()
        ..moveTo(1039, 761)
        ..lineTo(1006, 789)
        ..lineTo(1036, 819),
      const Color(0xFFA8F2DD),
      12,
    );
    stroke(
      canvas,
      Path()
        ..moveTo(1100, 769)
        ..lineTo(1132, 799)
        ..lineTo(1098, 828),
      const Color(0xFFA8F2DD),
      12,
    );
    stroke(
      canvas,
      Path()
        ..moveTo(1078, 748)
        ..lineTo(1058, 842),
      const Color(0xFFFFD77D),
      9,
    );
    final base = Path()
      ..moveTo(883, 901)
      ..lineTo(1169, 933)
      ..lineTo(1205, 970)
      ..lineTo(880, 936)
      ..close();
    fill(canvas, base, const Color(0xFF102A48));
    stroke(canvas, base, const Color(0xFF75DCE3), 7);
    canvas.restore();
  }

  void _notebook(Canvas canvas) {
    // The canonical left hand overlaps the notebook edge in the middle layer.
    canvas.save();
    canvas.translate(50, 0);
    final cover = Path()
      ..moveTo(74, 755)
      ..lineTo(330, 785)
      ..lineTo(309, 1018)
      ..lineTo(52, 985)
      ..close();
    fill(canvas, cover, const Color(0xFF80684A));
    stroke(canvas, cover, const Color(0xFF384C3F), 9);
    final paper = Path()
      ..moveTo(90, 776)
      ..lineTo(309, 802)
      ..lineTo(292, 986)
      ..lineTo(73, 960)
      ..close();
    fill(canvas, paper, const Color(0xFFF8F1D8));
    for (var index = 0; index < 4; index++) {
      stroke(
        canvas,
        Path()
          ..moveTo(111, 825 + index * 32)
          ..lineTo(265, 842 + index * 32),
        const Color(0xFF9CB5A2),
        5,
      );
    }
    stroke(
      canvas,
      Path()
        ..moveTo(95, 775)
        ..lineTo(75, 971),
      const Color(0xFF354C42),
      11,
    );
    for (var index = 0; index < 5; index++) {
      canvas.drawCircle(
        Offset(94, 810 + index * 32),
        5,
        Paint()..color = const Color(0xFFB9C8B5),
      );
    }
    canvas.restore();
  }

  void _plant(Canvas canvas) {
    canvas.save();
    canvas.translate(160, 160);
    canvas.scale(.82);
    final pot = Path()
      ..moveTo(955, 842)
      ..lineTo(1138, 842)
      ..lineTo(1118, 1006)
      ..quadraticBezierTo(1045, 1043, 974, 1006)
      ..close();
    fill(canvas, pot, const Color(0xFFB76F4E));
    stroke(canvas, pot, const Color(0xFF754B3E), 9);
    fill(
      canvas,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(940, 826, 213, 30),
          const Radius.circular(13),
        ),
      ),
      const Color(0xFFC8885C),
    );
    stroke(
      canvas,
      Path()
        ..moveTo(1047, 827)
        ..cubicTo(1010, 716, 1050, 653, 1031, 568),
      const Color(0xFF487A55),
      17,
    );
    final leaves = <Path>[
      Path()
        ..moveTo(1020, 730)
        ..quadraticBezierTo(905, 686, 917, 623)
        ..quadraticBezierTo(1002, 628, 1020, 730),
      Path()
        ..moveTo(1038, 668)
        ..quadraticBezierTo(1152, 617, 1138, 550)
        ..quadraticBezierTo(1050, 561, 1038, 668),
      Path()
        ..moveTo(1031, 583)
        ..quadraticBezierTo(971, 496, 1014, 450)
        ..quadraticBezierTo(1082, 507, 1031, 583),
    ];
    for (final leaf in leaves) {
      fill(canvas, leaf, const Color(0xFF60A36A));
      stroke(canvas, leaf, const Color(0xFF32744C), 7);
    }
    canvas.restore();
  }
}

class _SabiGarmentPainter extends _SabiOverlayPainter {
  const _SabiGarmentPainter(super.profession);

  @override
  void drawOverlay(Canvas canvas, Size size) {
    switch (profession) {
      case SabiProfession.medicine:
        _coat(canvas);
      case SabiProfession.nursing:
        _openJacket(
          canvas,
          const Color(0xFF8AC9CA),
          const Color(0xFF438C98),
          const Color(0xFFD0ECE5),
          hem: 876,
          lapels: false,
        );
        _pocket(
          canvas,
          const Rect.fromLTWH(451, 785, 55, 53),
          const Color(0xFFB7DEDA),
          const Color(0xFF438C98),
        );
      case SabiProfession.psychology:
        _openJacket(
          canvas,
          const Color(0xFFA993BC),
          const Color(0xFF77688F),
          const Color(0xFFD8C5DC),
          hem: 925,
          lapels: false,
        );
        _buttons(canvas, const Color(0xFFEAD2AA), 844);
      case SabiProfession.law:
        _openJacket(
          canvas,
          const Color(0xFF424C67),
          const Color(0xFF2A3650),
          const Color(0xFF748095),
          hem: 955,
        );
        _buttons(canvas, const Color(0xFFCEB67B), 853);
      case SabiProfession.software:
        break; // The canonical S+ shirt remains entirely visible.
      case SabiProfession.industrialEngineering:
        _technicalVest(
          canvas,
          const Color(0xFFED9953),
          const Color(0xFF9E623B),
          const Color(0xFFF7EAC5),
        );
      case SabiProfession.civilEngineering:
        _technicalVest(
          canvas,
          const Color(0xFFDFCC66),
          const Color(0xFF8D854F),
          const Color(0xFFE9EBD2),
        );
        _pocket(
          canvas,
          const Rect.fromLTWH(452, 822, 56, 54),
          const Color(0xFF456A81),
          const Color(0xFF314D65),
        );
        _pocket(
          canvas,
          const Rect.fromLTWH(719, 822, 50, 54),
          const Color(0xFF456A81),
          const Color(0xFF314D65),
        );
      case SabiProfession.administration:
        _openJacket(
          canvas,
          const Color(0xFF538391),
          const Color(0xFF355C70),
          const Color(0xFF99BEBB),
          hem: 887,
        );
        line(
          canvas,
          const Offset(452, 798),
          const Offset(498, 798),
          const Color(0xFFC5D8D1),
          6,
        );
      case SabiProfession.accounting:
        _waistcoat(canvas, const Color(0xFF98616B), const Color(0xFF603F50));
      case SabiProfession.education:
        _openJacket(
          canvas,
          const Color(0xFFD3A364),
          const Color(0xFF9B774F),
          const Color(0xFFEFD4A7),
          hem: 925,
          lapels: false,
        );
        _pocket(
          canvas,
          const Rect.fromLTWH(447, 816, 61, 65),
          const Color(0xFFE1BA80),
          const Color(0xFF9B774F),
        );
        _pocket(
          canvas,
          const Rect.fromLTWH(719, 816, 50, 65),
          const Color(0xFFE1BA80),
          const Color(0xFF9B774F),
        );
      case SabiProfession.design:
        _openJacket(
          canvas,
          const Color(0xFF927196),
          const Color(0xFF674F74),
          const Color(0xFFC5A9BE),
          hem: 909,
        );
        // A contrasting utility pocket and pen loops, entirely on the garment.
        _pocket(
          canvas,
          const Rect.fromLTWH(446, 791, 61, 78),
          const Color(0xFFE0B58D),
          const Color(0xFF674F74),
        );
        for (final x in [459.0, 478.0]) {
          line(
            canvas,
            Offset(x, 808),
            Offset(x + 5, 757),
            const Color(0xFF455566),
            7,
          );
        }
      case SabiProfession.environmentalAgro:
        _fieldJacket(canvas);
    }
  }

  // Shared tailoring for the new professions only. The approved D2A painters
  // remain unchanged. Open fronts preserve the original printed S+.
  void _openJacket(
    Canvas canvas,
    Color fabric,
    Color edge,
    Color lining, {
    required double hem,
    bool lapels = true,
  }) {
    final left = Path()
      ..moveTo(506, 589)
      ..cubicTo(447, 604, 402, 650, 377, 701)
      ..lineTo(431, 737)
      ..lineTo(431, 844)
      ..lineTo(426, hem - 17)
      ..quadraticBezierTo(468, hem + 9, 522, hem)
      ..lineTo(529, 648)
      ..close();
    final right = Path()
      ..moveTo(713, 589)
      ..cubicTo(775, 606, 810, 650, 837, 701)
      ..lineTo(781, 738)
      ..lineTo(774, 847)
      ..lineTo(778, hem - 17)
      ..quadraticBezierTo(742, hem + 9, 709, hem)
      ..lineTo(701, 648)
      ..close();
    for (final panel in [left, right]) {
      fill(canvas, panel, fabric);
      stroke(canvas, panel, edge, 7);
    }
    if (lapels) {
      fill(
        canvas,
        Path()
          ..moveTo(506, 590)
          ..lineTo(529, 648)
          ..lineTo(512, 747)
          ..lineTo(463, 683)
          ..lineTo(481, 668)
          ..lineTo(461, 648)
          ..close(),
        lining,
      );
      fill(
        canvas,
        Path()
          ..moveTo(713, 590)
          ..lineTo(701, 648)
          ..lineTo(721, 747)
          ..lineTo(766, 683)
          ..lineTo(748, 668)
          ..lineTo(768, 648)
          ..close(),
        lining,
      );
    } else {
      stroke(
        canvas,
        Path()
          ..moveTo(506, 591)
          ..quadraticBezierTo(529, 628, 525, 674)
          ..lineTo(520, hem - 4),
        lining,
        13,
      );
      stroke(
        canvas,
        Path()
          ..moveTo(713, 591)
          ..quadraticBezierTo(699, 627, 706, 674)
          ..lineTo(711, hem - 4),
        lining,
        13,
      );
      line(canvas, const Offset(383, 699), const Offset(429, 730), lining, 10);
      line(canvas, const Offset(829, 699), const Offset(785, 730), lining, 10);
    }
  }

  void _pocket(Canvas canvas, Rect rect, Color fabric, Color edge) {
    rounded(canvas, rect, fabric, radius: 5);
    stroke(
      canvas,
      Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.left, rect.bottom - 8)
        ..quadraticBezierTo(
          rect.center.dx,
          rect.bottom + 6,
          rect.right,
          rect.bottom - 8,
        )
        ..lineTo(rect.right, rect.top),
      edge,
      4,
    );
    line(
      canvas,
      Offset(rect.left + 2, rect.top + 10),
      Offset(rect.right - 2, rect.top + 10),
      edge,
      3,
    );
  }

  void _buttons(Canvas canvas, Color color, double y) {
    for (var i = 0; i < 2; i++) {
      canvas.drawCircle(Offset(725, y + i * 34), 5, Paint()..color = color);
    }
  }

  void _technicalVest(
    Canvas canvas,
    Color fabric,
    Color edge,
    Color reflective,
  ) {
    final left = Path()
      ..moveTo(505, 589)
      ..lineTo(453, 613)
      ..quadraticBezierTo(479, 686, 443, 749)
      ..lineTo(434, 901)
      ..lineTo(524, 912)
      ..lineTo(529, 647)
      ..close();
    final right = Path()
      ..moveTo(713, 589)
      ..lineTo(762, 613)
      ..quadraticBezierTo(739, 686, 777, 749)
      ..lineTo(783, 901)
      ..lineTo(708, 912)
      ..lineTo(702, 647)
      ..close();
    for (final panel in [left, right]) {
      fill(canvas, panel, fabric);
      stroke(canvas, panel, edge, 7);
      canvas.save();
      canvas.clipPath(panel);
      for (final y in [754.0, 880.0]) {
        rounded(canvas, Rect.fromLTWH(430, y, 360, 21), reflective, radius: 0);
      }
      canvas.restore();
    }
    line(
      canvas,
      const Offset(485, 616),
      const Offset(480, 743),
      reflective,
      17,
    );
    line(
      canvas,
      const Offset(736, 616),
      const Offset(739, 743),
      reflective,
      17,
    );
  }

  void _waistcoat(Canvas canvas, Color fabric, Color edge) {
    final left = Path()
      ..moveTo(505, 589)
      ..lineTo(454, 616)
      ..quadraticBezierTo(477, 686, 447, 740)
      ..lineTo(440, 883)
      ..lineTo(487, 931)
      ..lineTo(526, 895)
      ..lineTo(529, 649)
      ..close();
    final right = Path()
      ..moveTo(713, 589)
      ..lineTo(761, 616)
      ..quadraticBezierTo(740, 686, 775, 740)
      ..lineTo(781, 883)
      ..lineTo(742, 931)
      ..lineTo(706, 895)
      ..lineTo(701, 649)
      ..close();
    for (final panel in [left, right]) {
      fill(canvas, panel, fabric);
      stroke(canvas, panel, edge, 7);
    }
    line(
      canvas,
      const Offset(457, 816),
      const Offset(503, 812),
      const Color(0xFFD8B4B4),
      5,
    );
    line(
      canvas,
      const Offset(721, 812),
      const Offset(762, 816),
      const Color(0xFFD8B4B4),
      5,
    );
    _buttons(canvas, const Color(0xFFDFCCD1), 850);
  }

  void _coat(Canvas canvas) {
    final left = Path()
      ..moveTo(505, 589)
      ..cubicTo(442, 601, 405, 638, 373, 703)
      ..lineTo(433, 742)
      ..lineTo(432, 848)
      ..lineTo(421, 1010)
      ..quadraticBezierTo(470, 1037, 530, 1020)
      ..lineTo(531, 650)
      ..close();
    final right = Path()
      ..moveTo(713, 588)
      ..cubicTo(774, 603, 810, 644, 840, 702)
      ..lineTo(784, 742)
      ..lineTo(769, 850)
      ..lineTo(778, 1010)
      ..quadraticBezierTo(747, 1035, 704, 1020)
      ..lineTo(701, 649)
      ..close();
    for (final panel in [left, right]) {
      fill(canvas, panel, const Color(0xFFF5FAFF));
      stroke(canvas, panel, const Color(0xFFB6C9D5), 7);
    }
    stroke(
      canvas,
      Path()
        ..moveTo(504, 591)
        ..quadraticBezierTo(444, 616, 403, 692),
      const Color(0xFFD2E0E9),
      5,
    );
    stroke(
      canvas,
      Path()
        ..moveTo(714, 591)
        ..quadraticBezierTo(780, 620, 809, 692),
      const Color(0xFFD2E0E9),
      5,
    );
    fill(
      canvas,
      Path()
        ..moveTo(505, 590)
        ..lineTo(530, 650)
        ..lineTo(509, 738)
        ..lineTo(470, 670)
        ..close(),
      const Color(0xFFE1EDF4),
    );
    fill(
      canvas,
      Path()
        ..moveTo(713, 590)
        ..lineTo(701, 650)
        ..lineTo(734, 739)
        ..lineTo(754, 670)
        ..close(),
      const Color(0xFFE1EDF4),
    );
    // Stethoscope lives on the coat panel, outside the canonical S+.
    stroke(
      canvas,
      Path()
        ..moveTo(709, 596)
        ..quadraticBezierTo(731, 614, 744, 635),
      const Color(0xFF344D61),
      9,
    );
    stroke(
      canvas,
      Path()
        ..moveTo(744, 635)
        ..cubicTo(774, 689, 777, 784, 739, 819)
        ..cubicTo(714, 842, 691, 808, 702, 762),
      const Color(0xFF344D61),
      13,
    );
    canvas.drawCircle(
      const Offset(737, 819),
      25,
      Paint()..color = const Color(0xFF455A6B),
    );
    canvas.drawCircle(
      const Offset(737, 819),
      15,
      Paint()..color = const Color(0xFFD5E6EF),
    );
    // Lower patch pockets make the long coat distinct from the field vest.
    for (final rect in [
      const Rect.fromLTWH(448, 902, 59, 69),
      const Rect.fromLTWH(720, 902, 41, 69),
    ]) {
      final pocket = Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.bottom - 9)
        ..quadraticBezierTo(
          rect.center.dx,
          rect.bottom + 9,
          rect.left,
          rect.bottom - 9,
        )
        ..close();
      fill(canvas, pocket, const Color(0xFFE7F0F6));
      stroke(canvas, pocket, const Color(0xFFB6C9D5), 4);
      stroke(
        canvas,
        Path()
          ..moveTo(rect.left + 4, rect.top + 8)
          ..lineTo(rect.right - 4, rect.top + 8),
        const Color(0xFFFFFFFF),
        3,
      );
    }
  }

  void _fieldJacket(Canvas canvas) {
    final left = Path()
      ..moveTo(506, 589)
      ..lineTo(456, 612)
      ..quadraticBezierTo(479, 684, 446, 750)
      ..lineTo(437, 897)
      ..quadraticBezierTo(475, 921, 523, 908)
      ..lineTo(527, 649)
      ..close();
    final right = Path()
      ..moveTo(713, 589)
      ..lineTo(760, 612)
      ..quadraticBezierTo(740, 685, 773, 750)
      ..lineTo(781, 897)
      ..quadraticBezierTo(747, 921, 708, 908)
      ..lineTo(704, 650)
      ..close();
    for (final panel in [left, right]) {
      fill(canvas, panel, const Color(0xFF63806B));
      stroke(canvas, panel, const Color(0xFF3E5E50), 8);
    }
    stroke(
      canvas,
      Path()
        ..moveTo(456, 613)
        ..quadraticBezierTo(479, 684, 446, 750),
      const Color(0xFFC0B88B),
      9,
    );
    stroke(
      canvas,
      Path()
        ..moveTo(760, 613)
        ..quadraticBezierTo(740, 685, 773, 750),
      const Color(0xFFC0B88B),
      9,
    );
    fill(
      canvas,
      Path()
        ..moveTo(506, 590)
        ..lineTo(527, 649)
        ..lineTo(511, 737)
        ..lineTo(465, 661)
        ..close(),
      const Color(0xFF9EAD80),
    );
    fill(
      canvas,
      Path()
        ..moveTo(713, 590)
        ..lineTo(704, 650)
        ..lineTo(735, 738)
        ..lineTo(754, 665)
        ..close(),
      const Color(0xFF9EAD80),
    );
    for (final rect in [
      const Rect.fromLTWH(452, 807, 58, 70),
      const Rect.fromLTWH(722, 807, 46, 70),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = const Color(0xFF7F9B79),
      );
      stroke(
        canvas,
        Path()
          ..moveTo(rect.left, rect.top + 18)
          ..lineTo(rect.center.dx, rect.top + 26)
          ..lineTo(rect.right, rect.top + 18),
        const Color(0xFF375A4A),
        4,
      );
      canvas.drawCircle(
        Offset(rect.center.dx, rect.top + 14),
        4,
        Paint()..color = const Color(0xFFD4CAA0),
      );
    }
  }
}
