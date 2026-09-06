import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/widgets/animated_streak_flame.dart';

void main() {
  testWidgets('la llama se mueve y termina sin dejar animaciones activas', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: AnimatedStreakFlame(
            key: Key('test-flame'),
            color: Colors.orange,
          ),
        ),
      ),
    );
    final before = _firstTransform(tester);

    await tester.pump(const Duration(milliseconds: 225));
    final during = _firstTransform(tester);

    expect(during, isNot(equals(before)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('streak-flame-art')), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('respeta la preferencia de reducir movimiento', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: AnimatedStreakFlame(
              key: Key('test-flame'),
              color: Colors.orange,
            ),
          ),
        ),
      ),
    );
    final before = _firstTransform(tester);

    await tester.pump(const Duration(milliseconds: 225));

    expect(_firstTransform(tester), equals(before));
  });

  testWidgets('repite el movimiento mientras la racha está activa', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: AnimatedStreakFlame(
            key: Key('test-flame'),
            color: Colors.orange,
            continuous: true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 2500));
    final resting = _painter(tester);

    await tester.pump(const Duration(milliseconds: 180));
    await tester.pump(const Duration(milliseconds: 225));

    expect(_painter(tester).shouldRepaint(resting), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('pausa fuera de la pantalla aunque el widget siga montado', (
    tester,
  ) async {
    final scroll = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            height: 200,
            child: SingleChildScrollView(
              controller: scroll,
              child: Column(
                children: const [
                  Center(
                    child: AnimatedStreakFlame(
                      color: Colors.orange,
                      size: 100,
                      continuous: true,
                    ),
                  ),
                  SizedBox(height: 1600),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    scroll.jumpTo(350);
    await tester.pump();
    await tester.pump();
    expect(find.byType(AnimatedStreakFlame), findsOneWidget);
    final hidden = _painter(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(_painter(tester).shouldRepaint(hidden), isFalse);
    expect(tester.binding.transientCallbackCount, 0);
    scroll.jumpTo(0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(_painter(tester).shouldRepaint(hidden), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    scroll.dispose();
  });

  testWidgets('detiene el fuego al ocultar la ruta y lo reanuda', (
    tester,
  ) async {
    Future<void> show(bool visible) => tester.pumpWidget(
      MaterialApp(
        home: TickerMode(
          enabled: visible,
          child: const AnimatedStreakFlame(
            color: Colors.orange,
            continuous: true,
          ),
        ),
      ),
    );
    await show(true);
    await tester.pump(const Duration(seconds: 3));
    await show(false);
    await tester.pump();
    final hidden = _painter(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(_painter(tester).shouldRepaint(hidden), isFalse);
    expect(tester.binding.transientCallbackCount, 0);
    await show(true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_painter(tester).shouldRepaint(hidden), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'pausa al pasar al fondo y respeta movimiento reducido en caliente',
    (tester) async {
      Future<void> show(bool reduced) => tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const AnimatedStreakFlame(
              color: Colors.orange,
              continuous: true,
            ),
          ),
        ),
      );
      await show(false);
      await tester.pump(const Duration(seconds: 3));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      final paused = _painter(tester);
      await tester.pump(const Duration(seconds: 4));
      expect(_painter(tester).shouldRepaint(paused), isFalse);
      expect(tester.binding.transientCallbackCount, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(_painter(tester).shouldRepaint(paused), isTrue);
      await show(true);
      await tester.pumpAndSettle();
      final reduced = _painter(tester);
      await tester.pump(const Duration(seconds: 4));
      expect(_painter(tester).shouldRepaint(reduced), isFalse);
      expect(tester.binding.transientCallbackCount, 0);
    },
  );

  testWidgets(
    'hielo y brasa permanecen estáticos aunque se solicite repetición',
    (tester) async {
      for (final appearance in [
        StreakFlameAppearance.frozen,
        StreakFlameAppearance.extinguished,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: AnimatedStreakFlame(
              color: Colors.blue,
              appearance: appearance,
              continuous: true,
              semanticLabel: 'Racha de prueba',
            ),
          ),
        );
        final before = _painter(tester);
        await tester.pump(const Duration(seconds: 4));
        expect(_painter(tester).shouldRepaint(before), isFalse);
        expect(tester.binding.transientCallbackCount, 0);
        expect(find.bySemanticsLabel('Racha de prueba'), findsOneWidget);
      }
    },
  );

  testWidgets(
    'cambiar de nivel enciende la llama y conserva el tamaño del diseño',
    (tester) async {
      Future<void> show(Color color) => tester.pumpWidget(
        MaterialApp(
          home: Center(child: AnimatedStreakFlame(color: color, size: 100)),
        ),
      );
      await show(Colors.orange);
      await tester.pumpAndSettle();
      final oldColor = _painter(tester);
      await show(Colors.purple);
      await tester.pump(const Duration(milliseconds: 350));
      expect(_painter(tester).shouldRepaint(oldColor), isTrue);
      expect(
        tester.getSize(find.byKey(const Key('streak-flame-art'))),
        const Size.square(100),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}

CustomPainter _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.byKey(const Key('streak-flame-art')))
    .painter!;

List<double> _firstTransform(WidgetTester tester) {
  final flame = find.byKey(const Key('test-flame'));
  final transform = tester.widget<Transform>(
    find.descendant(of: flame, matching: find.byType(Transform)).last,
  );
  return List<double>.of(transform.transform.storage);
}
