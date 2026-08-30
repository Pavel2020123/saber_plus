import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/academic/domain/academic_models.dart';
import 'package:saber_plus/features/practice/domain/practice_history_models.dart';
import 'package:saber_plus/features/profile/domain/score_projection.dart';
import 'package:saber_plus/features/progress/domain/progress_models.dart';
import 'package:saber_plus/features/study/domain/study_models.dart';

void main() {
  test('aplica la ponderación global sobre cinco materias', () {
    final history = SimulationHistory(
      total: 5,
      results: [
        for (final area in AcademicArea.values)
          _result('${area.slug}-1', area, 60, 25, DateTime(2026, 8, 20)),
      ],
    );

    final projection = ScoreProjection.calculate(
      simulationHistory: history,
      progress: ProgressDashboard.empty,
    );

    expect(projection, isNotNull);
    expect(projection!.estimatedGlobalScore, 300);
    expect(projection.confidence, ProjectionConfidence.high);
    expect(projection.lowerBound, 280);
    expect(projection.upperBound, 320);
  });

  test('prioriza simulacros recientes y completa áreas con el historial', () {
    final projection = ScoreProjection.calculate(
      simulationHistory: SimulationHistory(
        total: 2,
        results: [
          _result(
            'math-old',
            AcademicArea.mathematics,
            50,
            25,
            DateTime(2026, 8, 1),
          ),
          _result(
            'math-new',
            AcademicArea.mathematics,
            80,
            25,
            DateTime(2026, 8, 20),
          ),
        ],
      ),
      progress: _progressForAll(60),
    );

    expect(projection, isNotNull);
    expect(
      projection!.scoreFor(AcademicArea.mathematics)?.score,
      closeTo(70, 0.01),
    );
    expect(
      projection.scoreFor(AcademicArea.mathematics)?.source,
      ProjectionEvidenceSource.simulation,
    );
    expect(
      projection.scoreFor(AcademicArea.english)?.source,
      ProjectionEvidenceSource.answerHistory,
    );
    expect(projection.estimatedGlobalScore, 312);
    expect(projection.confidence, ProjectionConfidence.low);
  });

  test('no proyecta si falta evidencia de alguna materia', () {
    final byArea = Map<AcademicArea, AnswerHistorySummary>.from(
      _progressForAll(60).byArea,
    )..remove(AcademicArea.english);

    final projection = ScoreProjection.calculate(
      simulationHistory: const SimulationHistory(total: 0, results: []),
      progress: ProgressDashboard(
        study: StudyProgress.empty,
        answers: ProgressDashboard.emptyAnswers,
        byArea: byArea,
      ),
    );

    expect(projection, isNull);
  });
}

ProgressDashboard _progressForAll(double percentage) => ProgressDashboard(
  study: StudyProgress.empty,
  answers: ProgressDashboard.emptyAnswers,
  byArea: {
    for (final area in AcademicArea.values)
      area: AnswerHistorySummary(
        total: 10,
        correct: 6,
        incorrect: 4,
        successPercentage: percentage,
      ),
  },
);

SimulationHistoryResult _result(
  String id,
  AcademicArea area,
  double percentage,
  int questions,
  DateTime completedAt,
) => SimulationHistoryResult(
  id: id,
  area: area,
  totalQuestions: questions,
  correctAnswers: (questions * percentage / 100).round(),
  percentage: percentage,
  earnedXp: 0,
  completedAt: completedAt,
);
