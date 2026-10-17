import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/profile/presentation/sabi_profession_illustration.dart';

const _names = <SabiProfession, String>{
  SabiProfession.medicine: 'medicine',
  SabiProfession.nursing: 'nursing',
  SabiProfession.psychology: 'psychology',
  SabiProfession.law: 'law',
  SabiProfession.software: 'software',
  SabiProfession.industrialEngineering: 'industrial_engineering',
  SabiProfession.civilEngineering: 'civil_engineering',
  SabiProfession.administration: 'administration',
  SabiProfession.accounting: 'accounting',
  SabiProfession.education: 'education',
  SabiProfession.design: 'design',
  SabiProfession.environmentalAgro: 'environmental_agro',
};

const _capture = bool.fromEnvironment('CAPTURE_SABI_OV1D2');
const _titles = <SabiProfession, String>{
  SabiProfession.medicine: 'Medicina',
  SabiProfession.nursing: 'Enfermería',
  SabiProfession.psychology: 'Psicología',
  SabiProfession.law: 'Derecho',
  SabiProfession.software: 'Sistemas / software',
  SabiProfession.industrialEngineering: 'Ingeniería industrial',
  SabiProfession.civilEngineering: 'Ingeniería civil',
  SabiProfession.administration: 'Administración',
  SabiProfession.accounting: 'Contaduría',
  SabiProfession.education: 'Educación / licenciaturas',
  SabiProfession.design: 'Diseño / comunicación visual',
  SabiProfession.environmentalAgro: 'Ambiental / agro',
};

const _labels = <SabiProfession, String>{
  SabiProfession.medicine: 'Sabi con bata médica y estetoscopio',
  SabiProfession.nursing:
      'Sabi de enfermería con uniforme clínico y tablero de cuidados',
  SabiProfession.psychology:
      'Sabi de psicología con cuaderno y burbujas de conversación',
  SabiProfession.law: 'Sabi de derecho con traje y libro jurídico con balanza',
  SabiProfession.software: 'Sabi con portátil de software',
  SabiProfession.industrialEngineering:
      'Sabi de ingeniería industrial con chaleco y diagrama de procesos',
  SabiProfession.civilEngineering:
      'Sabi de ingeniería civil con chaleco y plano de un puente',
  SabiProfession.administration:
      'Sabi de administración con chaqueta y tablero de planificación',
  SabiProfession.accounting:
      'Sabi de contaduría con chaleco, calculadora y registro de cuentas',
  SabiProfession.education:
      'Sabi de educación con cardigan, libro y pizarra de formas',
  SabiProfession.design:
      'Sabi de diseño con chaqueta creativa, tableta gráfica y lápiz',
  SabiProfession.environmentalAgro:
      'Sabi con vestimenta de campo, planta y libreta',
};

Widget _art(SabiProfession profession, {Key? key, double width = 615}) =>
    RepaintBoundary(
      key: key,
      child: ColoredBox(
        color: const Color(0xFFF4F9FC),
        child: SizedBox(
          width: width,
          height: width * 1278 / 1230,
          child: SabiProfessionIllustration(profession: profession),
        ),
      ),
    );

File _previewFile(String name) {
  final allowed = {
    ..._names.values,
    'contact_sheet',
    'contact_sheet_1',
    'contact_sheet_2',
  };
  if (!allowed.contains(name)) {
    throw ArgumentError.value(name, 'name', 'Not an authorized preview name');
  }
  if (!_capture) {
    throw StateError('Preview writes require CAPTURE_SABI_OV1D2=true');
  }
  return File('build/sabi-vocational-preview/$name.png');
}

Future<void> _writePreview(GlobalKey key, String name) async {
  final output = _previewFile(name);
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await output.parent.create(recursive: true);
    await output.writeAsBytes(bytes!.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}

Future<void> _loadReviewFont() async {
  // Widget tests default to Ahem blocks. Use the SDK's bundled Roboto only
  // for review captions, without a new production font asset or dependency.
  var directory = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final file = File(
      '${directory.path}/artifacts/material_fonts/roboto-regular.ttf',
    );
    if (await file.exists()) {
      final font = FontLoader('ReviewLabels')
        ..addFont(Future.value(ByteData.sublistView(await file.readAsBytes())));
      await font.load();
      return;
    }
    if (directory.parent.path == directory.path) break;
    directory = directory.parent;
  }
  throw StateError(
    'Cannot locate the Flutter SDK Roboto font for review captions',
  );
}

