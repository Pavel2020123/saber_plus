import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/flashcard_models.dart';
import '../domain/flashcard_repository.dart';

class DriftFlashcardRepository implements FlashcardRepository {
  DriftFlashcardRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<FlashcardProgress>> watchProgress(String userId) => _database
      .watchFlashcardProgress(userId)
      .map((rows) => rows.map(_fromRow).toList(growable: false));

  @override
  Future<void> recordReview({
    required String userId,
    required String cardId,
    required bool mastered,
    required DateTime reviewedAt,
  }) async {
    final existing = await _database.findFlashcardProgress(userId, cardId);
    await _database.saveFlashcardProgress(
      FlashcardProgressEntriesCompanion.insert(
        userId: userId,
        cardId: cardId,
        mastered: Value(mastered),
        reviewCount: Value((existing?.reviewCount ?? 0) + 1),
        correctCount: Value((existing?.correctCount ?? 0) + (mastered ? 1 : 0)),
        lastReviewedAt: reviewedAt,
      ),
    );
  }

  FlashcardProgress _fromRow(FlashcardProgressEntry row) => FlashcardProgress(
    userId: row.userId,
    cardId: row.cardId,
    mastered: row.mastered,
    reviewCount: row.reviewCount,
    correctCount: row.correctCount,
    lastReviewedAt: row.lastReviewedAt,
  );
}

final flashcardRepositoryProvider = Provider<FlashcardRepository>(
  (ref) => DriftFlashcardRepository(ref.watch(appDatabaseProvider)),
);
