import '../../academic/domain/academic_models.dart';

class PracticeSession {
  const PracticeSession({
    required this.attemptId,
    required this.area,
    required this.subtopicId,
    required this.questions,
    this.isRandom = false,
    this.isSimulation = false,
    this.isAdaptive = false,
    this.selectedAreas = const [],
  });

  final String attemptId;
  final AcademicArea area;
  final String subtopicId;
  final List<PracticeQuestion> questions;
  final bool isRandom;
  final bool isSimulation;
  final bool isAdaptive;
  final List<AcademicArea> selectedAreas;

  List<AcademicArea> get areas =>
      selectedAreas.isEmpty ? [area] : selectedAreas;

  factory PracticeSession.fromJson(
    Map<String, dynamic> json, {
    required AcademicArea area,
    required String subtopicId,
  }) => PracticeSession(
    attemptId: json['intentoId'] as String,
    area: area,
    subtopicId: subtopicId,
    questions: (json['preguntas'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              PracticeQuestion.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );

  factory PracticeSession.fromRandomJson(
    Map<String, dynamic> json, {
    required List<AcademicArea> areas,
  }) => PracticeSession(
    attemptId: json['intentoId'] as String,
    area: areas.first,
    subtopicId: '',
    isRandom: true,
    selectedAreas: List.unmodifiable(areas),
    questions: (json['preguntas'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              PracticeQuestion.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );

  factory PracticeSession.fromSimulationJson(
    Map<String, dynamic> json, {
    required AcademicArea area,
  }) => PracticeSession(
    attemptId: json['intentoId'] as String,
    area: area,
    subtopicId: '',
    isSimulation: true,
    questions: (json['preguntas'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              PracticeQuestion.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );

  factory PracticeSession.fromAdaptiveJson(Map<String, dynamic> json) {
    final questions = (json['preguntas'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              PracticeQuestion.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
    final areas = questions
        .map((question) => question.area)
        .toSet()
        .toList(growable: false);
    return PracticeSession(
      attemptId: json['intentoId'] as String,
      area: areas.isEmpty ? AcademicArea.mathematics : areas.first,
      subtopicId: '',
      isAdaptive: true,
      selectedAreas: areas,
      questions: questions,
    );
  }

  factory PracticeSession.fromStoredJson(
    Map<String, dynamic> json,
  ) => PracticeSession(
    attemptId: json['attemptId'] as String,
    area: AcademicArea.fromBackend(json['area'] as String),
    subtopicId: json['subtopicId'] as String? ?? '',
    isRandom: json['isRandom'] as bool? ?? false,
    isSimulation: json['isSimulation'] as bool? ?? false,
    isAdaptive: json['isAdaptive'] as bool? ?? false,
    selectedAreas: (json['selectedAreas'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map(AcademicArea.fromBackend)
        .toList(growable: false),
    questions: (json['questions'] as List<dynamic>? ?? const [])
        .map(
          (item) =>
              PracticeQuestion.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false),
  );

  Map<String, dynamic> toStoredJson() => {
    'attemptId': attemptId,
    'area': area.backendValue,
    'subtopicId': subtopicId,
    'isRandom': isRandom,
    'isSimulation': isSimulation,
    'isAdaptive': isAdaptive,
    'selectedAreas': areas.map((item) => item.backendValue).toList(),
    'questions': questions.map((item) => item.toJson()).toList(),
  };
}

enum PracticeDifficulty {
  easy('BASICO', 'Básica'),
  medium('MEDIO', 'Media'),
  hard('AVANZADO', 'Avanzada');

  const PracticeDifficulty(this.backendValue, this.label);

  final String backendValue;
  final String label;

  factory PracticeDifficulty.fromBackend(String value) => PracticeDifficulty
      .values
      .firstWhere((difficulty) => difficulty.backendValue == value);
}

class RandomPracticeConfig {
  const RandomPracticeConfig({
    required this.areas,
    required this.questionCount,
    this.difficulty,
  });

  final List<AcademicArea> areas;
  final int questionCount;
  final PracticeDifficulty? difficulty;

  String get routeLocation {
    final query = <String, String>{
      'areas': areas.map((area) => area.backendValue).join(','),
      'cantidad': questionCount.toString(),
      if (difficulty case final value?) 'dificultad': value.backendValue,
    };
    return Uri(
      path: '/student/practice/random/session',
      queryParameters: query,
    ).toString();
  }

  static RandomPracticeConfig? tryFromUri(Uri uri) {
    final rawAreas = uri.queryParameters['areas'];
    if (rawAreas == null) return null;
    try {
      final areas = rawAreas
          .split(',')
          .where((value) => value.isNotEmpty)
          .map(AcademicArea.fromBackend)
          .toSet()
          .toList(growable: false);
      final count = int.tryParse(uri.queryParameters['cantidad'] ?? '10');
      final difficultyValue = uri.queryParameters['dificultad'];
      if (areas.isEmpty || count == null || count < 1 || count > 100) {
        return null;
      }
      return RandomPracticeConfig(
        areas: areas,
        questionCount: count,
        difficulty: difficultyValue == null
            ? null
            : PracticeDifficulty.fromBackend(difficultyValue),
      );
    } on Object {
      return null;
    }
  }
}

enum OfficialSimulationBlock {
  morning('am', 'Jornada AM', 'Primera jornada'),
  afternoon('pm', 'Jornada PM', 'Segunda jornada');

  const OfficialSimulationBlock(this.slug, this.label, this.description);

  static const questionCount = 75;
  static const totalQuestionCount = questionCount * 2;

  final String slug;
  final String label;
  final String description;

  RandomPracticeConfig get practiceConfig => const RandomPracticeConfig(
    areas: AcademicArea.values,
    questionCount: questionCount,
  );

  String get routeLocation => '/student/practice/official/$slug';

  bool accepts(PracticeSession session) {
    final areas = session.questions.map((question) => question.area).toSet();
    return session.isRandom &&
        session.questions.length == questionCount &&
        areas.containsAll(AcademicArea.values);
  }

  static OfficialSimulationBlock? tryFromSlug(String value) {
    for (final block in values) {
      if (block.slug == value) return block;
    }
    return null;
  }
}

class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.statement,
    required this.difficulty,
    required this.options,
    required this.subtopicName,
    required this.themeName,
    required this.area,
    this.subtopicId,
    this.imageUrl,
    this.orderInCase,
    this.caseContent,
  });

  final String id;
  final String statement;
  final String difficulty;
  final String? imageUrl;
  final int? orderInCase;
  final PracticeCase? caseContent;
  final List<PracticeOption> options;
  final String? subtopicId;
  final String subtopicName;
  final String themeName;
  final AcademicArea area;

  factory PracticeQuestion.fromJson(Map<String, dynamic> json) {
    final subtopic = Map<String, dynamic>.from(json['subtema'] as Map);
    final theme = Map<String, dynamic>.from(subtopic['tema'] as Map);
    final caseJson = json['caso'];
    return PracticeQuestion(
      id: json['id'] as String,
      statement: json['enunciado'] as String,
      difficulty: json['dificultad'] as String? ?? '',
      imageUrl: _optionalText(json['imagenUrl']),
      orderInCase: json['ordenEnCaso'] as int?,
      caseContent: caseJson is Map
          ? PracticeCase.fromJson(Map<String, dynamic>.from(caseJson))
          : null,
      options: (json['respuestas'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                PracticeOption.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      subtopicId: _optionalText(subtopic['id']),
      subtopicName: subtopic['nombre'] as String? ?? '',
      themeName: theme['nombre'] as String? ?? '',
      area: AcademicArea.fromBackend(theme['area'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'enunciado': statement,
    'dificultad': difficulty,
    'imagenUrl': imageUrl,
    'ordenEnCaso': orderInCase,
    'caso': caseContent?.toJson(),
    'respuestas': options.map((option) => option.toJson()).toList(),
    'subtema': {
      'id': subtopicId,
      'nombre': subtopicName,
      'tema': {'nombre': themeName, 'area': area.backendValue},
    },
  };
}

class PracticeCase {
  const PracticeCase({
    required this.id,
    required this.title,
    required this.context,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String context;
  final String? imageUrl;

  factory PracticeCase.fromJson(Map<String, dynamic> json) => PracticeCase(
    id: json['id'] as String,
    title: json['titulo'] as String? ?? '',
    context: json['contexto'] as String? ?? '',
    imageUrl: _optionalText(json['imagenUrl']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': title,
    'contexto': context,
    'imagenUrl': imageUrl,
  };
}

class PracticeOption {
  const PracticeOption({required this.id, required this.text});

  final String id;
  final String text;

  factory PracticeOption.fromJson(Map<String, dynamic> json) =>
      PracticeOption(id: json['id'] as String, text: json['texto'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'texto': text};
}

class PracticeAnswer {
  const PracticeAnswer({
    required this.questionId,
    required this.answerId,
    required this.responseTimeSeconds,
  });

  final String questionId;
  final String answerId;
  final int responseTimeSeconds;

  Map<String, dynamic> toJson() => {
    'preguntaId': questionId,
    'respuestaId': answerId,
    'tiempoRespuestaSegundos': responseTimeSeconds.clamp(0, 7200),
  };
}

class PracticeResult {
  const PracticeResult({required this.summary, required this.review});

  final PracticeResultSummary summary;
  final List<PracticeReviewQuestion> review;

  factory PracticeResult.fromJson(Map<String, dynamic> json) => PracticeResult(
    summary: PracticeResultSummary.fromJson(
      Map<String, dynamic>.from(json['resumen'] as Map),
    ),
    review: (json['detalle'] as List<dynamic>? ?? const [])
        .map(
          (item) => PracticeReviewQuestion.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false),
  );
}

class PracticeResultSummary {
  const PracticeResultSummary({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.percentage,
    required this.earnedXp,
  });

  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final double percentage;
  final int earnedXp;

  factory PracticeResultSummary.fromJson(Map<String, dynamic> json) =>
      PracticeResultSummary(
        totalQuestions: json['totalPreguntas'] as int? ?? 0,
        correctAnswers: json['respuestasCorrectas'] as int? ?? 0,
        incorrectAnswers: json['respuestasIncorrectas'] as int? ?? 0,
        percentage: _percentage(json['puntaje']),
        earnedXp: json['xpGanado'] as int? ?? 0,
      );
}

class PracticeReviewQuestion {
  const PracticeReviewQuestion({
    required this.id,
    required this.statement,
    required this.isCorrect,
    required this.selectedAnswerId,
    required this.correctAnswerId,
    required this.options,
    this.imageUrl,
    this.explanation,
    this.orderInCase,
    this.caseContent,
  });

  final String id;
  final String statement;
  final String? imageUrl;
  final bool isCorrect;
  final String selectedAnswerId;
  final String correctAnswerId;
  final String? explanation;
  final int? orderInCase;
  final PracticeCase? caseContent;
  final List<PracticeReviewOption> options;

  factory PracticeReviewQuestion.fromJson(Map<String, dynamic> json) {
    final caseJson = json['caso'];
    return PracticeReviewQuestion(
      id: json['preguntaId'] as String,
      statement: json['enunciado'] as String,
      imageUrl: _optionalText(json['imagenUrl']),
      isCorrect: json['esCorrecto'] as bool? ?? false,
      selectedAnswerId: json['respuestaSeleccionadaId'] as String,
      correctAnswerId: json['respuestaCorrectaId'] as String,
      explanation: _optionalText(json['explicacion']),
      orderInCase: json['ordenEnCaso'] as int?,
      caseContent: caseJson is Map
          ? PracticeCase.fromJson(Map<String, dynamic>.from(caseJson))
          : null,
      options: (json['respuestas'] as List<dynamic>? ?? const [])
          .map(
            (item) => PracticeReviewOption.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class PracticeReviewOption {
  const PracticeReviewOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.explanation,
  });

  final String id;
  final String text;
  final bool isCorrect;
  final String? explanation;

  factory PracticeReviewOption.fromJson(Map<String, dynamic> json) =>
      PracticeReviewOption(
        id: json['id'] as String,
        text: json['texto'] as String,
        isCorrect: json['esCorrecta'] as bool? ?? false,
        explanation: _optionalText(json['explicacion']),
      );
}

double _percentage(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll('%', '').trim()) ?? 0;
  }
  return 0;
}

String? _optionalText(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}
