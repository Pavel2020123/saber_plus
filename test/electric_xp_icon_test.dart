import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:saber_plus/features/dashboard/presentation/widgets/electric_xp_icon.dart';

Widget _app({
  bool reduce = false,
  bool ticker = true,
  int xp = 10,
  bool accessible = false,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: reduce,
      accessibleNavigation: accessible,
    ),
    child: TickerMode(
      enabled: ticker,
      child: Scaffold(body: ElectricXpIcon(xp: xp)),
    ),
  ),
);

void main() {
  testWidgets('accessible navigation keeps a static icon', (tester) async {
    await tester.pumpWidget(_app(accessible: true));
    await tester.pump(const Duration(seconds: 10));
    expect(find.byIcon(LucideIcons.zap), findsOneWidget);
    expect(find.byKey(const Key('xp-electric-flow')), findsNothing);
  });

  testWidgets('background pauses pulses and foreground restores them', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(find.byKey(const Key('xp-electric-flow')), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('xp-electric-flow')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Lucide remains and current pulses briefly with a pause', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byIcon(LucideIcons.zap), findsWidgets);
    expect(find.byKey(const Key('xp-electric-flow')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('xp-electric-flow')), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('xp-electric-flow')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  for (final reduce in [false, true]) {
    testWidgets(
      'no pulse with ${reduce ? 'reduced motion' : 'hidden ticker'}',
      (tester) async {
        await tester.pumpWidget(_app(reduce: reduce, ticker: reduce));
        await tester.pump(const Duration(seconds: 6));
        expect(find.byIcon(LucideIcons.zap), findsOneWidget);
        expect(find.byKey(const Key('xp-electric-flow')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('increased XP triggers decoration without changing supplied XP', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(xp: 20));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('xp-electric-flow')), findsOneWidget);
    expect(tester.widget<ElectricXpIcon>(find.byType(ElectricXpIcon)).xp, 20);
  });
}
