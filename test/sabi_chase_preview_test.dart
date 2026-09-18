import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/games/ghost_duel/presentation/ghost_duel_setup_page.dart';
import 'package:saber_plus/features/games/ghost_duel/presentation/sabi_chase_preview_page.dart';
import 'package:saber_plus/features/games/ghost_duel/presentation/sabi_runner_painter.dart';

void main() {
  double phase(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint, skipOffstage: false))
      .map((widget) => widget.painter)
      .whereType<SabiChasePainter>()
      .single
      .phase;

  Widget app({bool reduced = false, bool tickers = true}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: TickerMode(enabled: tickers, child: const SabiChasePreviewPage()),
    ),
  );

  testWidgets('debug setup opens isolated preview and returns without a game', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: GhostDuelSetupPage()));
    await tester.ensureVisible(find.byKey(const Key('open-sabi-preview')));
    await tester.tap(find.byKey(const Key('open-sabi-preview')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SabiChasePreviewPage), findsOneWidget);
    expect(find.textContaining('no cambia puntos'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SabiChasePreviewPage), findsNothing);
    expect(find.byType(GhostDuelSetupPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('continuous cycle can pause, scrub and resume without jumping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 120));
    expect(phase(tester), greaterThan(0));
    final before = phase(tester);
    await tester.tap(find.byKey(const Key('sabi-motion-toggle')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(phase(tester), before);
    tester.widget<Slider>(find.byType(Slider)).onChanged!(.6);
    await tester.pump();
    expect(phase(tester), .6);
    await tester.tap(find.byKey(const Key('sabi-motion-toggle')));
    await tester.pump();
    expect(phase(tester), closeTo(.6, .0001));
    await tester.pump(const Duration(milliseconds: 80));
    expect(phase(tester), greaterThan(.6));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'lifecycle, covering routes, reduced motion and ticker mode pause the scene',
    (tester) async {
      await tester.pumpWidget(app());
      await tester.pump(const Duration(milliseconds: 170));
      final before = phase(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 1));
      expect(phase(tester), before);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(phase(tester), isNot(before));
      Navigator.of(tester.element(find.byType(SabiChasePreviewPage))).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Cover')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final covered = phase(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(phase(tester), covered);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(app(tickers: false));
      final hidden = phase(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(phase(tester), hidden);
      await tester.pumpWidget(app(reduced: true));
      expect(phase(tester), .15);
      expect(find.byKey(const Key('sabi-motion-toggle')), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(phase(tester), .15);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  for (final dark in [false, true]) {
    testWidgets('small screen and large text, dark=$dark', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
          home: const MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: SabiChasePreviewPage(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.byKey(const Key('sabi-chase-preview')),
        150,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();
      expect(
        find.bySemanticsLabel(RegExp('Sabi corre detrás')),
        findsOneWidget,
      );
      semantics.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  test('runner cycle closes without a geometric jump', () async {
    Future<List<int>> render(double phase) async {
      final recorder = ui.PictureRecorder();
      SabiRunnerPainter(
        phase: phase,
      ).paint(Canvas(recorder), const Size(200, 250));
      final picture = recorder.endRecording();
      final image = await picture.toImage(200, 250);
      final bytes = await image.toByteData();
      final result = bytes!.buffer.asUint8List().toList();
      image.dispose();
      picture.dispose();
      return result;
    }

    final start = await render(0);
    final end = await render(1);
    expect(end, start);
    expect(await render(.25), isNot(start));
  });

  testWidgets('optional contact sheet for visual inspection', (tester) async {
    if (!const bool.fromEnvironment('CAPTURE_SABI')) return;
    tester.view.physicalSize = const Size(960, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: Column(
              children: [
                for (var row = 0; row < 2; row++)
                  Row(
                    children: [
                      for (var col = 0; col < 2; col++)
                        Column(
                          children: [
                            Text('Fase ${(row * 2 + col) / 4}'),
                            CustomPaint(
                              size: const Size(480, 320),
                              painter: SabiChasePainter(
                                phase: (row * 2 + col) / 4,
                                dark: row == 1,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File('build/sabi-preview/contact-sheet.png');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
