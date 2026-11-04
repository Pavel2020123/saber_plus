import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/domain/personal_return_eligibility.dart';
import 'package:saber_plus/features/institutions/presentation/personal_return_page.dart';

void main() {
  PersonalReturnEligibility decision({bool managed = false}) =>
      PersonalReturnEligibility.fromJson({
        'puedeVolver': !managed,
        'gestionada': managed,
        'asignacionId': 'assignment',
        'versionAsignacion': '2026-11-03T12:00:00.000Z',
      });

  testWidgets('managed account has no personal-return command', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PersonalReturnBoard(
          load: () async => decision(managed: true),
          submit: (_, _) async => fail('Managed account must not submit'),
          refreshSession: () async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Volver a modalidad personal'), findsNothing);
    expect(find.textContaining('creada por el colegio'), findsOneWidget);
  });

  testWidgets('cancel confirmation sends no request', (tester) async {
    var submissions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PersonalReturnBoard(
          load: () async => decision(),
          submit: (_, _) async {
            submissions++;
          },
          refreshSession: () async => true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver a modalidad personal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(submissions, 0);
  });

  testWidgets('uncertain response cannot automatically repeat command', (
    tester,
  ) async {
    var submissions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PersonalReturnBoard(
          load: () async => decision(),
          submit: (_, _) async {
            submissions++;
            throw Exception('timeout');
          },
          refreshSession: () async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver a modalidad personal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar salida'));
    await tester.pumpAndSettle();
    expect(submissions, 1);
    expect(find.text('Volver a modalidad personal'), findsNothing);
    expect(find.text('Actualizar mi perfil'), findsOneWidget);
  });
}
