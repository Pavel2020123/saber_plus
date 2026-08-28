import '../../academic/domain/academic_models.dart';
import '../../practice/domain/practice_history_models.dart';
import '../../practice/domain/practice_models.dart';
import '../../study/domain/study_models.dart';

class ProgressDashboard {
  const ProgressDashboard({
    required this.study,
    required this.answers,
    required this.byArea,
  });

  final StudyProgress study;
  final AnswerHistorySummary answers;
  final Map<AcademicArea, AnswerHistorySummary> byArea;

  AnswerHistorySummary performanceFor(AcademicArea area) =>
      byArea[area] ?? ProgressDashboard.emptyAnswers;

  static const emptyAnswers = AnswerHistorySummary(
    total: 0,
    correct: 0,
    incorrect: 0,
    successPercentage: 0,
  );

  static const empty = ProgressDashboard(
    study: StudyProgress.empty,
    answers: emptyAnswers,
    byArea: {},
  );
}

enum NotebookStatus {
  pending('PENDIENTE', 'Pendiente'),
  reviewing('REPASANDO', 'En repaso'),
  mastered('DOMINADO', 'Dominado');

  const NotebookStatus(this.backendValue, this.label);

  final String backendValue;
  final String label;

  factory NotebookStatus.fromBackend(String value) => NotebookStatus.values
      .firstWhere((status) => status.backendValue == value);
}

class NotebookFilter {
  const NotebookFilter({this.area, this.status});

  final AcademicArea? area;
  final NotebookStatus? status;
}

class NotebookSummary {
  const NotebookSummary({
    required this.total,
    required this.pending,
    required this.reviewing,
    required this.mastered,
  });

  final int total;
  final int pending;
  final int reviewing;
  final int mastered;

  factory NotebookSummary.fromJson(Map<String, dynamic> json) =>
      NotebookSummary(
        total: json['total'] as int? ?? 0,
        pending: json['pendientes'] as int? ?? 0,
        reviewing: json['repasando'] as int? ?? 0,
        mastered: json['dominados'] as int? ?? 0,
      );

  static const empty = NotebookSummary(
    total: 0,
    pending: 0,
    reviewing: 0,
    mastered: 0,
  );
}

class ErrorNotebook {
  const ErrorNotebook({required this.summary, required this.errors});

  final NotebookSummary summary;
  final List<ErrorNotebookItem> errors;

  factory ErrorNotebook.fromJson(Map<String, dynamic> json) => ErrorNotebook(
    summary: NotebookSummary.fromJson(
      Map<String, dynamic>.from(json['resumen'] as Map? ?? const {}),
    ),
    errors: (json['errores'] as List<dynamic>? ?? const [])
        .map(
          (item) => ErrorNotebookItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false),
  );

  static const empty = ErrorNotebook(
    summary: NotebookSummary.empty,
    errors: [],
  );
}

class ErrorNotebookItem {
  const ErrorNotebookItem({
    required this.questionId,
    required this.statement,
    required this.area,
    required this.theme,
    required this.subtopic,
    required this.timesFailed,
    required this.lastFailedAt,
    required this.note,
    required this.status,
    this.explanation,
    this.difficulty,
    this.selectedAnswer,
    this.correctAnswer,
    this.caseTitle,
  });

  final String questionId;
  final String statement;
  final String? explanation;
  final String? difficulty;
  final AcademicArea area;
  final String theme;
  final String subtopic;
  final int timesFailed;
  final DateTime lastFailedAt;
  final NotebookAnswer? selectedAnswer;
  final NotebookAnswer? correctAnswer;
  final String? caseTitle;
  final String note;
  final NotebookStatus status;

  factory ErrorNotebookItem.fromJson(Map<String, dynamic> json) {
    final selected = json['respuestaSeleccionada'];
    final correct = json['respuestaCorrecta'];
    final caseContent = json['caso'];
    return ErrorNotebookItem(
      questionId: json['preguntaId'] as String,
      statement: json['enunciado'] as String? ?? '',
      explanation: _optionalText(json['explicacion']),
      difficulty: _optionalText(json['dificultad']),
      area: AcademicArea.fromBackend(json['area'] as String),
      theme: json['tema'] as String? ?? '',
      subtopic: json['subtema'] as String? ?? '',
      timesFailed: json['vecesFallada'] as int? ?? 1,
      lastFailedAt: DateTime.parse(json['ultimoErrorEn'] as String).toLocal(),
      selectedAnswer: selected is Map
          ? NotebookAnswer.fromJson(Map<String, dynamic>.from(selected))
          : null,
      correctAnswer: correct is Map
          ? NotebookAnswer.fromJson(Map<String, dynamic>.from(correct))
          : null,
      caseTitle: caseContent is Map
          ? _optionalText(caseContent['titulo'])
          : null,
      note: json['nota'] as String? ?? '',
      status: NotebookStatus.fromBackend(json['estado'] as String),
    );
  }
}

class NotebookAnswer {
  const NotebookAnswer({
    required this.id,
    required this.text,
    this.explanation,
  });

