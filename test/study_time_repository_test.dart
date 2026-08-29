import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/core/database/app_database.dart';
import 'package:saber_plus/features/study_time/data/drift_study_time_repository.dart';
import 'package:saber_plus/features/study_time/domain/study_time_models.dart';

void main() {
  test('registra cada actividad una vez y separa estudiantes', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final repository = DriftStudyTimeRepository(database);
    addTearDown(database.close);
    final record = StudyTimeRecord(
      userId: 'student-1',
      eventId: 'practice:attempt-1',
      source: StudyTimeSource.practice,
      durationSeconds: 420,
      recordedAt: DateTime.utc(2026, 8, 29, 15),
    );

    await repository.record(record);
    await repository.record(record);

    final studentOne = await repository.watchAll('student-1').first;
    expect(studentOne, hasLength(1));
    expect(studentOne.single.durationSeconds, 420);
    expect(await repository.watchAll('student-2').first, isEmpty);
  });

  test('calcula total, hoy, semana y desglose sin contar días futuros', () {
    final now = DateTime(2026, 8, 29, 18);
    final summary = StudyTimeSummary.fromRecords([
      _record('today', StudyTimeSource.pomodoro, 1500, now),
      _record(
        'week',
        StudyTimeSource.practice,
        2700,
        now.subtract(const Duration(days: 3)),
      ),
      _record(
        'old',
        StudyTimeSource.diagnostic,
        3600,
        now.subtract(const Duration(days: 8)),
      ),
      _record(
        'future',
        StudyTimeSource.practice,
        900,
        now.add(const Duration(days: 1)),
      ),
    ], now: now);

    expect(summary.totalSeconds, 8700);
    expect(summary.todaySeconds, 1500);
    expect(summary.lastSevenDaysSeconds, 4200);
    expect(summary.secondsBySource[StudyTimeSource.practice], 3600);
    expect(formatStudyDuration(summary.totalSeconds), '2 h 25 min');
    expect(formatStudyDuration(45), '< 1 min');
    expect(formatStudyDuration(0), '0 min');
  });
}

StudyTimeRecord _record(
  String id,
  StudyTimeSource source,
  int seconds,
  DateTime recordedAt,
) => StudyTimeRecord(
  userId: 'student-1',
  eventId: id,
  source: source,
  durationSeconds: seconds,
  recordedAt: recordedAt,
);
