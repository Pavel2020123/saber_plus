import '../../academic/domain/academic_models.dart';

class SimulationHistory {
  const SimulationHistory({required this.total, required this.results});

  final int total;
  final List<SimulationHistoryResult> results;

  factory SimulationHistory.fromJson(Map<String, dynamic> json) =>
      SimulationHistory(
        total: json['totalSimulacros'] as int? ?? 0,
        results: (json['resultados'] as List<dynamic>? ?? const [])
            .map(
              (item) => SimulationHistoryResult.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(growable: false),
      );
}

class SimulationHistoryResult {
  const SimulationHistoryResult({
    required this.id,
    required this.area,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
    required this.earnedXp,
    required this.completedAt,
  });

  final String id;
  final AcademicArea area;
  final int totalQuestions;
  final int correctAnswers;
  final double percentage;
  final int earnedXp;
  final DateTime completedAt;

  factory SimulationHistoryResult.fromJson(Map<String, dynamic> json) =>
      SimulationHistoryResult(
        id: json['id'] as String,
        area: AcademicArea.fromBackend(json['area'] as String),
        totalQuestions: json['totalPreguntas'] as int? ?? 0,
        correctAnswers: json['respuestasCorrectas'] as int? ?? 0,
        percentage: (json['puntaje'] as num?)?.toDouble() ?? 0,
        earnedXp: json['xpGanado'] as int? ?? 0,
        completedAt: DateTime.parse(json['fechaRealizado'] as String).toLocal(),
      );
}

enum AnswerOutcomeFilter { all, correct, incorrect }

class AnswerHistoryFilter {
  const AnswerHistoryFilter({
    this.area,
    this.outcome = AnswerOutcomeFilter.all,
    this.limit = 50,
  });

  final AcademicArea? area;
  final AnswerOutcomeFilter outcome;
  final int limit;
}

class AnswerHistory {
  const AnswerHistory({required this.summary, required this.answers});

  final AnswerHistorySummary summary;
  final List<AnswerHistoryItem> answers;

  factory AnswerHistory.fromJson(Map<String, dynamic> json) => AnswerHistory(
    summary: AnswerHistorySummary.fromJson(
      Map<String, dynamic>.from(json['resumen'] as Map? ?? const {}),
    ),
    answers: (json['respuestas'] as List<dynamic>? ?? const [])
        .map(
          (item) => AnswerHistoryItem.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false),
  );
}

class AnswerHistorySummary {
  const AnswerHistorySummary({
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.successPercentage,
  });

  final int total;
  final int correct;
  final int incorrect;
  final double successPercentage;

  factory AnswerHistorySummary.fromJson(Map<String, dynamic> json) =>
      AnswerHistorySummary(
        total: json['total'] as int? ?? 0,
        correct: json['correctas'] as int? ?? 0,
        incorrect: json['incorrectas'] as int? ?? 0,
        successPercentage:
            (json['porcentajeAciertos'] as num?)?.toDouble() ?? 0,
      );
}

enum PracticeOrigin {
  simulation('SIMULACRO', 'Simulacro por área'),
  random('PERSONALIZADO', 'Preguntas aleatorias'),
  subtopic('PRACTICA', 'Práctica de tema'),
  diagnostic('DIAGNOSTICO', 'Diagnóstico inicial'),
  battle('BATALLA', 'Batalla'),
  adaptive('ADAPTATIVO', 'Repaso inteligente');

  const PracticeOrigin(this.backendValue, this.label);

  final String backendValue;
  final String label;

  factory PracticeOrigin.fromBackend(String value) => PracticeOrigin.values
      .firstWhere((origin) => origin.backendValue == value);
}

class AnswerHistoryItem {
  const AnswerHistoryItem({
    required this.id,
    required this.sessionId,
    required this.questionId,
    required this.statement,
    required this.difficulty,
    required this.area,
    required this.origin,
    required this.isCorrect,
    required this.answeredAt,
    required this.theme,
    required this.subtopic,
    this.explanation,
    this.responseTimeSeconds,
    this.selectedAnswer,
    this.correctAnswer,
    this.caseTitle,
  });

  final String id;
  final String sessionId;
  final String questionId;
  final String statement;
  final String? explanation;
  final String difficulty;
  final AcademicArea area;
  final PracticeOrigin origin;
  final bool isCorrect;
  final int? responseTimeSeconds;
  final DateTime answeredAt;
  final HistoryAnswer? selectedAnswer;
  final HistoryAnswer? correctAnswer;
  final String theme;
  final String subtopic;
  final String? caseTitle;

  factory AnswerHistoryItem.fromJson(Map<String, dynamic> json) {
    final selected = json['respuestaSeleccionada'];
    final correct = json['respuestaCorrecta'];
    final caseContent = json['caso'];
    return AnswerHistoryItem(
      id: json['id'] as String,
      sessionId: json['sesionId'] as String,
      questionId: json['preguntaId'] as String,
      statement: json['enunciado'] as String,
      explanation: _optionalText(json['explicacion']),
      difficulty: json['dificultad'] as String? ?? '',
      area: AcademicArea.fromBackend(json['area'] as String),
      origin: PracticeOrigin.fromBackend(json['origen'] as String),
      isCorrect: json['esCorrecta'] as bool? ?? false,
      responseTimeSeconds: (json['tiempoRespuestaSegundos'] as num?)?.toInt(),
      answeredAt: DateTime.parse(json['fechaRespuesta'] as String).toLocal(),
      selectedAnswer: selected is Map
          ? HistoryAnswer.fromJson(Map<String, dynamic>.from(selected))
          : null,
      correctAnswer: correct is Map
          ? HistoryAnswer.fromJson(Map<String, dynamic>.from(correct))
          : null,
      theme: json['tema'] as String? ?? '',
      subtopic: json['subtema'] as String? ?? '',
      caseTitle: caseContent is Map
          ? _optionalText(caseContent['titulo'])
          : null,
    );
  }
}

class HistoryAnswer {
  const HistoryAnswer({required this.id, required this.text, this.explanation});

  final String id;
  final String text;
  final String? explanation;

  factory HistoryAnswer.fromJson(Map<String, dynamic> json) => HistoryAnswer(
    id: json['id'] as String,
    text: json['texto'] as String,
    explanation: _optionalText(json['explicacion']),
  );
}

String? _optionalText(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}
