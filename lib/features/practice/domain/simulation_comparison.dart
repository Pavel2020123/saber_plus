import '../../academic/domain/academic_models.dart';
import 'practice_history_models.dart';

enum SimulationTrendDirection { improved, stable, declined }

class SimulationComparison {
  SimulationComparison._({required this.previous, required this.current});

  final SimulationHistoryResult previous;
  final SimulationHistoryResult current;

  AcademicArea get area => current.area;
  double get percentageDelta => current.percentage - previous.percentage;
  int get correctAnswersDelta =>
      current.correctAnswers - previous.correctAnswers;

  SimulationTrendDirection get direction {
    if (percentageDelta >= 5) return SimulationTrendDirection.improved;
    if (percentageDelta <= -5) return SimulationTrendDirection.declined;
    return SimulationTrendDirection.stable;
  }

  static SimulationComparison? between(
    SimulationHistoryResult first,
    SimulationHistoryResult second,
  ) {
    if (first.id == second.id || first.area != second.area) return null;
    final firstIsPrevious = !first.completedAt.isAfter(second.completedAt);
    return SimulationComparison._(
      previous: firstIsPrevious ? first : second,
      current: firstIsPrevious ? second : first,
    );
  }
}

class SimulationAreaTrend {
  SimulationAreaTrend._({required this.area, required this.results});

  final AcademicArea area;
  final List<SimulationHistoryResult> results;

  SimulationComparison? get latestComparison => results.length < 2
      ? null
      : SimulationComparison.between(results[results.length - 2], results.last);

  factory SimulationAreaTrend.fromHistory(
    SimulationHistory history,
    AcademicArea area,
  ) {
    final results = history.results.where((item) => item.area == area).toList()
      ..sort((left, right) => left.completedAt.compareTo(right.completedAt));
    return SimulationAreaTrend._(
      area: area,
      results: List.unmodifiable(results),
    );
  }
}

List<AcademicArea> comparableSimulationAreas(SimulationHistory history) =>
    AcademicArea.values
        .where(
          (area) =>
              history.results.where((item) => item.area == area).length >= 2,
        )
        .toList(growable: false);
