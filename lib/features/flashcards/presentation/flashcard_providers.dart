import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_controller.dart';
import '../../library/presentation/reference_library_providers.dart';
import '../data/drift_flashcard_repository.dart';
import '../domain/flashcard_models.dart';

final flashcardCatalogProvider = FutureProvider<List<Flashcard>>((ref) async {
  final library = await ref.watch(referenceLibraryRepositoryProvider).load();
  return buildFlashcards(library);
});

final flashcardProgressProvider = StreamProvider<List<FlashcardProgress>>((
  ref,
) {
  final userId = ref.watch(
    sessionControllerProvider.select((session) => session.user?.id),
  );
  if (userId == null) return Stream.value(const []);
  return ref.watch(flashcardRepositoryProvider).watchProgress(userId);
});
