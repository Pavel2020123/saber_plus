import '../../gamification/domain/gamification_models.dart';
import '../../study_time/domain/study_time_models.dart';

class DailyAcademicActivity {
  const DailyAcademicActivity({
    required this.date,
    required this.studySeconds,
    required this.sessions,
    required this.actions,
  });

  final DateTime date;
  final int studySeconds;
  final int sessions;
  final int actions;
}

class AcademicPeriodSummary {
  const AcademicPeriodSummary({
    required this.start,
    required this.endExclusive,
    required this.studySeconds,
    required this.sessions,
    required this.activeDays,
    required this.actions,
  });

  final DateTime start;
  final DateTime endExclusive;
  final int studySeconds;
  final int sessions;
  final int activeDays;
  final int actions;
}

class AcademicActivityReport {
  const AcademicActivityReport({
    required this.week,
    required this.weekDays,
    required this.currentMonth,
    required this.previousMonth,
    required this.actionsAvailable,
    this.weeklyTargetMinutes,
  });

  final AcademicPeriodSummary week;
  final List<DailyAcademicActivity> weekDays;
  final AcademicPeriodSummary currentMonth;
  final AcademicPeriodSummary previousMonth;
  final bool actionsAvailable;
  final int? weeklyTargetMinutes;

  int get studySecondsDifference =>
      currentMonth.studySeconds - previousMonth.studySeconds;

  int get sessionDifference => currentMonth.sessions - previousMonth.sessions;

  int get activeDaysDifference =>
      currentMonth.activeDays - previousMonth.activeDays;

  double? get weeklyTargetProgress {
    final target = weeklyTargetMinutes;
    if (target == null || target <= 0) return null;
    return (week.studySeconds / (target * 60)).clamp(0, 1);
  }

  factory AcademicActivityReport.fromSources({
    required DateTime now,
    required List<StudyTimeRecord> studyRecords,
    List<DailyActivity>? dailyActivity,
    int? weeklyTargetMinutes,
  }) {
    final today = _dateOnly(now);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final currentMonthStart = DateTime(today.year, today.month);
    final nextMonthStart = DateTime(today.year, today.month + 1);
    final previousMonthStart = DateTime(today.year, today.month - 1);
    final records = studyRecords
        .where((record) => !_dateOnly(record.recordedAt).isAfter(today))
        .toList(growable: false);
    final actions = (dailyActivity ?? const <DailyActivity>[])
        .where((item) => !_dateOnly(item.date).isAfter(today))
        .toList(growable: false);

    return AcademicActivityReport(
      week: _summarize(
        start: weekStart,
        endExclusive: weekEnd,
        records: records,
        activity: actions,
      ),
      weekDays: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        final next = date.add(const Duration(days: 1));
        final summary = _summarize(
          start: date,
          endExclusive: next,
          records: records,
          activity: actions,
        );
        return DailyAcademicActivity(
          date: date,
          studySeconds: summary.studySeconds,
          sessions: summary.sessions,
          actions: summary.actions,
        );
      }, growable: false),
      currentMonth: _summarize(
        start: currentMonthStart,
        endExclusive: nextMonthStart,
        records: records,
        activity: const [],
      ),
      previousMonth: _summarize(
        start: previousMonthStart,
        endExclusive: currentMonthStart,
        records: records,
        activity: const [],
      ),
      actionsAvailable: dailyActivity != null,
      weeklyTargetMinutes:
          weeklyTargetMinutes != null && weeklyTargetMinutes > 0
          ? weeklyTargetMinutes
          : null,
    );
  }
}

AcademicPeriodSummary _summarize({
  required DateTime start,
  required DateTime endExclusive,
  required List<StudyTimeRecord> records,
  required List<DailyActivity> activity,
}) {
  var studySeconds = 0;
  var sessions = 0;
  var actions = 0;
  final activeDates = <String>{};

  for (final record in records) {
    final date = _dateOnly(record.recordedAt);
    if (date.isBefore(start) || !date.isBefore(endExclusive)) continue;
    studySeconds += record.durationSeconds.clamp(0, 24 * 60 * 60);
    sessions++;
    activeDates.add(_dateKey(date));
  }

  for (final item in activity) {
    final date = _dateOnly(item.date);
    if (date.isBefore(start) || !date.isBefore(endExclusive)) continue;
    final count = item.count.clamp(0, 1000000);
    actions += count;
    if (count > 0) activeDates.add(_dateKey(date));
  }

  return AcademicPeriodSummary(
    start: start,
    endExclusive: endExclusive,
    studySeconds: studySeconds,
    sessions: sessions,
    activeDays: activeDates.length,
    actions: actions,
  );
}

DateTime _dateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String _dateKey(DateTime value) => '${value.year}-${value.month}-${value.day}';
