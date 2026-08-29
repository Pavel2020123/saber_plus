import 'flashcard_models.dart';

abstract interface class FlashcardRepository {
  Stream<List<FlashcardProgress>> watchProgress(String userId);

  Future<void> recordReview({
    required String userId,
    required String cardId,
    required bool mastered,
    required DateTime reviewedAt,
  });
}
