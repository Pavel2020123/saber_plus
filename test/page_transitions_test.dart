import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/page_transitions.dart';

void main() {
  test('configura tiempos breves para abrir y volver', () {
    final page = saberPage(
      key: const ValueKey('test-page'),
      child: const SizedBox(),
    );

    expect(page.transitionDuration, const Duration(milliseconds: 260));
    expect(page.reverseTransitionDuration, const Duration(milliseconds: 210));
  });

  testWidgets(
    'combina fundido y desplazamiento cuando el movimiento está activo',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SaberPageTransition(
            animation: AlwaysStoppedAnimation(0.5),
            child: SizedBox(key: Key('transition-child')),
          ),
        ),
      );

      final transition = find.byType(SaberPageTransition);
      expect(
        find.descendant(of: transition, matching: find.byType(FadeTransition)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: transition, matching: find.byType(SlideTransition)),
        findsOneWidget,
      );
      expect(find.byKey(const Key('transition-child')), findsOneWidget);
    },
  );

  testWidgets(
    'elimina el movimiento si el sistema solicita reducir animaciones',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: SaberPageTransition(
              animation: AlwaysStoppedAnimation(0.5),
              child: SizedBox(key: Key('reduced-motion-child')),
            ),
          ),
        ),
      );

      final transition = find.byType(SaberPageTransition);
      expect(
        find.descendant(of: transition, matching: find.byType(FadeTransition)),
        findsNothing,
      );
      expect(
        find.descendant(of: transition, matching: find.byType(SlideTransition)),
        findsNothing,
      );
      expect(find.byKey(const Key('reduced-motion-child')), findsOneWidget);
    },
  );
}
