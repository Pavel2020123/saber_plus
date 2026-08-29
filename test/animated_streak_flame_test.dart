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
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
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
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 900));
    final resting = _firstTransform(tester);

    await tester.pump(const Duration(milliseconds: 180));
    await tester.pump(const Duration(milliseconds: 225));

    expect(_firstTransform(tester), isNot(equals(resting)));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

List<double> _firstTransform(WidgetTester tester) {
  final flame = find.byKey(const Key('test-flame'));
  final transform = tester.widget<Transform>(
    find.descendant(of: flame, matching: find.byType(Transform)).last,
  );
  return List<double>.of(transform.transform.storage);
}
