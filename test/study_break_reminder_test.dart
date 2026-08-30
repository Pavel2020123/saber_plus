import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/wellbeing/study_break_reminder.dart';

void main() {
  testWidgets('sugiere y cronometra un descanso de tres minutos', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StudyBreakReminder(
            reminderAfter: Duration(seconds: 2),
            breakDuration: Duration(minutes: 3),
            child: Text('Contenido de estudio'),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('study-break-dialog')), findsOneWidget);
    expect(find.text('¿Y si descansas?'), findsOneWidget);
    expect(find.textContaining('toma agua'), findsOneWidget);

    await tester.tap(find.byKey(const Key('start-study-break')));
    await tester.pump();
    expect(find.text('03:00'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('02:59'), findsOneWidget);
    await tester.tap(find.byKey(const Key('finish-study-break-early')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('study-break-dialog')), findsNothing);
  });

  test('formatea el contador sin aceptar valores negativos', () {
    expect(formatBreakDuration(180), '03:00');
    expect(formatBreakDuration(0), '00:00');
    expect(formatBreakDuration(-4), '00:00');
  });
}
