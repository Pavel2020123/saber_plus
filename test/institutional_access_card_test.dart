import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/auth/domain/institutional_access.dart';
import 'package:saber_plus/features/auth/presentation/institutional_access_card.dart';

void main() {
  for (final brightness in Brightness.values) {
    for (final state in InstitutionalLicenseState.values) {
      testWidgets(
        '$brightness $state: texto grande sin desbordamiento y acción accesible',
        (tester) async {
          tester.view.physicalSize = const Size(375, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final access = InstitutionalAccess(
            institutionId: 'school',
            state: state,
            managedAccount: true,
            hasAssignment: true,
            practiceAllowed: state == InstitutionalLicenseState.active,
            historyAllowed: true,
            validatedAt: DateTime.utc(2026, 11, 3),
            startsAt: DateTime.utc(2026, 11, 1),
            endsAt: DateTime.utc(2027, 5, 1),
          );
          var refreshes = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                colorSchemeSeed: Colors.indigo,
                brightness: brightness,
              ),
              home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2.5)),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: InstitutionalAccessCard(
                      access: access,
                      username: 'nombre.largo@colegio.institucional.example',
                      onRefresh: () => refreshes++,
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(find.text(access.statusLabel), findsOneWidget);
          expect(
            find.text('Es un usuario de acceso, no un buzón de correo.'),
            findsOneWidget,
          );
          await tester.ensureVisible(find.text('Actualizar acceso'));
          await tester.tap(find.text('Actualizar acceso'));
          expect(refreshes, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'sin asignación no presenta acceso activo y refresco pendiente se deshabilita',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InstitutionalAccessCard(
              access: InstitutionalAccess(
                institutionId: 'school',
                state: InstitutionalLicenseState.active,
                managedAccount: true,
                hasAssignment: false,
                practiceAllowed: false,
                historyAllowed: true,
                validatedAt: DateTime.utc(2026, 11, 3),
              ),
              onRefresh: () {},
              refreshing: true,
            ),
          ),
        ),
      );
      expect(find.text('Sin cupo asignado'), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
    },
  );
}
