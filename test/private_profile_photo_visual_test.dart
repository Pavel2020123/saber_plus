// Render-only opt-in artifacts, not committed golden baselines or native QA.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/app/theme.dart';
import 'package:saber_plus/features/profile/presentation/private_profile_photo_board.dart';
import 'private_profile_photo_board_test.dart' show PhotoFake;

const renderPrivatePhotoQa = bool.fromEnvironment('C5_PRIVATE_PHOTO_RENDER_QA');

void main() {
  if (renderPrivatePhotoQa) {
    setUpAll(() async {
      const fontPath = String.fromEnvironment('C5_QA_FONT_FILE');
      if (fontPath.isEmpty) {
        throw StateError('Pass a local Roboto font for readable QA artifacts.');
      }
      final bytes = await File(fontPath).readAsBytes();
      await (FontLoader(
        'Roboto',
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      final iconBytes = await File.fromUri(
        File(fontPath).uri.resolve('materialicons-regular.otf'),
      ).readAsBytes();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(Future.value(ByteData.sublistView(iconBytes)))).load();
    });
  }
  for (final scenario in [
    ('phone-light', const Size(375, 812), Brightness.light, 1.0),
    ('phone-dark', const Size(375, 812), Brightness.dark, 1.0),
    ('small-large-text', const Size(320, 640), Brightness.light, 2.5),
    ('landscape-large-text', const Size(812, 375), Brightness.dark, 2.5),
  ]) {
    testWidgets('render-only private photo ${scenario.$1}', (tester) async {
      tester.view.physicalSize = scenario.$2;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('photo-visual'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: scenario.$3 == Brightness.dark
                ? SaberPlusTheme.dark
                : SaberPlusTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scenario.$4),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: PrivateProfilePhotoBoard(
              userId: 'visual-fixture',
              repository: PhotoFake(),
              pick: () async => null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const Key('photo-visual')),
        matchesGoldenFile('../.tmp/c5-private-photo-${scenario.$1}.png'),
      );
    }, skip: !renderPrivatePhotoQa);
  }
}
