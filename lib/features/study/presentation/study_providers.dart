import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academic/domain/academic_models.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/remote_study_repository.dart';
import '../domain/study_models.dart';

final studyProgressProvider = FutureProvider.autoDispose<StudyProgress>((
  ref,
) async {
  final user = ref.watch(sessionControllerProvider).user;
  if (user?.isDemo ?? false) return StudyProgress.empty;
  return ref.watch(studyRepositoryProvider).loadProgress();
});

final studyCatalogProvider = FutureProvider.autoDispose
    .family<StudyCatalog, AcademicArea>((ref, area) async {
      final user = ref.watch(sessionControllerProvider).user;
      if (user?.isDemo ?? false) return StudyCatalog.demo(area);
      return ref.watch(studyRepositoryProvider).loadCatalog(area);
    });
