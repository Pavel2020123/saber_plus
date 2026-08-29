import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/flashcards/domain/flashcard_models.dart';
import 'package:saber_plus/features/library/data/asset_reference_library_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'genera flashcards de todas las fórmulas y términos del glosario',
    () async {
      final library = await AssetReferenceLibraryRepository().load();
      final cards = buildFlashcards(library);

      expect(cards, hasLength(130));
      expect(
        cards.where((card) => card.kind == FlashcardKind.formula),
        hasLength(80),
      );
      expect(
        cards.where((card) => card.kind == FlashcardKind.glossary),
        hasLength(50),
      );
      expect(cards.map((card) => card.id).toSet(), hasLength(cards.length));
    },
  );

  test('prioriza tarjetas pendientes y menos repasadas', () {
    const cards = [
      Flashcard(
        id: 'a',
        kind: FlashcardKind.formula,
        area: AcademicArea.mathematics,
        front: 'A',
        back: 'A',
        context: 'A',
      ),
      Flashcard(
        id: 'b',
        kind: FlashcardKind.formula,
        area: AcademicArea.mathematics,
        front: 'B',
        back: 'B',
        context: 'B',
      ),
      Flashcard(
        id: 'c',
        kind: FlashcardKind.glossary,
        area: AcademicArea.english,
        front: 'C',
        back: 'C',
        context: 'C',
      ),
    ];
    final progress = {
      'a': FlashcardProgress(
        userId: 'student-1',
        cardId: 'a',
        mastered: true,
        reviewCount: 1,
        correctCount: 1,
        lastReviewedAt: DateTime.utc(2026, 8, 29),
      ),
      'b': FlashcardProgress(
        userId: 'student-1',
        cardId: 'b',
        mastered: false,
        reviewCount: 3,
        correctCount: 1,
        lastReviewedAt: DateTime.utc(2026, 8, 29),
      ),
    };

    final session = buildFlashcardSession(
      cards: cards,
      progress: progress,
      config: const FlashcardSessionConfig(count: 3),
    );

    expect(session.map((card) => card.id), ['c', 'b', 'a']);
  });

  test('conserva filtros en la ruta de una sesión', () {
    const config = FlashcardSessionConfig(
      kind: FlashcardKind.glossary,
      area: AcademicArea.english,
      count: 20,
    );
    final restored = FlashcardSessionConfig.fromUri(Uri.parse(config.location));

    expect(restored.kind, FlashcardKind.glossary);
    expect(restored.area, AcademicArea.english);
    expect(restored.count, 20);
  });
}
