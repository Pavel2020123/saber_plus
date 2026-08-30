import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/domain/practice_history_models.dart';
import 'package:saber_plus/features/practice/domain/simulation_comparison.dart';

void main() {
  test('ordena intentos y calcula una mejora sin alterar sus puntajes', () {
    final recent = _result(
      id: 'recent',
      percentage: 76,
      correct: 19,
      daysAgo: 1,
    );
    final previous = _result(
      id: 'previous',
      percentage: 60,
      correct: 15,
      daysAgo: 8,
    );

    final comparison = SimulationComparison.between(recent, previous)!;

    expect(comparison.previous.id, 'previous');
    expect(comparison.current.id, 'recent');
    expect(comparison.percentageDelta, 16);
    expect(comparison.correctAnswersDelta, 4);
    expect(comparison.direction, SimulationTrendDirection.improved);
  });

  test('solo permite comparar dos intentos distintos de la misma materia', () {
    final mathematics = _result(
      id: 'math',
      percentage: 70,
      correct: 18,
      daysAgo: 2,
    );
    final reading = _result(
      id: 'reading',
      percentage: 70,
      correct: 18,
      daysAgo: 1,
      area: AcademicArea.criticalReading,
    );

    expect(SimulationComparison.between(mathematics, mathematics), isNull);
    expect(SimulationComparison.between(mathematics, reading), isNull);
  });

  test('detecta áreas comparables y construye su tendencia cronológica', () {
    final history = SimulationHistory(
      total: 3,
      results: [
        _result(id: 'new', percentage: 72, correct: 18, daysAgo: 1),
        _result(id: 'old', percentage: 68, correct: 17, daysAgo: 9),
        _result(
          id: 'reading',
          percentage: 80,
          correct: 20,
          daysAgo: 2,
          area: AcademicArea.criticalReading,
        ),
      ],
    );

    expect(comparableSimulationAreas(history), [AcademicArea.mathematics]);
    final trend = SimulationAreaTrend.fromHistory(
      history,
      AcademicArea.mathematics,
    );
    expect(trend.results.map((item) => item.id), ['old', 'new']);
    expect(trend.latestComparison?.direction, SimulationTrendDirection.stable);
  });
}

SimulationHistoryResult _result({
  required String id,
  required double percentage,
  required int correct,
  required int daysAgo,
  AcademicArea area = AcademicArea.mathematics,
}) => SimulationHistoryResult(
  id: id,
  area: area,
  totalQuestions: 25,
  correctAnswers: correct,
  percentage: percentage,
  earnedXp: correct * 10,
  completedAt: DateTime(2026, 8, 30).subtract(Duration(days: daysAgo)),
);
