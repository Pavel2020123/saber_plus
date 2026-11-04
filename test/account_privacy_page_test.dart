import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/domain/account_privacy_request.dart';
import 'package:saber_plus/features/institutions/presentation/account_privacy_page.dart';

void main() {
  AccountPrivacyRequest request(String user) => AccountPrivacyRequest.fromJson({
    'id': 'request',
    'usuarioId': user,
    'estado': 'PENDIENTE',
    'creadoEn': '2026-11-03T12:00:00Z',
  });

  testWidgets('pending own request disables another submission', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountPrivacyBoard(
          userId: 'self',
          load: (_) async => AccountPrivacyPage(1, false, [request('self')]),
          submit: (_, _) async => throw StateError('must not submit'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Solicitar revisión'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Pendiente de revisión'), findsOneWidget);
  });

  testWidgets(
    'does not display another managed student request in own history',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AccountPrivacyBoard(
            userId: 'self',
            load: (_) async => AccountPrivacyPage(1, false, [request('other')]),
            submit: (_, _) async => request('self'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pendiente de revisión'), findsNothing);
      expect(
        find.text('No hay solicitudes propias en esta página.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'network uncertainty retains motive and disables automatic retry',
    (tester) async {
      var writes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AccountPrivacyBoard(
            userId: 'self',
            load: (_) async => const AccountPrivacyPage(1, false, []),
            submit: (_, _) async {
              writes++;
              throw Exception('timeout');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Solicitud de prueba');
      await tester.ensureVisible(find.text('Solicitar revisión'));
      await tester.tap(find.text('Solicitar revisión'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enviar solicitud'));
      await tester.pumpAndSettle();
      expect(writes, 1);
      expect(find.text('Solicitud de prueba'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Solicitar revisión'),
            )
            .onPressed,
        isNull,
      );
    },
  );
}
