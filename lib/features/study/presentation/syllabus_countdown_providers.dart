import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academic/domain/academic_models.dart';
import '../../academic/presentation/academic_home_controller.dart';
import '../../exam_countdown/presentation/exam_countdown_clock.dart';
import '../domain/syllabus_countdown_models.dart';
import 'study_providers.dart';

final syllabusCountdownProvider = FutureProvider.autoDispose<SyllabusCountdown>(
  (ref) async {
    final academicFuture = ref.watch(academicHomeControllerProvider.future);
    final progressFuture = ref.watch(studyProgressProvider.future);
    final nowFuture = ref.watch(examCountdownClockProvider.future);
    final catalogFutures = [
      for (final area in AcademicArea.values)
        ref.watch(studyCatalogProvider(area).future),
    ];
    final academic = await academicFuture;
    final progress = await progressFuture;
    final now = await nowFuture;
    final catalogs = await Future.wait(catalogFutures);
    return SyllabusCountdown.calculate(
      catalogs: catalogs,
      progress: progress,
      exam: academic.activeExam,
      now: now,
    );
  },
);
