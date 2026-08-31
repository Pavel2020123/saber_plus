import 'dart:math';

import '../../../academic/domain/academic_models.dart';
import '../../../flashcards/domain/flashcard_models.dart';

enum MemoryMatchKind {
  mixed('mixed', 'Fórmulas y glosario'),
  formulas('formulas', 'Solo fórmulas'),
  glossary('glossary', 'Solo glosario');

  const MemoryMatchKind(this.queryValue, this.label);

  final String queryValue;
  final String label;

  static MemoryMatchKind? tryFromQuery(String? value) {
    for (final kind in values) {
      if (kind.queryValue == value) return kind;
    }
    return null;
  }
}

enum MemoryMatchDifficulty {
  easy('easy', 'Fácil', 6),
  medium('medium', 'Media', 8),
  hard('hard', 'Difícil', 10);

  const MemoryMatchDifficulty(this.queryValue, this.label, this.pairCount);

  final String queryValue;
  final String label;
  final int pairCount;

  static MemoryMatchDifficulty? tryFromQuery(String? value) {
    for (final difficulty in values) {
      if (difficulty.queryValue == value) return difficulty;
    }
    return null;
  }
}

class MemoryMatchConfig {
  const MemoryMatchConfig({
    required this.kind,
    required this.difficulty,
    this.area,
  });

  final MemoryMatchKind kind;
  final MemoryMatchDifficulty difficulty;
  final AcademicArea? area;

  String get routeLocation => Uri(
    path: '/student/practice/memory-match/play',
    queryParameters: {
      'tipo': kind.queryValue,
      'dificultad': difficulty.queryValue,
      if (area case final selected?) 'area': selected.slug,
    },
  ).toString();

  static MemoryMatchConfig? tryFromUri(Uri uri) {
    final kind = MemoryMatchKind.tryFromQuery(uri.queryParameters['tipo']);
    final difficulty = MemoryMatchDifficulty.tryFromQuery(
      uri.queryParameters['dificultad'],
    );
    if (kind == null || difficulty == null) return null;
    final rawArea = uri.queryParameters['area'];
    try {
      return MemoryMatchConfig(
        kind: kind,
        difficulty: difficulty,
        area: rawArea == null ? null : AcademicArea.fromSlug(rawArea),
      );
    } on Object {
      return null;
    }
  }
}

class MemoryMatchPair {
  const MemoryMatchPair({
    required this.id,
    required this.kind,
    required this.area,
    required this.prompt,
    required this.answer,
    required this.context,
  });

  final String id;
  final FlashcardKind kind;
  final AcademicArea area;
  final String prompt;
  final String answer;
  final String context;
}

class MemoryMatchTile {
  const MemoryMatchTile({
    required this.id,
    required this.pairId,
    required this.text,
    required this.isPrompt,
  });

  final String id;
  final String pairId;
  final String text;
  final bool isPrompt;
}

List<MemoryMatchPair> buildMemoryMatchPairs({
  required List<Flashcard> cards,
  required MemoryMatchConfig config,
  int? seed,
}) {
  final filtered = cards
      .where((card) {
        if (config.area != null && card.area != config.area) return false;
        return switch (config.kind) {
          MemoryMatchKind.mixed => true,
          MemoryMatchKind.formulas => card.kind == FlashcardKind.formula,
          MemoryMatchKind.glossary => card.kind == FlashcardKind.glossary,
        };
      })
      .toList(growable: false);
  final shuffled = [...filtered]..shuffle(Random(seed));
  return List.unmodifiable(
    shuffled
        .take(config.difficulty.pairCount)
        .map(
          (card) => MemoryMatchPair(
            id: card.id,
            kind: card.kind,
            area: card.area,
            prompt: card.front,
            answer: card.back,
            context: card.context,
          ),
        ),
  );
}

List<MemoryMatchTile> buildMemoryMatchDeck(
  List<MemoryMatchPair> pairs, {
  int? seed,
}) {
  final tiles = <MemoryMatchTile>[
    for (final pair in pairs) ...[
      MemoryMatchTile(
        id: '${pair.id}-prompt',
        pairId: pair.id,
        text: pair.prompt,
        isPrompt: true,
      ),
      MemoryMatchTile(
        id: '${pair.id}-answer',
        pairId: pair.id,
        text: pair.answer,
        isPrompt: false,
      ),
    ],
  ]..shuffle(Random(seed));
  return List.unmodifiable(tiles);
}

String formatMemoryTime(int seconds) {
  final safe = seconds.clamp(0, 359999);
  final minutes = safe ~/ 60;
  final remainder = safe % 60;
  return '$minutes:${remainder.toString().padLeft(2, '0')}';
}
