import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';

enum TriviaRushDuration {
  quick(60, '60 s', 'Una ronda rápida'),
  standard(90, '90 s', 'Equilibrio entre ritmo y precisión'),
  extended(120, '120 s', 'Más tiempo para construir combos');

  const TriviaRushDuration(this.seconds, this.label, this.description);

  final int seconds;
  final String label;
  final String description;

  static TriviaRushDuration? tryFromSeconds(int seconds) {
    for (final value in values) {
      if (value.seconds == seconds) return value;
    }
    return null;
  }
}

class TriviaRushConfig {
  const TriviaRushConfig({required this.areas, required this.duration});

  final List<AcademicArea> areas;
  final TriviaRushDuration duration;

  bool get isMixed => areas.length > 1;

  String get routeLocation => Uri(
    path: '/student/practice/trivia-rush/play',
    queryParameters: {
      'areas': areas.map((area) => area.backendValue).join(','),
      'segundos': duration.seconds.toString(),
    },
  ).toString();

  static TriviaRushConfig? tryFromUri(Uri uri) {
    final rawAreas = uri.queryParameters['areas'];
    final seconds = int.tryParse(uri.queryParameters['segundos'] ?? '');
    final duration = seconds == null
        ? null
        : TriviaRushDuration.tryFromSeconds(seconds);
    if (rawAreas == null || duration == null) return null;
    try {
      final areas = rawAreas
          .split(',')
          .where((value) => value.isNotEmpty)
          .map(AcademicArea.fromBackend)
          .toSet()
          .toList(growable: false);
      if (areas.isEmpty) return null;
      return TriviaRushConfig(areas: areas, duration: duration);
    } on Object {
      return null;
    }
  }
}

enum TriviaRushBooster {
  extraTime('Más 10 segundos', 'Añade diez segundos a esta ronda.'),
  fiftyFifty(
    'Descartar dos',
    'Oculta dos opciones incorrectas de la pregunta.',
  ),
  comboShield('Proteger combo', 'El próximo error no rompe tu combo.'),
  skip('Saltar pregunta', 'Avanza sin sumar ni restar puntos.'),
  secondChance(
    'Segunda oportunidad',
    'Permite corregir un primer error sin romper el combo.',
  );

  const TriviaRushBooster(this.label, this.description);

  final String label;
  final String description;
}

class TriviaRushSession {
  const TriviaRushSession({
    required this.attemptId,
    required this.questions,
    this.serverState,
  });

  final String attemptId;
  final List<PracticeQuestion> questions;
  final TriviaRushServerState? serverState;

  bool get isAuthoritative => serverState != null;
}

class TriviaRushAnswerEvaluation {
  const TriviaRushAnswerEvaluation({
    required this.questionId,
    required this.isCorrect,
    required this.correctAnswerId,
    required this.explanation,
    this.isFinal = true,
    this.canRetry = false,
    this.serverState,
  });

  final String questionId;
  final bool isCorrect;
  final String? correctAnswerId;
  final String? explanation;
  final bool isFinal;
  final bool canRetry;
  final TriviaRushServerState? serverState;
}

class TriviaRushBoosterActivation {
  const TriviaRushBoosterActivation({
    this.eliminatedAnswerIds = const {},
    this.serverState,
  });

  final Set<String> eliminatedAnswerIds;
  final TriviaRushServerState? serverState;
}

class TriviaRushScore {
  const TriviaRushScore({
    this.points = 0,
    this.combo = 0,
    this.bestCombo = 0,
    this.correctAnswers = 0,
    this.incorrectAnswers = 0,
    this.skippedQuestions = 0,
  });

  final int points;
  final int combo;
  final int bestCombo;
  final int correctAnswers;
  final int incorrectAnswers;
  final int skippedQuestions;

  int get multiplier => multiplierFor(combo);

  static int multiplierFor(int combo) => switch (combo) {
    >= 10 => 4,
    >= 6 => 3,
    >= 3 => 2,
    _ => 1,
  };

  TriviaRushScore registerCorrect() {
    final nextCombo = combo + 1;
    return TriviaRushScore(
      points: points + (100 * multiplierFor(nextCombo)),
      combo: nextCombo,
      bestCombo: nextCombo > bestCombo ? nextCombo : bestCombo,
      correctAnswers: correctAnswers + 1,
      incorrectAnswers: incorrectAnswers,
      skippedQuestions: skippedQuestions,
    );
  }

