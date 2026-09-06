import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/games/memory_match/domain/memory_match_models.dart';
import 'package:saber_plus/features/games/memory_match/presentation/memory_tile_card.dart';

const _tile = MemoryMatchTile(
  id: 'rule-answer',
  pairId: 'rule',
  text: 'x = (b × c) / a',
  isPrompt: false,
);

void main() {
  testWidgets('la cara oculta no revela respuestas al lector de pantalla', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    expect(find.text(_tile.text), findsNothing);
    expect(find.bySemanticsLabel('Tarjeta oculta'), findsOneWidget);
    expect(find.bySemanticsLabel(_tile.text), findsNothing);

    await tester.pumpWidget(_app(revealed: true));
    await tester.pumpAndSettle();
    expect(find.text(_tile.text), findsOneWidget);
    expect(find.bySemanticsLabel(_tile.text), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('el giro muestra perspectiva sin reflejar el texto', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpWidget(_app(revealed: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    var transform = tester
        .widget<Transform>(find.byKey(const Key('memory-card-perspective')))
        .transform;
    expect(transform.entry(0, 0), inExclusiveRange(0, 1));
    expect(find.text(_tile.text), findsNothing);

    await tester.pump(const Duration(milliseconds: 125));
    transform = tester
        .widget<Transform>(find.byKey(const Key('memory-card-perspective')))
        .transform;
    expect(transform.entry(0, 0), inExclusiveRange(0, 1));
    expect(find.text(_tile.text), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('pareja encontrada queda legible y no admite otro toque', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(_app(revealed: true));
    await tester.pumpWidget(_app(matched: true, onTap: () => taps++));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Pareja'), findsOneWidget);
    expect(find.text(_tile.text), findsOneWidget);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
    await tester.tap(find.byType(MemoryTileCard));
    expect(taps, 0);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets(
    'movimiento reducido cambia de cara sin transiciones pendientes',
    (tester) async {
      await tester.pumpWidget(_app(reduceMotion: true));
      await tester.pumpWidget(
        _app(reduceMotion: true, revealed: true, matched: true),
      );
      expect(find.text(_tile.text), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    },
  );

  testWidgets('ocultar la ruta pausa el giro y permite reanudarlo', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpWidget(_app(revealed: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    await tester.pumpWidget(_app(revealed: true, visible: false));
    final paused = tester
        .widget<Transform>(find.byKey(const Key('memory-card-perspective')))
        .transform
        .clone();
    await tester.pump(const Duration(seconds: 3));
    expect(
      tester
          .widget<Transform>(find.byKey(const Key('memory-card-perspective')))
          .transform,
      paused,
    );
    await tester.pumpWidget(_app(revealed: true));
    await tester.pumpAndSettle();
    expect(find.text(_tile.text), findsOneWidget);
  });

  testWidgets('el ciclo de vida pausa y reanuda el giro de carta', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpWidget(_app(revealed: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final paused = tester
        .widget<Transform>(find.byKey(const Key('memory-card-perspective')))
        .transform
        .clone();
    await tester.pump(const Duration(seconds: 3));
    expect(
      tester
          .widget<Transform>(find.byKey(const Key('memory-card-perspective')))
          .transform,
      paused,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text(_tile.text), findsOneWidget);
  });

  testWidgets('texto ampliado cabe en la carta y puede desplazarse', (
    tester,
  ) async {
    await tester.pumpWidget(_app(revealed: true, textScale: 2));
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}

Widget _app({
  bool revealed = false,
  bool matched = false,
  bool reduceMotion = false,
  bool visible = true,
  double textScale = 1,
  VoidCallback? onTap,
}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(
      disableAnimations: reduceMotion,
      textScaler: TextScaler.linear(textScale),
    ),
    child: Scaffold(
      body: TickerMode(
        enabled: visible,
        child: Center(
          child: SizedBox(
            width: 160,
            height: 180,
            child: MemoryTileCard(
              tile: _tile,
              revealed: revealed,
              matched: matched,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    ),
  ),
);
