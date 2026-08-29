import '../../academic/domain/academic_models.dart';
import '../../library/domain/reference_library_models.dart';

enum FlashcardKind {
  formula('FORMULA', 'Fórmulas'),
  glossary('GLOSSARY', 'Glosario');

  const FlashcardKind(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static FlashcardKind? tryFromQuery(String? value) => switch (value) {
    'formula' => FlashcardKind.formula,
    'glossary' => FlashcardKind.glossary,
    _ => null,
  };

  String get queryValue => switch (this) {
    FlashcardKind.formula => 'formula',
    FlashcardKind.glossary => 'glossary',
  };
}

class Flashcard {
  const Flashcard({
    required this.id,
    required this.kind,
    required this.area,
    required this.front,
    required this.back,
    required this.context,
    this.note,
  });

  final String id;
  final FlashcardKind kind;
  final AcademicArea area;
  final String front;
  final String back;
  final String context;
  final String? note;
}

class FlashcardProgress {
  const FlashcardProgress({
    required this.userId,
    required this.cardId,
    required this.mastered,
    required this.reviewCount,
    required this.correctCount,
    required this.lastReviewedAt,
  });

  final String userId;
  final String cardId;
  final bool mastered;
  final int reviewCount;
  final int correctCount;
  final DateTime lastReviewedAt;
}

class FlashcardSessionConfig {
  const FlashcardSessionConfig({this.kind, this.area, this.count = 10});

  final FlashcardKind? kind;
  final AcademicArea? area;
  final int count;

  String get location {
    final parameters = <String, String>{'cantidad': '$count'};
    if (kind case final selected?) parameters['tipo'] = selected.queryValue;
    if (area case final selected?) parameters['area'] = selected.slug;
    return Uri(
      path: '/student/progress/flashcards/session',
      queryParameters: parameters,
    ).toString();
  }

  factory FlashcardSessionConfig.fromUri(Uri uri) {
    final count = int.tryParse(uri.queryParameters['cantidad'] ?? '');
    final areaValue = uri.queryParameters['area'];
    AcademicArea? area;
    if (areaValue != null) {
      area = AcademicArea.values
          .where((item) => item.slug == areaValue)
          .firstOrNull;
    }
    return FlashcardSessionConfig(
      kind: FlashcardKind.tryFromQuery(uri.queryParameters['tipo']),
      area: area,
      count: count != null && count >= 5 && count <= 30 ? count : 10,
    );
  }
}

List<Flashcard> buildFlashcards(ReferenceLibrary library) {
  final cards = <Flashcard>[];
  for (final area in library.formulas) {
    for (final section in area.sections) {
      for (final item in section.items) {
        cards.add(
          Flashcard(
            id: _stableId(
              'formula',
              area.area.backendValue,
              section.id,
              item.name,
            ),
            kind: FlashcardKind.formula,
            area: area.area,
            front: '¿Cuál es la fórmula o relación para ${item.name}?',
            back: item.expression,
            context: item.use,
            note: [
              if (item.variables case final value?) 'Variables: $value',
              if (item.warning case final value?) 'Atención: $value',
            ].join('\n'),
          ),
        );
      }
    }
  }
  for (final term in library.glossary) {
    cards.add(
      Flashcard(
        id: _stableId('glossary', term.area.backendValue, term.term),
        kind: FlashcardKind.glossary,
        area: term.area,
        front: term.term,
        back: term.definition,
        context: 'Ejemplo: ${term.example}',
        note: term.related.isEmpty
            ? null
            : 'Relacionado: ${term.related.join(', ')}',
      ),
    );
  }
  return List.unmodifiable(cards);
}

List<Flashcard> buildFlashcardSession({
  required List<Flashcard> cards,
  required Map<String, FlashcardProgress> progress,
  required FlashcardSessionConfig config,
}) {
  final filtered = cards
      .where((card) {
        if (config.kind != null && card.kind != config.kind) return false;
        if (config.area != null && card.area != config.area) return false;
        return true;
      })
      .toList(growable: false);

  final sorted = [...filtered]
    ..sort((left, right) {
      final leftProgress = progress[left.id];
      final rightProgress = progress[right.id];
      final mastery = (leftProgress?.mastered ?? false ? 1 : 0).compareTo(
        rightProgress?.mastered ?? false ? 1 : 0,
      );
      if (mastery != 0) return mastery;
      final reviews = (leftProgress?.reviewCount ?? 0).compareTo(
        rightProgress?.reviewCount ?? 0,
      );
      if (reviews != 0) return reviews;
      return left.id.compareTo(right.id);
    });
  return sorted.take(config.count).toList(growable: false);
}

String _stableId(String kind, String area, String value, [String? extra]) {
  final source = [kind, area, value, ?extra].join('-');
  return source
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}
