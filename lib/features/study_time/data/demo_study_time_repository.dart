import 'dart:async';

import '../domain/study_time_models.dart';
import '../domain/study_time_repository.dart';

class DemoStudyTimeRepository implements StudyTimeRepository {
  DemoStudyTimeRepository() {
    final now = DateTime.now();
    _records.addAll([
      StudyTimeRecord(
        userId: 'demo-student',
        eventId: 'demo-pomodoro-1',
        source: StudyTimeSource.pomodoro,
        durationSeconds: 25 * 60,
        recordedAt: now.subtract(const Duration(hours: 1)),
      ),
      StudyTimeRecord(
        userId: 'demo-student',
        eventId: 'demo-practice-1',
        source: StudyTimeSource.practice,
        durationSeconds: 42 * 60,
        recordedAt: now.subtract(const Duration(hours: 3)),
      ),
      StudyTimeRecord(
        userId: 'demo-student',
        eventId: 'demo-diagnostic-1',
        source: StudyTimeSource.diagnostic,
        durationSeconds: 38 * 60,
        recordedAt: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  final _records = <StudyTimeRecord>[];
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<List<StudyTimeRecord>> watchAll(String userId) async* {
    List<StudyTimeRecord> current() => _records
        .where((record) => record.userId == userId)
        .toList(growable: false);
    yield current();
    yield* _changes.stream.map((_) => current());
  }

  @override
  Future<void> record(StudyTimeRecord entry) async {
    if (entry.durationSeconds <= 0) return;
    final exists = _records.any(
      (record) =>
          record.userId == entry.userId && record.eventId == entry.eventId,
    );
    if (exists) return;
    _records.add(entry);
    _changes.add(null);
  }

  void dispose() => _changes.close();
}