  TriviaRushScore registerIncorrect({bool protectCombo = false}) =>
      TriviaRushScore(
        points: points,
        combo: protectCombo ? combo : 0,
        bestCombo: bestCombo,
        correctAnswers: correctAnswers,
        incorrectAnswers: incorrectAnswers + 1,
        skippedQuestions: skippedQuestions,
      );

  TriviaRushScore registerSkip() => TriviaRushScore(
    points: points,
    combo: combo,
    bestCombo: bestCombo,
    correctAnswers: correctAnswers,
    incorrectAnswers: incorrectAnswers,
    skippedQuestions: skippedQuestions + 1,
  );
}

class TriviaRushReviewEntry {
  const TriviaRushReviewEntry({
    required this.question,
    required this.selectedAnswerId,
    required this.evaluation,
  });

  final PracticeQuestion question;
  final String selectedAnswerId;
  final TriviaRushAnswerEvaluation evaluation;
}

class TriviaRushWeakness {
  const TriviaRushWeakness({
    required this.area,
    required this.theme,
    required this.subtopic,
    required this.subtopicId,
    required this.errors,
  });

  final AcademicArea area;
  final String theme;
  final String subtopic;
  final String? subtopicId;
  final int errors;

  String? get studyRoute {
    final id = subtopicId?.trim() ?? '';
    if (id.isEmpty) return null;
    return '/student/practice/subtopic/${area.slug}/${Uri.encodeComponent(id)}';
  }
}

enum TriviaRushAttemptStatus {
  active,
  finished,
  expired,
  abandoned;

  bool get isTerminal => this != active;

  factory TriviaRushAttemptStatus.fromBackend(String value) => switch (value) {
    'ACTIVO' => active,
    'FINALIZADO' => finished,
    'EXPIRADO' => expired,
    'ABANDONADO' => abandoned,
    _ => throw FormatException('Estado de Trivia Rush desconocido: $value'),
  };
}

class TriviaRushServerState {
  const TriviaRushServerState({
    required this.attemptId,
    required this.status,
    required this.ruleVersion,
    required this.areas,
    required this.baseDurationSeconds,
    required this.extraTimeSeconds,
    required this.serverNow,
    required this.receivedAt,
    required this.startedAt,
    required this.expiresAt,
    required this.score,
    required this.currentIndex,
    required this.totalQuestions,
    required this.assisted,
    required this.comboShieldActive,
    required this.secondChanceActive,
    required this.eliminatedAnswerIds,
    required this.weaknesses,
    this.finishedAt,
    this.currentQuestion,
  });

  final String attemptId;
  final TriviaRushAttemptStatus status;
  final int ruleVersion;
  final List<AcademicArea> areas;
  final int baseDurationSeconds;
  final int extraTimeSeconds;
  final DateTime serverNow;
  final DateTime receivedAt;
  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime? finishedAt;
  final TriviaRushScore score;
  final int currentIndex;
  final int totalQuestions;
  final bool assisted;
  final bool comboShieldActive;
  final bool secondChanceActive;
  final Set<String> eliminatedAnswerIds;
  final PracticeQuestion? currentQuestion;
  final List<TriviaRushWeakness> weaknesses;

  bool get isTerminal => status.isTerminal;

  int secondsRemainingAt(DateTime deviceNow) {
    if (isTerminal) return 0;
    final authoritativeNow = _authoritativeNow(deviceNow);
    final milliseconds = expiresAt.difference(authoritativeNow).inMilliseconds;
    if (milliseconds <= 0) return 0;
    return (milliseconds / 1000).ceil();
  }

  int elapsedSecondsAt(DateTime deviceNow) {
    final authoritativeNow = isTerminal
        ? (finishedAt ?? serverNow)
        : _authoritativeNow(deviceNow);
    return authoritativeNow
        .difference(startedAt)
        .inSeconds
        .clamp(0, baseDurationSeconds + extraTimeSeconds);
  }

  DateTime _authoritativeNow(DateTime deviceNow) =>
      deviceNow.add(serverNow.difference(receivedAt));

