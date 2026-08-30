import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/gamification/domain/gamification_models.dart';
import 'package:saber_plus/features/profile/domain/academic_activity_report.dart';
import 'package:saber_plus/features/study_time/domain/study_time_models.dart';

void main() {
  test('resume la semana de lunes a domingo sin contar fechas futuras', () {
    final report = AcademicActivityReport.fromSources(
      now: DateTime(2026, 8, 30, 12),
      studyRecords: [
        _record('mon', DateTime(2026, 8, 24, 10), 30),
        _record('sat', DateTime(2026, 8, 29, 10), 20),
        _record('sun', DateTime(2026, 8, 30, 10), 10),
        _record('future', DateTime(2026, 8, 31, 10), 99),
      ],
      dailyActivity: [
        DailyActivity(date: DateTime(2026, 8, 24), count: 2),
        DailyActivity(date: DateTime(2026, 8, 26), count: 3),
        DailyActivity(date: DateTime(2026, 8, 30), count: 1),
        DailyActivity(date: DateTime(2026, 8, 31), count: 40),
      ],
      weeklyTargetMinutes: 120,
    );

    expect(report.week.start, DateTime(2026, 8, 24));
    expect(report.week.endExclusive, DateTime(2026, 8, 31));
    expect(report.week.studySeconds, 60 * 60);
    expect(report.week.sessions, 3);
    expect(report.week.actions, 6);
    expect(report.week.activeDays, 4);
    expect(report.weeklyTargetProgress, 0.5);
    expect(report.weekDays, hasLength(7));
  });

  test('compara el mes actual con el mes calendario anterior', () {
    final report = AcademicActivityReport.fromSources(
      now: DateTime(2026, 8, 30),
      studyRecords: [
        _record('aug-a', DateTime(2026, 8, 5), 75),
        _record('jul-a', DateTime(2026, 7, 15), 40),
      ],
      dailyActivity: [
        DailyActivity(date: DateTime(2026, 8, 5), count: 5),
        DailyActivity(date: DateTime(2026, 7, 10), count: 4),
      ],
    );

    expect(report.currentMonth.start, DateTime(2026, 8));
    expect(report.previousMonth.start, DateTime(2026, 7));
    expect(report.currentMonth.studySeconds, 75 * 60);
    expect(report.previousMonth.studySeconds, 40 * 60);
    expect(report.studySecondsDifference, 35 * 60);
    expect(report.currentMonth.actions, 0);
    expect(report.previousMonth.actions, 0);
  });

  test('mantiene el tiempo local cuando no hay actividad remota', () {
    final report = AcademicActivityReport.fromSources(
      now: DateTime(2026, 8, 30),
      studyRecords: [_record('local', DateTime(2026, 8, 30), 25)],
    );

    expect(report.week.studySeconds, 25 * 60);
    expect(report.week.actions, 0);
    expect(report.actionsAvailable, isFalse);
  });
}

StudyTimeRecord _record(String id, DateTime date, int minutes) =>
    StudyTimeRecord(
      userId: 'student-1',
      eventId: id,
      source: StudyTimeSource.practice,
      durationSeconds: minutes * 60,
      recordedAt: date,
    );
