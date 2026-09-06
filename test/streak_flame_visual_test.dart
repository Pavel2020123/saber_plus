import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/widgets/animated_streak_flame.dart';
import 'package:saber_plus/features/gamification/domain/gamification_models.dart';
import 'package:saber_plus/features/gamification/presentation/streak_flame_style.dart';

void main() {
  testWidgets('la ilustración renderiza niveles y estados en claro y oscuro', (
    tester,
  ) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: const Key('flame-gallery'),
              child: ColoredBox(
                color: dark ? const Color(0xFF162133) : const Color(0xFFF9FAFC),
                child: SizedBox(
                  width: 720,
                  height: 420,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final days in [
                        <int>[1, 10, 20, 30],
                        <int>[40, 50, -1, 0],
                      ])
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            for (final day in days)
                              _Preview(day: day, dark: dark),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('flame-gallery')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final pixels = bytes!.buffer.asUint8List();
        final colors = <int>{};
        for (var i = 0; i < pixels.length; i += 4) {
          colors.add((pixels[i] << 16) | (pixels[i + 1] << 8) | pixels[i + 2]);
        }
        // A missing/blank painter would leave only background and text colors.
        expect(colors.length, greaterThan(1000));
        final output = Platform.environment['SABERPLUS_FLAME_QA_DIR'];
        if (output != null && output.isNotEmpty) {
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = await Directory(output).create(recursive: true);
          await File(
            '${directory.path}/flames-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytes(png!.buffer.asUint8List());
        }
        image.dispose();
      });
    }
  });
}

class _Preview extends StatelessWidget {
  const _Preview({required this.day, required this.dark});

  final int day;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final style = StreakFlameStyle.fromStreak(
      StudyStreak(
        current: day == -1 ? 10 : day,
        best: 50,
        activeToday: day > 0,
      ),
      frozenPreview: day == -1,
    );
    return SizedBox(
      width: 160,
      height: 192,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedStreakFlame(
            color: style.color,
            size: 142,
            animate: false,
            appearance: switch (style.state) {
              StreakFlameState.active => StreakFlameAppearance.burning,
              StreakFlameState.frozen => StreakFlameAppearance.frozen,
              StreakFlameState.lost => StreakFlameAppearance.extinguished,
            },
          ),
          Text(
            day > 0 ? '$day días · ${style.levelLabel}' : style.statusLabel,
            style: TextStyle(
              color: dark ? Colors.white : const Color(0xFF273449),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