  factory TriviaRushServerState.fromJson(
    Map<String, dynamic> json, {
    DateTime? receivedAt,
  }) {
    final received = receivedAt ?? DateTime.now();
    final attempt = _jsonMap(json['intento']);
    final marker = _jsonMap(attempt['marcador']);
    final progress = _jsonMap(attempt['progreso']);
    final activeBoosters = _jsonMap(attempt['potenciadoresActivos']);
    final result = _jsonMap(attempt['resultado']);
    final questionJson = attempt['pregunta'];
    return TriviaRushServerState(
      attemptId: attempt['id'] as String,
      status: TriviaRushAttemptStatus.fromBackend(attempt['estado'] as String),
      ruleVersion: _jsonInt(attempt['versionReglas']),
      areas: (attempt['areas'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .map(AcademicArea.fromBackend)
          .toList(growable: false),
      baseDurationSeconds: _jsonInt(attempt['duracionBaseSegundos']),
      extraTimeSeconds: _jsonInt(attempt['tiempoExtraSegundos']),
      serverNow: DateTime.parse(json['servidorAhora'] as String),
      receivedAt: received,
      startedAt: DateTime.parse(attempt['iniciadoEn'] as String),
      expiresAt: DateTime.parse(attempt['venceEn'] as String),
      finishedAt: _optionalDate(attempt['finalizadoEn']),
      score: TriviaRushScore(
        points: _jsonInt(marker['puntaje']),
        combo: _jsonInt(marker['comboActual']),
        bestCombo: _jsonInt(marker['mejorCombo']),
        correctAnswers: _jsonInt(marker['respuestasCorrectas']),
        incorrectAnswers: _jsonInt(marker['respuestasIncorrectas']),
        skippedQuestions: _jsonInt(marker['preguntasSaltadas']),
      ),
      currentIndex: _jsonInt(progress['indiceActual']),
      totalQuestions: _jsonInt(progress['totalPreguntas']),
      assisted: attempt['asistido'] == true,
      comboShieldActive: activeBoosters['escudoCombo'] == true,
      secondChanceActive: activeBoosters['segundaOportunidad'] == true,
      eliminatedAnswerIds:
          (activeBoosters['opcionesEliminadas'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toSet(),
      currentQuestion: questionJson is Map
          ? _serverQuestion(Map<String, dynamic>.from(questionJson))
          : null,
      weaknesses: (result['diagnostico'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => _serverWeakness(Map<String, dynamic>.from(item)))
          .toList(growable: false),
    );
  }
}

PracticeQuestion _serverQuestion(Map<String, dynamic> json) {
  final id = json['id'] as String;
  final context = json['contexto'] as String?;
  return PracticeQuestion(
    id: id,
    statement: json['enunciado'] as String,
    difficulty: json['dificultad'] as String? ?? '',
    imageUrl: json['imagenUrl'] as String?,
    options: (json['opciones'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => PracticeOption.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false),
    subtopicId: json['subtemaId'] as String?,
    subtopicName: json['subtema'] as String? ?? '',
    themeName: json['tema'] as String? ?? '',
    area: AcademicArea.fromBackend(json['area'] as String),
    caseContent: context == null || context.trim().isEmpty
        ? null
        : PracticeCase(
            id: 'trivia-context-$id',
            title: '',
            context: context,
            imageUrl: json['imagenUrl'] as String?,
          ),
  );
}

TriviaRushWeakness _serverWeakness(Map<String, dynamic> json) =>
    TriviaRushWeakness(
      area: AcademicArea.fromBackend(json['area'] as String),
      theme: json['tema'] as String? ?? '',
      subtopic: json['subtema'] as String? ?? '',
      subtopicId: json['subtemaId'] as String?,
      errors: _jsonInt(json['errores']),
    );

Map<String, dynamic> _jsonMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

int _jsonInt(Object? value) => value is num ? value.toInt() : 0;

DateTime? _optionalDate(Object? value) =>
    value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;

List<TriviaRushWeakness> triviaRushWeaknesses(
  Iterable<TriviaRushReviewEntry> review,
) {
  final grouped = <String, TriviaRushWeakness>{};
  for (final entry in review.where((entry) => !entry.evaluation.isCorrect)) {
    final question = entry.question;
    final routeId = question.subtopicId ?? '';
    final key = '${question.area.name}|${question.themeName}|$routeId';
    final current = grouped[key];
    grouped[key] = TriviaRushWeakness(
      area: question.area,
      theme: question.themeName,
      subtopic: question.subtopicName,
      subtopicId: question.subtopicId,
      errors: (current?.errors ?? 0) + 1,
    );
  }
  final result = grouped.values.toList(growable: false)
    ..sort((a, b) => b.errors.compareTo(a.errors));
  return result;
}