  final String id;
  final String text;
  final String? explanation;

  factory NotebookAnswer.fromJson(Map<String, dynamic> json) => NotebookAnswer(
    id: json['id'] as String,
    text: json['texto'] as String? ?? '',
    explanation: _optionalText(json['explicacion']),
  );
}

String? _optionalText(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

class AdaptiveProfile {
  const AdaptiveProfile({
    required this.analyzedAttempts,
    required this.targetLevel,
    required this.areaPerformance,
    required this.priorityAreas,
    required this.recommendedMix,
    this.recentAccuracy,
  });

  final int analyzedAttempts;
  final double? recentAccuracy;
  final PracticeDifficulty targetLevel;
  final List<AdaptiveAreaPerformance> areaPerformance;
  final List<AcademicArea> priorityAreas;
  final AdaptiveDifficultyMix recommendedMix;

  factory AdaptiveProfile.fromJson(
    Map<String, dynamic> json,
  ) => AdaptiveProfile(
    analyzedAttempts: json['intentosAnalizados'] as int? ?? 0,
    recentAccuracy: (json['precisionReciente'] as num?)?.toDouble(),
    targetLevel: PracticeDifficulty.fromBackend(
      json['nivelObjetivo'] as String,
    ),
    areaPerformance: (json['rendimientoPorArea'] as List<dynamic>? ?? const [])
        .map(
          (item) => AdaptiveAreaPerformance.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false),
    priorityAreas: (json['areasPrioritarias'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map(AcademicArea.fromBackend)
        .toList(growable: false),
    recommendedMix: AdaptiveDifficultyMix.fromJson(
      Map<String, dynamic>.from(json['mezclaRecomendada'] as Map? ?? const {}),
    ),
  );
}

class AdaptiveAreaPerformance {
  const AdaptiveAreaPerformance({
    required this.area,
    required this.attempts,
    required this.priority,
    this.accuracy,
  });

  final AcademicArea area;
  final int attempts;
  final double? accuracy;
  final int priority;

  factory AdaptiveAreaPerformance.fromJson(Map<String, dynamic> json) =>
      AdaptiveAreaPerformance(
        area: AcademicArea.fromBackend(json['area'] as String),
        attempts: json['intentos'] as int? ?? 0,
        accuracy: (json['precision'] as num?)?.toDouble(),
        priority: json['prioridad'] as int? ?? 0,
      );
}

class AdaptiveDifficultyMix {
  const AdaptiveDifficultyMix({
    required this.basic,
    required this.medium,
    required this.advanced,
  });

  final int basic;
  final int medium;
  final int advanced;

  factory AdaptiveDifficultyMix.fromJson(Map<String, dynamic> json) =>
      AdaptiveDifficultyMix(
        basic: json['BASICO'] as int? ?? 0,
        medium: json['MEDIO'] as int? ?? 0,
        advanced: json['AVANZADO'] as int? ?? 0,
      );
}

class AdaptiveSessionStart {
  const AdaptiveSessionStart({required this.session, required this.plan});

  final PracticeSession session;
  final AdaptiveSessionPlan plan;

  factory AdaptiveSessionStart.fromJson(Map<String, dynamic> json) =>
      AdaptiveSessionStart(
        session: PracticeSession.fromAdaptiveJson(json),
        plan: AdaptiveSessionPlan.fromJson(
          Map<String, dynamic>.from(json['adaptacion'] as Map? ?? const {}),
        ),
      );
}

class AdaptiveSessionPlan {
  const AdaptiveSessionPlan({
    required this.targetLevel,
    required this.priorityAreas,
    required this.questionMix,
    this.recentAccuracy,
  });

  final PracticeDifficulty targetLevel;
  final double? recentAccuracy;
  final List<AcademicArea> priorityAreas;
  final AdaptiveDifficultyMix questionMix;

  factory AdaptiveSessionPlan.fromJson(Map<String, dynamic> json) =>
      AdaptiveSessionPlan(
        targetLevel: PracticeDifficulty.fromBackend(
          json['nivelObjetivo'] as String,
        ),
        recentAccuracy: (json['precisionReciente'] as num?)?.toDouble(),
        priorityAreas: (json['areasPrioritarias'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .map(AcademicArea.fromBackend)
            .toList(growable: false),
        questionMix: AdaptiveDifficultyMix.fromJson(
          Map<String, dynamic>.from(json['mezcla'] as Map? ?? const {}),
        ),
      );
}

class AdaptiveGradeResult {
  const AdaptiveGradeResult({required this.result, required this.nextProfile});

  final PracticeResult result;
  final AdaptiveProfile nextProfile;

  factory AdaptiveGradeResult.fromJson(Map<String, dynamic> json) =>
      AdaptiveGradeResult(
        result: PracticeResult.fromJson(json),
        nextProfile: AdaptiveProfile.fromJson(
          Map<String, dynamic>.from(
            json['perfilSiguiente'] as Map? ?? const {},
          ),
        ),
      );
}
