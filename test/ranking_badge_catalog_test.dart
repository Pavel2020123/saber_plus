import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/ranking/domain/ranking_badge_catalog.dart';
import 'package:saber_plus/features/ranking/presentation/ranking_badge_catalog_page.dart';

void main() {
  test('40 existing assets and unambiguous coverage for positions 1–50', () {
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
    expect(paths, hasLength(40));
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
