import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/app.dart';

void main() {
  testWidgets('muestra la bienvenida de SaberPlus', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SaberPlusApp()));

    expect(find.text('SaberPlus'), findsOneWidget);
    expect(find.text('Comenzar'), findsOneWidget);
    expect(find.textContaining('Tu preparación ICFES'), findsOneWidget);
  });

  testWidgets('permite entrar al dashboard demostrativo', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SaberPlusApp()));

    await tester.ensureVisible(find.text('Comenzar'));
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();
    expect(find.text('Qué bueno verte'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('student-demo-button')));
    await tester.tap(find.byKey(const Key('student-demo-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hola, Santiago'), findsOneWidget);
    expect(find.text('Refuerzo de matemáticas'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
  });
}
