import '../../../core/database/app_database.dart';
import '../domain/study_time_models.dart';
import '../domain/study_time_repository.dart';

class DriftStudyTimeRepository implements StudyTimeRepository {
  DriftStudyTimeRepository(this._database);

  final AppDatabase _database;

  @override
  Stream<List<StudyTimeRecord>> watchAll(String userId) => _database
      .watchStudyTimeEntries(userId)
      .map((rows) => rows.map(_fromRow).toList(growable: false));

  @override
  Future<void> record(StudyTimeRecord entry) async {
    if (entry.durationSeconds <= 0) return;
    await _database.transaction(() async {
      // No importar registros previos ni volver a encolar un evento confirmado.
      if (await _database.findStudyTimeEntry(entry.userId, entry.eventId) !=
          null) {
        return;
      }
      await _database.saveStudyTimeEntry(
        StudyTimeEntriesCompanion.insert(
          userId: entry.userId,
          eventId: entry.eventId,
          source: entry.source.storageValue,
          durationSeconds: entry.durationSeconds,
          recordedAt: entry.recordedAt,
        ),
      );
      if (entry.source == StudyTimeSource.pomodoro &&
          entry.durationSeconds == 1500) {
        await _database.enqueuePomodoro(
          entry.userId,
          entry.eventId,
          DateTime.fromMillisecondsSinceEpoch(
            entry.recordedAt.millisecondsSinceEpoch,
            isUtc: true,
          ).toIso8601String(),
        );
      }
    });
  }

  StudyTimeRecord _fromRow(StudyTimeEntry row) => StudyTimeRecord(
    userId: row.userId,
    eventId: row.eventId,
    source: StudyTimeSource.fromStorage(row.source),
    durationSeconds: row.durationSeconds,
    recordedAt: row.recordedAt,
  );
}
