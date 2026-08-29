import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_controller.dart';
import '../data/drift_difficult_question_repository.dart';
import '../domain/difficult_question_models.dart';

final difficultQuestionsProvider = StreamProvider<List<DifficultQuestionMark>>((
  ref,
) {
  final userId = ref.watch(
    sessionControllerProvider.select((session) => session.user?.id),
  );
  if (userId == null) return Stream.value(const []);
  return ref.watch(difficultQuestionRepositoryProvider).watchAll(userId);
});

final difficultQuestionStatusProvider = StreamProvider.autoDispose
    .family<bool, String>((ref, questionId) {
      final userId = ref.watch(
        sessionControllerProvider.select((session) => session.user?.id),
      );
      if (userId == null) return Stream.value(false);
      return ref
          .watch(difficultQuestionRepositoryProvider)
          .watchContains(userId, questionId);
    });
