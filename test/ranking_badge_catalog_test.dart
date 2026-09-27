import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/ranking/domain/ranking_badge_catalog.dart';
import 'package:saber_plus/features/ranking/presentation/ranking_badge_catalog_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 90 images are bundled and decode as real images', () async {
    for (final family in BadgeGame.values) {
      for (final art in RankingBadgeArt.forGame(family)) {
        final data = await rootBundle.load(art.assetPath);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: 32,
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0), reason: art.assetPath);
        frame.image.dispose();
        codec.dispose();
      }
    }
  });

  test('retired game has no route or practice entry', () {
    expect(
      File('lib/app/router.dart').readAsStringSync(),
      isNot(contains('knowledge-shield')),
    );
    expect(
      File(
        'lib/features/practice/presentation/practice_hub_page.dart',
      ).readAsStringSync(),
      isNot(contains('open-knowledge-shield')),
    );
  });

  for (final family in [
    BadgeGame.guardian,
    BadgeGame.memory,
    BadgeGame.battles,
    BadgeGame.starRescue,
    BadgeGame.institutions,
  ]) {
    testWidgets('new family ${family.label} displays preview and detail', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: RankingBadgeCatalogPage()),
      );
      await tester.ensureVisible(find.text(family.label));
      await tester.tap(find.text(family.label));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('TOP 1'));
      await tester.tap(find.text('TOP 1'));
      await tester.pumpAndSettle();
      expect(find.text('${family.label} · TOP 1'), findsOneWidget);
      if (family.isInstitution) {
        expect(
          find.textContaining('no para un jugador individual'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
  test('90 existing assets and unambiguous coverage for positions 1–50', () {
    final paths = <String>{};
    for (final game in BadgeGame.values) {
      final catalog = RankingBadgeArt.forGame(game);
      for (final art in catalog) {
        expect(File(art.assetPath).existsSync(), isTrue);
        paths.add(art.assetPath);
      }
      for (var rank = 1; rank <= 50; rank++) {
        expect(
          catalog.where((a) => rank >= a.first && rank <= a.last),
          hasLength(1),
        );
        expect(RankingBadgeArt.forPosition(game, rank), isNotNull);
      }
      for (final rank in [-1, 0, 51, 100, 101]) {
        expect(RankingBadgeArt.forPosition(game, rank), isNull);
      }
    }
    expect(paths, hasLength(90));
    expect(BadgeGame.values.where((game) => !game.isInstitution), hasLength(8));
    expect(BadgeGame.values.where((game) => game.isInstitution), hasLength(1));
  });

  testWidgets('catalog switches games and describes previews honestly', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: RankingBadgeCatalogPage()));
    expect(find.text('Catálogo de diseños'), findsOneWidget);
    await tester.tap(find.text('Duelo fantasma'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TOP 1'));
    await tester.pumpAndSettle();
    expect(find.text('Duelo fantasma · TOP 1'), findsOneWidget);
    expect(find.textContaining('Vista previa, no obtenida.'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
