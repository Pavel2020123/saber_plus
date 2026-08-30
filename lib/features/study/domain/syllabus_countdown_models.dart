import '../../academic/domain/academic_models.dart';
import 'study_models.dart';

enum SyllabusPaceStatus {
  dateMissing,
  examElapsed,
  noContent,
  completed,
  manageable,
  demanding,
  intensive,
}

class SyllabusAreaCountdown {
  const SyllabusAreaCountdown({
    required this.area,
    required this.totalSubtopics,
    required this.completedSubtopics,
    required this.inProgressSubtopics,
    required this.averagePercentage,
    required this.pendingSubtopics,
    required this.requiredPerWeek,
  });

  final AcademicArea area;
  final int totalSubtopics;
  final int completedSubtopics;
  final int inProgressSubtopics;
  final int averagePercentage;
  final List<String> pendingSubtopics;
  final double requiredPerWeek;

  int get remainingSubtopics => totalSubtopics - completedSubtopics;
}

class SyllabusCountdown {
  const SyllabusCountdown({
    required this.exam,
    required this.daysRemaining,
    required this.totalSubtopics,
    required this.completedSubtopics,
    required this.inProgressSubtopics,
    required this.requiredPerWeek,
    required this.status,
    required this.areas,
  });

  final ActiveExam? exam;
  final int? daysRemaining;
  final int totalSubtopics;
  final int completedSubtopics;
  final int inProgressSubtopics;
  final double requiredPerWeek;
  final SyllabusPaceStatus status;
  final List<SyllabusAreaCountdown> areas;

  int get remainingSubtopics => totalSubtopics - completedSubtopics;

  factory SyllabusCountdown.calculate({
    required List<StudyCatalog> catalogs,
    required StudyProgress progress,
    required ActiveExam? exam,
    required DateTime now,
  }) {
    final days = exam?.daysRemaining(now);
    final weeksAvailable = days != null && days > 0 ? days / 7 : 0.0;
    var total = 0;
    var completed = 0;
    var inProgress = 0;
    final areaCountdowns = <SyllabusAreaCountdown>[];

    for (final area in AcademicArea.values) {
      final catalog = _catalogFor(catalogs, area);
      final subtopics =
          catalog?.themes
              .expand((theme) => theme.subtopics)
              .toList(growable: false) ??
          const <StudySubtopic>[];
      var areaCompleted = 0;
      var areaInProgress = 0;
      var percentageTotal = 0;
      final pending = <String>[];
      for (final subtopic in subtopics) {
        final percentage = progress.percentageFor(subtopic.id).clamp(0, 100);
        percentageTotal += percentage;
        if (percentage >= 100) {
          areaCompleted++;
        } else {
          pending.add(subtopic.name);
          if (percentage > 0) areaInProgress++;
        }
      }
      final remaining = subtopics.length - areaCompleted;
      areaCountdowns.add(
        SyllabusAreaCountdown(
          area: area,
          totalSubtopics: subtopics.length,
          completedSubtopics: areaCompleted,
          inProgressSubtopics: areaInProgress,
          averagePercentage: subtopics.isEmpty
              ? 0
              : (percentageTotal / subtopics.length).round(),
          pendingSubtopics: List.unmodifiable(pending),
          requiredPerWeek: weeksAvailable > 0 ? remaining / weeksAvailable : 0,
        ),
      );
      total += subtopics.length;
      completed += areaCompleted;
      inProgress += areaInProgress;
    }

    areaCountdowns.sort((left, right) {
      final remaining = right.remainingSubtopics.compareTo(
        left.remainingSubtopics,
      );
      if (remaining != 0) return remaining;
      final progress = left.averagePercentage.compareTo(
        right.averagePercentage,
      );
      if (progress != 0) return progress;
      return left.area.index.compareTo(right.area.index);
    });

    final remaining = total - completed;
    final requiredPerWeek = weeksAvailable > 0
        ? remaining / weeksAvailable
        : 0.0;
    final status = total == 0
        ? SyllabusPaceStatus.noContent
        : remaining == 0
        ? SyllabusPaceStatus.completed
        : exam == null
        ? SyllabusPaceStatus.dateMissing
        : days! <= 0
        ? SyllabusPaceStatus.examElapsed
        : requiredPerWeek <= 2
        ? SyllabusPaceStatus.manageable
        : requiredPerWeek <= 4
        ? SyllabusPaceStatus.demanding
        : SyllabusPaceStatus.intensive;

    return SyllabusCountdown(
      exam: exam,
      daysRemaining: days,
      totalSubtopics: total,
      completedSubtopics: completed,
      inProgressSubtopics: inProgress,
      requiredPerWeek: requiredPerWeek,
      status: status,
      areas: List.unmodifiable(areaCountdowns),
    );
  }
}

StudyCatalog? _catalogFor(List<StudyCatalog> catalogs, AcademicArea area) {
  for (final catalog in catalogs) {
    if (catalog.area == area) return catalog;
  }
  return null;
}
