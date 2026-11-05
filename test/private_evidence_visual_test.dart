// Render-only local QA, not native Android evidence or committed goldens.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/theme.dart';
import 'package:saber_plus/features/institutions/presentation/private_evidence_board.dart';
import 'package:saber_plus/features/institutions/presentation/private_evidence_controller.dart';
import 'private_evidence_controller_test.dart' show Repository, file;

const enabled = bool.fromEnvironment('C5_PRIVATE_EVIDENCE_RENDER_QA');
void main() {
  if (enabled) {
    setUpAll(() async {
      const fontPath = String.fromEnvironment('C5_QA_FONT_FILE');
      if (fontPath.isEmpty) throw StateError('Supply a local Roboto font.');
      final bytes = await File(fontPath).readAsBytes();
      await (FontLoader(
        'Roboto',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      final icons = await File.fromUri(
        File(fontPath).uri.resolve('materialicons-regular.otf'),
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(icons)))).load();
    });
  }
  for (final scenario in [
    ('phone-light', const Size(375, 812), false, 1.0),
    ('phone-dark', const Size(375, 812), true, 1.0),
    ('small-large-text', const Size(320, 640), false, 2.5),
    ('landscape-large-text', const Size(844, 390), true, 2.5),
  ]) {
    testWidgets('evidence render-only ${scenario.$1}', (tester) async {
      tester.view.physicalSize = scenario.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = Repository();
      repository.files = [file('3bfc090f-9aa3-45ad-9f20-23dad1b41475')];
      final controller = PrivateEvidenceController(
        repository,
        isCurrent: () => true,
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('evidence-qa'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: scenario.$3 ? SaberPlusTheme.dark : SaberPlusTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scenario.$4),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: PrivateEvidenceBoard(
              controller: controller,
              pick: () async => null,
              export: (_, _) async => true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const Key('evidence-qa')),
        matchesGoldenFile('../.tmp/c5-evidence-${scenario.$1}-top.png'),
      );
      await tester.scrollUntilVisible(find.text('Seleccionar archivo'), 150);
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const Key('evidence-qa')),
        matchesGoldenFile('../.tmp/c5-evidence-${scenario.$1}-actions.png'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    }, skip: !enabled);
  }
}
