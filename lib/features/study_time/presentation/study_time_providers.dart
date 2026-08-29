import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/demo_study_time_repository.dart';
import '../data/drift_study_time_repository.dart';
import '../domain/study_time_models.dart';
import '../domain/study_time_repository.dart';

typedef StudyTimeNow = DateTime Function();

final studyTimeNowProvider = Provider<StudyTimeNow>((ref) => DateTime.now);

final studyTimeRepositoryProvider = Provider<StudyTimeRepository>((ref) {
  final isDemo = ref.watch(
    sessionControllerProvider.select(
      (session) => session.user?.isDemo ?? false,
    ),
  );
  if (isDemo) {
    final repository = DemoStudyTimeRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  return DriftStudyTimeRepository(ref.watch(appDatabaseProvider));
});

final studyTimeRecordsProvider = StreamProvider<List<StudyTimeRecord>>((ref) {
  final userId = ref.watch(
    sessionControllerProvider.select((session) => session.user?.id),
  );
  if (userId == null) return Stream.value(const []);
  return ref.watch(studyTimeRepositoryProvider).watchAll(userId);
});

final studyTimeSummaryProvider = Provider<AsyncValue<StudyTimeSummary>>((ref) {
  final records = ref.watch(studyTimeRecordsProvider);
  return records.whenData(
    (items) => StudyTimeSummary.fromRecords(
      items,
      now: ref.watch(studyTimeNowProvider)(),
    ),
  );
});