void main() {
  test('catalog contains exactly the twelve authorized professions', () {
    expect(SabiProfession.values.map((p) => p.name), [
      'medicine',
      'nursing',
      'psychology',
      'law',
      'software',
      'industrialEngineering',
      'civilEngineering',
      'administration',
      'accounting',
      'education',
      'design',
      'environmentalAgro',
    ]);
    expect(_names.keys, SabiProfession.values);
    expect(_labels.values.toSet(), hasLength(12));
  });

  for (final profession in SabiProfession.values) {
    for (final width in [120.0, 615.0]) {
      testWidgets(
        '${_names[profession]} at $width: canonical asset, one semantic image, offline and static',
        (tester) async {
          tester.view.physicalSize = const Size(700, 760);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          var networkAttempts = 0;
          try {
            await HttpOverrides.runZoned(
              () async {
                await tester.pumpWidget(
                  MaterialApp(
                    home: Scaffold(
                      body: Center(child: _art(profession, width: width)),
                    ),
                  ),
                );
                await tester.pumpAndSettle();
                final images = tester.widgetList<Image>(find.byType(Image));
                expect(images, hasLength(1));
                final provider = images.single.image;
                expect(provider, isA<AssetImage>());
                expect(
                  (provider as AssetImage).assetName,
                  'assets/characters/sabi/reference/sabi_front.png',
                );
                final node = tester.getSemantics(
                  find.bySemanticsLabel(_labels[profession]!),
                );
                expect(
                  node,
                  matchesSemantics(label: _labels[profession], isImage: true),
                );
                expect(node.childrenCount, 0);
                expect(
                  tester.getSize(find.byType(SabiProfessionIllustration)).width,
                  width,
                );
                expect(tester.binding.transientCallbackCount, 0);
                expect(tester.binding.hasScheduledFrame, isFalse);
                await tester.pump(const Duration(seconds: 3));
                expect(tester.binding.transientCallbackCount, 0);
                expect(tester.binding.hasScheduledFrame, isFalse);
                expect(tester.takeException(), isNull);
              },
              createHttpClient: (_) {
                networkAttempts++;
                throw StateError('Illustrations must render without HTTP');
              },
            );
            expect(networkAttempts, 0);
          } finally {
            semantics.dispose();
          }
        },
      );
    }
  }

  test('preview output is gated by the capture flag and confined to build', () {
    for (final name in [
      ..._names.values,
      'contact_sheet',
      'contact_sheet_1',
      'contact_sheet_2',
    ]) {
      if (_capture) {
        expect(
          _previewFile(name).path,
          'build/sabi-vocational-preview/$name.png',
        );
      } else {
        expect(() => _previewFile(name), throwsStateError);
      }
    }
  });

  test('preview writer rejects paths and unknown names', () {
    for (final name in [
      '../medicine',
      '../../assets/character',
      '/tmp/medicine',
      r'C:\medicine',
      'another_profession',
    ]) {
      expect(() => _previewFile(name), throwsArgumentError);
    }
  });

  testWidgets('capture twelve previews and labeled contact sheets', (
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
      await tester.runAsync(() => _writePreview(key, entry.value));
      expect(tester.takeException(), isNull);
    }

    await tester.runAsync(_loadReviewFont);
    for (final sheet in [
      ('contact_sheet', SabiProfession.values),
      ('contact_sheet_1', SabiProfession.values.take(6).toList()),
      ('contact_sheet_2', SabiProfession.values.skip(6).toList()),
    ]) {
      final rows = (sheet.$2.length / 3).ceil();
      tester.view.physicalSize = Size(1350, rows * 500);
      final sheetKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: const Color(0xFFF4F9FC),
            body: RepaintBoundary(
              key: sheetKey,
              child: ColoredBox(
                color: const Color(0xFFF4F9FC),
                child: Column(
                  children: [
                    for (var row = 0; row < rows; row++)
                      Row(
                        children: [
                          for (final profession
                              in sheet.$2.skip(row * 3).take(3))
                            SizedBox(
                              width: 450,
                              height: 500,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _titles[profession]!,
                                    style: const TextStyle(
                                      fontFamily: 'ReviewLabels',
                                      fontSize: 21,
                                      color: Color(0xFF233F58),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: 400,
                                    height: 415,
                                    child: SabiProfessionIllustration(
                                      profession: profession,
                                    ),
                                  ),
                                ],
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
      await tester.runAsync(() => _writePreview(sheetKey, sheet.$1));
      expect(tester.takeException(), isNull);
    }
  }, skip: !_capture);
}
