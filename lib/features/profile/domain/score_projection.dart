import '../../academic/domain/academic_models.dart';
import '../../practice/domain/practice_history_models.dart';
import '../../progress/domain/progress_models.dart';

enum ProjectionConfidence {
  low('Baja'),
  medium('Media'),
  high('Alta');

  const ProjectionConfidence(this.label);

  final String label;
}

enum ProjectionEvidenceSource {
  simulation('Simulacros por materia'),
  answerHistory('Respuestas registradas'),
  diagnostic('Diagnóstico');

  const ProjectionEvidenceSource(this.label);

  final String label;
}

class ProjectedAreaScore {
  const ProjectedAreaScore({
    required this.area,
    required this.score,
    required this.source,
    required this.evidenceQuestions,
  });

  final AcademicArea area;
  final double score;
  final ProjectionEvidenceSource source;
  final int evidenceQuestions;
}

class ScoreProjection {
  const ScoreProjection({
    required this.estimatedGlobalScore,
    required this.lowerBound,
    required this.upperBound,
    required this.confidence,
    required this.areaScores,
    required this.simulatedAreaCount,
    required this.simulationQuestionCount,
  });

  final int estimatedGlobalScore;
  final int lowerBound;
  final int upperBound;
  final ProjectionConfidence confidence;
  final List<ProjectedAreaScore> areaScores;
  final int simulatedAreaCount;
  final int simulationQuestionCount;

  ProjectedAreaScore? scoreFor(AcademicArea area) {
    for (final score in areaScores) {
      if (score.area == area) return score;
    }
    return null;
  }

  static ScoreProjection? calculate({
    required SimulationHistory simulationHistory,
    required ProgressDashboard progress,
    DiagnosticSummary? diagnostic,
  }) {
    final scores = <AcademicArea, ProjectedAreaScore>{};
    var simulatedAreas = 0;
    var simulationQuestions = 0;

    for (final area in AcademicArea.values) {
      final simulations =
          simulationHistory.results
              .where(
                (result) => result.area == area && result.totalQuestions > 0,
              )
              .toList()
            ..sort(
              (left, right) => left.completedAt.compareTo(right.completedAt),
            );
      if (simulations.isEmpty) continue;

      final recent = simulations.length <= 3
          ? simulations
          : simulations.sublist(simulations.length - 3);
      var weightedScore = 0.0;
      var totalWeight = 0;
      var questions = 0;
      for (var index = 0; index < recent.length; index++) {
        final weight = index + 1;
        weightedScore += recent[index].percentage.clamp(0, 100) * weight;
        totalWeight += weight;
        questions += recent[index].totalQuestions;
      }
      scores[area] = ProjectedAreaScore(
        area: area,
        score: weightedScore / totalWeight,
        source: ProjectionEvidenceSource.simulation,
        evidenceQuestions: questions,
      );
      simulatedAreas++;
      simulationQuestions += questions;
    }

    for (final area in AcademicArea.values) {
      if (scores.containsKey(area)) continue;
      final summary = progress.byArea[area];
      if (summary == null || summary.total <= 0) continue;
      scores[area] = ProjectedAreaScore(
        area: area,
        score: summary.successPercentage.clamp(0, 100),
        source: ProjectionEvidenceSource.answerHistory,
        evidenceQuestions: summary.total,
      );
    }

    for (final result in diagnostic?.resultsByArea ?? const []) {
      if (scores.containsKey(result.area) || result.totalQuestions <= 0) {
        continue;
      }
      scores[result.area] = ProjectedAreaScore(
        area: result.area,
        score: result.percentage.clamp(0, 100),
        source: ProjectionEvidenceSource.diagnostic,
        evidenceQuestions: result.totalQuestions,
      );
    }

    if (scores.length < AcademicArea.values.length) return null;

    final weightedAreaTotal =
        3 * scores[AcademicArea.criticalReading]!.score +
        3 * scores[AcademicArea.mathematics]!.score +
        3 * scores[AcademicArea.socialSciences]!.score +
        3 * scores[AcademicArea.naturalSciences]!.score +
        scores[AcademicArea.english]!.score;
    final estimated = ((weightedAreaTotal / 13) * 5).round().clamp(0, 500);
    final confidence = switch ((simulatedAreas, simulationQuestions)) {
      (5, >= 100) => ProjectionConfidence.high,
      (>= 3, >= 60) => ProjectionConfidence.medium,
      _ => ProjectionConfidence.low,
    };
    final margin = switch (confidence) {
      ProjectionConfidence.high => 20,
      ProjectionConfidence.medium => 35,
      ProjectionConfidence.low => 55,
    };

    return ScoreProjection(
      estimatedGlobalScore: estimated,
      lowerBound: (estimated - margin).clamp(0, 500),
      upperBound: (estimated + margin).clamp(0, 500),
      confidence: confidence,
      areaScores: AcademicArea.values
          .map((area) => scores[area]!)
          .toList(growable: false),
      simulatedAreaCount: simulatedAreas,
      simulationQuestionCount: simulationQuestions,
    );
  }
}
