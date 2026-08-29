import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/session_controller.dart';
import '../data/drift_learning_resume_repository.dart';
import '../domain/learning_resume_models.dart';

final learningResumeProvider = StreamProvider<LearningResume?>((ref) {
  final userId = ref.watch(
    sessionControllerProvider.select((session) => session.user?.id),
  );
  if (userId == null) return Stream.value(null);
  return ref.watch(learningResumeRepositoryProvider).watch(userId);
});
