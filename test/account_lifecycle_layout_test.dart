import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/institutions/domain/account_privacy_request.dart';
import 'package:saber_plus/features/institutions/domain/personal_return_eligibility.dart';
import 'package:saber_plus/features/institutions/presentation/account_privacy_page.dart';
import 'package:saber_plus/features/institutions/presentation/personal_return_page.dart';

void main() {
  for (final size in [const Size(375, 812), const Size(812, 375)]) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'privacy and return at $size $brightness large text reduced motion',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          Widget wrap(Widget child) => MaterialApp(
            theme: ThemeData(brightness: brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2.5),
                disableAnimations: true,
                padding: const EdgeInsets.only(bottom: 24),
              ),
              child: child!,
            ),
            home: child,
          );
          await tester.pumpWidget(
            wrap(
              AccountPrivacyBoard(
                userId: 'self',
                load: (_) async => const AccountPrivacyPage(1, false, []),
                submit: (_, _) async =>
                    throw StateError('No write in layout test'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(
            find.text('Actualizar estado'),
            200,
            scrollable: find.byType(Scrollable).first,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            wrap(
              PersonalReturnBoard(
                load: () async => PersonalReturnEligibility.fromJson({
                  'puedeVolver': false,
                  'gestionada': true,
                  'asignacionId': null,
                  'versionAsignacion': null,
                }),
                submit: (_, _) async =>
                    throw StateError('No write in layout test'),
                refreshSession: () async => false,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('Actualizar vinculación'),
            200,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
