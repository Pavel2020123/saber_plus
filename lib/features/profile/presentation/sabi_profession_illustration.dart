import 'package:flutter/material.dart';

/// The only approved prototypes for OV-1D2A. Other professions await review.
enum SabiProfession { medicine, software, environmentalAgro }

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
      SabiProfession.software => 'Sabi con portátil de software',
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
}

class _SabiBackdropPainter extends _SabiOverlayPainter {
  const _SabiBackdropPainter(super.profession);

  @override
  void drawOverlay(Canvas canvas, Size size) {
    _confetti(canvas);
    switch (profession) {
      case SabiProfession.medicine:
        break;
      case SabiProfession.software:
        _laptop(canvas);
      case SabiProfession.environmentalAgro:
        _notebook(canvas);
        _plant(canvas);
    }
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
      case SabiProfession.software:
        break; // The canonical S+ shirt remains entirely visible.
      case SabiProfession.environmentalAgro:
        _fieldJacket(canvas);
    }
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
