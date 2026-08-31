import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/flashcards/domain/flashcard_models.dart';
import 'package:saber_plus/features/games/memory_match/domain/memory_match_models.dart';
import 'package:saber_plus/features/games/memory_match/presentation/memory_match_page.dart';

void main() {
  test('construye y recupera la configuración del juego de memoria', () {
    const config = MemoryMatchConfig(
      kind: MemoryMatchKind.formulas,
      difficulty: MemoryMatchDifficulty.hard,
      area: AcademicArea.mathematics,
    );

    final restored = MemoryMatchConfig.tryFromUri(
      Uri.parse(config.routeLocation),
    );

    expect(restored?.kind, MemoryMatchKind.formulas);
    expect(restored?.difficulty, MemoryMatchDifficulty.hard);
    expect(restored?.area, AcademicArea.mathematics);
    expect(
      MemoryMatchConfig.tryFromUri(
        Uri.parse('/student/practice/memory-match/play?tipo=otro'),
      ),
      isNull,
    );
  });

  test('filtra tarjetas y crea exactamente dos fichas por pareja', () {
    final cards = [
      for (var index = 0; index < 12; index++)
        Flashcard(
          id: 'formula-$index',
          kind: FlashcardKind.formula,
          area: AcademicArea.mathematics,
          front: 'Fórmula $index',
          back: 'Expresión $index',
          context: 'Uso $index',
        ),
      const Flashcard(
        id: 'glossary-1',
        kind: FlashcardKind.glossary,
        area: AcademicArea.english,
        front: 'Context',
        back: 'Definition',
        context: 'Example',
      ),
    ];
    const config = MemoryMatchConfig(
      kind: MemoryMatchKind.formulas,
      difficulty: MemoryMatchDifficulty.medium,
      area: AcademicArea.mathematics,
    );

    final pairs = buildMemoryMatchPairs(cards: cards, config: config, seed: 7);
    final deck = buildMemoryMatchDeck(pairs, seed: 11);

    expect(pairs, hasLength(8));
    expect(pairs.every((pair) => pair.kind == FlashcardKind.formula), isTrue);
    expect(deck, hasLength(16));
    for (final pair in pairs) {
      final tiles = deck.where((tile) => tile.pairId == pair.id).toList();
      expect(tiles, hasLength(2));
      expect(tiles.where((tile) => tile.isPrompt), hasLength(1));
    }
  });

  test('formatea el cronómetro sin aceptar tiempos negativos', () {
    expect(formatMemoryTime(-3), '0:00');
    expect(formatMemoryTime(65), '1:05');
  });

  testWidgets('carga el tablero académico y permite solicitar una pista', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MemoryMatchPage(
            config: MemoryMatchConfig(
              kind: MemoryMatchKind.formulas,
              difficulty: MemoryMatchDifficulty.easy,
              area: AcademicArea.mathematics,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('0 movimientos'), findsOneWidget);
    expect(find.text('0/6'), findsOneWidget);
    final hintFinder = find.byKey(const Key('memory-hint-button'));
    expect(hintFinder, findsOneWidget);

    await tester.tap(hintFinder);
    await tester.pump();
    expect(tester.widget<OutlinedButton>(hintFinder).onPressed, isNull);
    await tester.pump(const Duration(milliseconds: 1250));
    expect(tester.widget<OutlinedButton>(hintFinder).onPressed, isNotNull);
  });
}
