enum StudyTimeSource {
  pomodoro('POMODORO', 'Pomodoro'),
  practice('PRACTICE', 'Prácticas y simulacros'),
  diagnostic('DIAGNOSTIC', 'Diagnóstico');

  const StudyTimeSource(this.storageValue, this.label);

  final String storageValue;
  final String label;

  factory StudyTimeSource.fromStorage(String value) => values.firstWhere(
    (source) => source.storageValue == value,
    orElse: () =>
        throw FormatException('Fuente de estudio desconocida: $value'),
  );
}

class StudyTimeRecord {
  const StudyTimeRecord({
    required this.userId,
    required this.eventId,
    required this.source,
    required this.durationSeconds,
    required this.recordedAt,
  });

  final String userId;
  final String eventId;
  final StudyTimeSource source;
  final int durationSeconds;
  final DateTime recordedAt;
}

class StudyTimeSummary {
  const StudyTimeSummary({
    required this.totalSeconds,
    required this.todaySeconds,
    required this.lastSevenDaysSeconds,
    required this.secondsBySource,
    required this.sessionCount,
  });

  final int totalSeconds;
  final int todaySeconds;
  final int lastSevenDaysSeconds;
  final Map<StudyTimeSource, int> secondsBySource;
  final int sessionCount;

  factory StudyTimeSummary.fromRecords(
    List<StudyTimeRecord> records, {
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    var total = 0;
    var todayTotal = 0;
    var weekTotal = 0;
    final bySource = <StudyTimeSource, int>{
      for (final source in StudyTimeSource.values) source: 0,
    };
    for (final record in records) {
      final duration = record.durationSeconds.clamp(0, 24 * 60 * 60);
      final local = record.recordedAt.toLocal();
      final date = DateTime(local.year, local.month, local.day);
      total += duration;
      bySource[record.source] = (bySource[record.source] ?? 0) + duration;
      if (date == today) todayTotal += duration;
      if (!date.isBefore(sevenDaysAgo) && !date.isAfter(today)) {
        weekTotal += duration;
      }
    }
    return StudyTimeSummary(
      totalSeconds: total,
      todaySeconds: todayTotal,
      lastSevenDaysSeconds: weekTotal,
      secondsBySource: Map.unmodifiable(bySource),
      sessionCount: records.length,
    );
  }
}

String formatStudyDuration(int seconds) {
  final safeSeconds = seconds.clamp(0, 999999999);
  if (safeSeconds > 0 && safeSeconds < 60) return '< 1 min';
  final hours = safeSeconds ~/ 3600;
  final minutes = (safeSeconds % 3600) ~/ 60;
  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}
