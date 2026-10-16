import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/profile/presentation/sabi_profession_illustration.dart';

const _names = <SabiProfession, String>{
  SabiProfession.medicine: 'medicine',
  SabiProfession.software: 'software',
  SabiProfession.environmentalAgro: 'environmental_agro',
};

Widget _art(SabiProfession profession, {Key? key}) => RepaintBoundary(
  key: key,
  child: ColoredBox(
    color: const Color(0xFFF4F9FC),
    child: SizedBox(
      width: 615,
      height: 639,
      child: SabiProfessionIllustration(profession: profession),
    ),
  ),
);

Future<void> _writePreview(GlobalKey key, String path) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final output = File(path);
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes!.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}

void main() {
  test('D2A contains only the three authorized prototypes', () {
    expect(SabiProfession.values, [
      SabiProfession.medicine,
      SabiProfession.software,
      SabiProfession.environmentalAgro,
    ]);
    expect(_names.values, ['medicine', 'software', 'environmental_agro']);
  });

  for (final profession in SabiProfession.values) {
    testWidgets('${_names[profession]} uses the canonical base PNG', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: _art(profession))),
        ),
      );
      await tester.pumpAndSettle();
      final images = tester.widgetList<Image>(find.byType(Image));
      expect(images, hasLength(1));
      final provider = images.single.image;
      expect(provider, isA<AssetImage>());
      expect(
        (provider as AssetImage).assetName,
        SabiProfessionIllustration.canonicalAsset,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('capture exactly three D2A previews and a review sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final entry in _names.entries) {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: _art(entry.key, key: key)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => _writePreview(
          key,
          'build/sabi-vocational-preview/${entry.value}.png',
        ),
      );
      expect(tester.takeException(), isNull);
    }

    tester.view.physicalSize = const Size(1350, 565);
    final sheetKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFF4F9FC),
          body: RepaintBoundary(
            key: sheetKey,
            child: ColoredBox(
              color: const Color(0xFFF4F9FC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final entry in _names.entries)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 400,
                          height: 415,
                          child: SabiProfessionIllustration(
                            profession: entry.key,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => _writePreview(
        sheetKey,
        'build/sabi-vocational-preview/contact_sheet.png',
      ),
    );
    expect(tester.takeException(), isNull);
  }, skip: !const bool.fromEnvironment('CAPTURE_SABI_OV1D2'));
}
