import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('los 14 iconos aprobados pertenecen a Lucide y se renderizan', (
    tester,
  ) async {
    const approved = [
      LucideIcons.house,
      LucideIcons.bookOpenText,
      LucideIcons.gamepad2,
      LucideIcons.chartArea,
      LucideIcons.menu,
      LucideIcons.slidersHorizontal,
      LucideIcons.zap,
      LucideIcons.clipboardCheck,
      LucideIcons.timer,
      LucideIcons.school,
      LucideIcons.userRound,
      LucideIcons.crown,
      LucideIcons.play,
      LucideIcons.arrowRight,
    ];
    expect(approved.toSet(), hasLength(14));
    for (final icon in approved) {
      expect(icon.fontFamily, 'Lucide');
      expect(icon.fontPackage, 'lucide_icons_flutter');
    }
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(children: [for (final icon in approved) Icon(icon)]),
        ),
      ),
    );
    for (final icon in approved) {
      expect(find.byIcon(icon), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
