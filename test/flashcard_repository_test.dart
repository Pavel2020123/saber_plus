import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/features/flashcards/data/drift_flashcard_repository.dart';

void main() {
  test(
    'guarda y actualiza el dominio de cada tarjeta por estudiante',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final repository = DriftFlashcardRepository(database);
      addTearDown(database.close);

      await repository.recordReview(
        userId: 'student-1',
        cardId: 'formula-1',
        mastered: true,
        reviewedAt: DateTime.utc(2026, 8, 29, 10),
      );
      var progress = await repository.watchProgress('student-1').first;
      expect(progress, hasLength(1));
      expect(progress.single.mastered, isTrue);
      expect(progress.single.reviewCount, 1);
      expect(progress.single.correctCount, 1);
      expect(await repository.watchProgress('student-2').first, isEmpty);

      await repository.recordReview(
        userId: 'student-1',
        cardId: 'formula-1',
        mastered: false,
        reviewedAt: DateTime.utc(2026, 8, 29, 11),
      );
      progress = await repository.watchProgress('student-1').first;
      expect(progress.single.mastered, isFalse);
      expect(progress.single.reviewCount, 2);
      expect(progress.single.correctCount, 1);
      expect(
        progress.single.lastReviewedAt.isAtSameMomentAs(
          DateTime.utc(2026, 8, 29, 11),
        ),
        isTrue,
      );
    },
  );
}
