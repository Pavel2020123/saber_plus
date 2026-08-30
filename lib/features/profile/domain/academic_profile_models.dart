import '../../academic/domain/academic_models.dart';
import '../../progress/domain/progress_models.dart';

class PersonalExamGoal {
  const PersonalExamGoal({required this.userId, required this.targetScore});

  static const minimumScore = 100;
  static const maximumScore = 500;

  final String userId;
  final int targetScore;

  static bool isValidScore(int value) =>
      value >= minimumScore && value <= maximumScore;
}

class ProfileAreaPerformance {
  const ProfileAreaPerformance({
    required this.area,
    required this.percentage,
    required this.answers,
  });

  final AcademicArea area;
  final double? percentage;
  final int answers;
}

class AcademicAreaInsights {
  const AcademicAreaInsights({
    required this.strongest,
    required this.needsReinforcement,
    required this.ranking,
  });

  final ProfileAreaPerformance? strongest;
  final ProfileAreaPerformance? needsReinforcement;
  final List<ProfileAreaPerformance> ranking;

  factory AcademicAreaInsights.fromSources({
    required ProgressDashboard progress,
    DiagnosticSummary? diagnostic,
  }) {
    final byArea = <AcademicArea, ProfileAreaPerformance>{};

    for (final entry in progress.byArea.entries) {
      if (entry.value.total <= 0) continue;
      byArea[entry.key] = ProfileAreaPerformance(
        area: entry.key,
        percentage: entry.value.successPercentage.clamp(0, 100),
        answers: entry.value.total,
      );
    }

    for (final result in diagnostic?.resultsByArea ?? const []) {
      if (result.totalQuestions <= 0) continue;
      byArea[result.area] = ProfileAreaPerformance(
        area: result.area,
        percentage: result.percentage.clamp(0, 100),
        answers: result.totalQuestions,
      );
    }

    final ranking = byArea.values.toList(growable: false)
      ..sort((left, right) {
        final byPercentage = (right.percentage ?? -1).compareTo(
          left.percentage ?? -1,
        );
        if (byPercentage != 0) return byPercentage;
        return left.area.index.compareTo(right.area.index);
      });

    ProfileAreaPerformance? resolve(
      AcademicArea? preferred,
      ProfileAreaPerformance? fallback,
    ) {
      if (preferred == null) return fallback;
      return byArea[preferred] ??
          ProfileAreaPerformance(area: preferred, percentage: null, answers: 0);
    }

    return AcademicAreaInsights(
      strongest: resolve(
        diagnostic?.strengthArea,
        ranking.isEmpty ? null : ranking.first,
      ),
      needsReinforcement: resolve(
        diagnostic?.priorityArea,
        ranking.isEmpty ? null : ranking.last,
      ),
      ranking: List.unmodifiable(ranking),
    );
  }

  static const empty = AcademicAreaInsights(
    strongest: null,
    needsReinforcement: null,
    ranking: [],
  );
}
