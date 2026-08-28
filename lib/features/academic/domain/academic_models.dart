enum AcademicArea {
  criticalReading,
  mathematics,
  naturalSciences,
  socialSciences,
  english;

  factory AcademicArea.fromBackend(String value) => switch (value) {
    'LECTURA_CRITICA' => AcademicArea.criticalReading,
    'MATEMATICAS' => AcademicArea.mathematics,
    'CIENCIAS_NATURALES' => AcademicArea.naturalSciences,
    'SOCIALES_CIUDADANAS' => AcademicArea.socialSciences,
    'INGLES' => AcademicArea.english,
    _ => throw FormatException('Área ICFES no reconocida: $value'),
  };

  String get label => switch (this) {
    AcademicArea.criticalReading => 'Lectura crítica',
    AcademicArea.mathematics => 'Matemáticas',
    AcademicArea.naturalSciences => 'Ciencias naturales',
    AcademicArea.socialSciences => 'Sociales y ciudadanas',
    AcademicArea.english => 'Inglés',
  };

  String get backendValue => switch (this) {
    AcademicArea.criticalReading => 'LECTURA_CRITICA',
    AcademicArea.mathematics => 'MATEMATICAS',
    AcademicArea.naturalSciences => 'CIENCIAS_NATURALES',
    AcademicArea.socialSciences => 'SOCIALES_CIUDADANAS',
    AcademicArea.english => 'INGLES',
  };

  String get slug => switch (this) {
    AcademicArea.criticalReading => 'lectura-critica',
    AcademicArea.mathematics => 'matematicas',
    AcademicArea.naturalSciences => 'ciencias-naturales',
    AcademicArea.socialSciences => 'sociales-ciudadanas',
    AcademicArea.english => 'ingles',
  };

  factory AcademicArea.fromSlug(String value) => AcademicArea.values.firstWhere(
    (area) => area.slug == value,
    orElse: () => throw FormatException('Área no reconocida: $value'),
  );
}

enum DiagnosticStatus { notStarted, inProgress, completed }

enum DiagnosticLevel {
  needsReinforcement,
  inProgress,
  strength;

  factory DiagnosticLevel.fromBackend(String value) => switch (value) {
    'POR_REFORZAR' => DiagnosticLevel.needsReinforcement,
    'EN_PROCESO' => DiagnosticLevel.inProgress,
    'FORTALEZA' => DiagnosticLevel.strength,
    _ => throw FormatException('Nivel diagnóstico no reconocido: $value'),
  };

  String get label => switch (this) {
    DiagnosticLevel.needsReinforcement => 'Por reforzar',
    DiagnosticLevel.inProgress => 'En proceso',
    DiagnosticLevel.strength => 'Fortaleza',
  };
}

class ActiveExam {
  const ActiveExam({
    required this.id,
    required this.year,
    required this.calendar,
    required this.examDate,
  });

  final String id;
  final int year;
  final String calendar;
  final DateTime examDate;

  factory ActiveExam.fromJson(Map<String, dynamic> json) => ActiveExam(
    id: json['id'] as String,
    year: json['anio'] as int,
    calendar: json['calendario'] as String,
    examDate: DateTime.parse(json['fechaExamen'] as String),
  );

  int daysRemaining(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(examDate.year, examDate.month, examDate.day);
    return date.difference(today).inDays;
  }
}

class AreaDiagnosticResult {
  const AreaDiagnosticResult({
    required this.area,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentage,
    required this.level,
  });

  final AcademicArea area;
  final int totalQuestions;
  final int correctAnswers;
  final double percentage;
  final DiagnosticLevel level;

  factory AreaDiagnosticResult.fromJson(Map<String, dynamic> json) =>
      AreaDiagnosticResult(
        area: AcademicArea.fromBackend(json['area'] as String),
        totalQuestions: json['totalPreguntas'] as int,
        correctAnswers: json['respuestasCorrectas'] as int,
        percentage: (json['porcentaje'] as num).toDouble(),
        level: DiagnosticLevel.fromBackend(json['nivel'] as String),
      );
}

class DiagnosticCaseContent {
  const DiagnosticCaseContent({
    required this.id,
    required this.title,
    required this.context,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String context;
  final String? imageUrl;

  factory DiagnosticCaseContent.fromJson(Map<String, dynamic> json) =>
      DiagnosticCaseContent(
        id: json['id'] as String,
        title: json['titulo'] as String? ?? '',
        context: json['contexto'] as String? ?? '',
        imageUrl: json['imagenUrl'] as String?,
      );
}

class DiagnosticOption {
  const DiagnosticOption({required this.id, required this.text});

  final String id;
  final String text;

  factory DiagnosticOption.fromJson(Map<String, dynamic> json) =>
      DiagnosticOption(id: json['id'] as String, text: json['texto'] as String);
}

class DiagnosticQuestion {
  const DiagnosticQuestion({
    required this.id,
    required this.statement,
    required this.difficulty,
    required this.options,
    required this.subtopicName,
    required this.themeName,
    required this.area,
    this.imageUrl,
    this.caseContent,
  });

  final String id;
  final String statement;
  final String difficulty;
  final String? imageUrl;
  final DiagnosticCaseContent? caseContent;
  final List<DiagnosticOption> options;
  final String subtopicName;
  final String themeName;
  final AcademicArea area;

  factory DiagnosticQuestion.fromJson(Map<String, dynamic> json) {
    final subtopic = Map<String, dynamic>.from(json['subtema'] as Map);
    final theme = Map<String, dynamic>.from(subtopic['tema'] as Map);
    final caseJson = json['caso'];
    return DiagnosticQuestion(
      id: json['id'] as String,
      statement: json['enunciado'] as String,
      difficulty: json['dificultad'] as String? ?? '',
      imageUrl: json['imagenUrl'] as String?,
      caseContent: caseJson is Map
          ? DiagnosticCaseContent.fromJson(Map<String, dynamic>.from(caseJson))
          : null,
      options: (json['respuestas'] as List<dynamic>)
          .map(
            (item) => DiagnosticOption.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      subtopicName: subtopic['nombre'] as String,
      themeName: theme['nombre'] as String,
      area: AcademicArea.fromBackend(theme['area'] as String),
    );
  }
}

class DiagnosticAnswer {
  const DiagnosticAnswer({
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

class WeakTopic {
  const WeakTopic({
    required this.area,
    required this.theme,
    required this.subtopic,
    required this.failedQuestions,
  });

  final AcademicArea area;
  final String theme;
  final String subtopic;
  final int failedQuestions;
}

class DiagnosticSummary {
  const DiagnosticSummary({
    required this.status,
    this.id,
    this.startedAt,
    this.completedAt,
    this.totalQuestions = 15,
    this.correctAnswers = 0,
    this.percentage = 0,
    this.level,
    this.resultsByArea = const [],
    this.questions = const [],
    this.weakTopics = const [],
    this.priorityArea,
    this.strengthArea,
  });

  final DiagnosticStatus status;
  final String? id;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int totalQuestions;
  final int correctAnswers;
  final double percentage;
  final DiagnosticLevel? level;
  final List<AreaDiagnosticResult> resultsByArea;
  final List<DiagnosticQuestion> questions;
  final List<WeakTopic> weakTopics;
  final AcademicArea? priorityArea;
  final AcademicArea? strengthArea;

  factory DiagnosticSummary.fromJson(Map<String, dynamic> json) {
    final status = switch (json['estado']) {
      'NO_INICIADO' => DiagnosticStatus.notStarted,
      'EN_PROGRESO' => DiagnosticStatus.inProgress,
      'COMPLETADO' => DiagnosticStatus.completed,
      final value => throw FormatException(
        'Estado diagnóstico no reconocido: $value',
      ),
    };
    return DiagnosticSummary(
      status: status,
      id: json['diagnosticoId'] as String?,
      startedAt: _optionalDate(json['iniciadoEn']),
      completedAt: _optionalDate(json['completadoEn']),
      totalQuestions: json['totalPreguntas'] as int? ?? 15,
      correctAnswers: json['respuestasCorrectas'] as int? ?? 0,
      percentage: (json['porcentaje'] as num?)?.toDouble() ?? 0,
      level: _optionalDiagnosticLevel(json['nivel']),
      resultsByArea:
          (json['resultadosPorArea'] as List<dynamic>?)
              ?.map(
                (item) => AreaDiagnosticResult.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          const [],
      questions:
          (json['preguntas'] as List<dynamic>?)
              ?.map(
                (item) => DiagnosticQuestion.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false) ??
          const [],
      priorityArea: _optionalAcademicArea(json['areaPrioritaria']),
      strengthArea: _optionalAcademicArea(json['areaFortaleza']),
    );
  }

  DiagnosticSummary copyWith({
    DiagnosticStatus? status,
    String? id,
    DateTime? startedAt,
    DateTime? completedAt,
    int? totalQuestions,
    int? correctAnswers,
    double? percentage,
    DiagnosticLevel? level,
    List<AreaDiagnosticResult>? resultsByArea,
    List<DiagnosticQuestion>? questions,
    List<WeakTopic>? weakTopics,
    AcademicArea? priorityArea,
    AcademicArea? strengthArea,
  }) => DiagnosticSummary(
    status: status ?? this.status,
    id: id ?? this.id,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    totalQuestions: totalQuestions ?? this.totalQuestions,
    correctAnswers: correctAnswers ?? this.correctAnswers,
    percentage: percentage ?? this.percentage,
    level: level ?? this.level,
    resultsByArea: resultsByArea ?? this.resultsByArea,
    questions: questions ?? this.questions,
    weakTopics: weakTopics ?? this.weakTopics,
    priorityArea: priorityArea ?? this.priorityArea,
    strengthArea: strengthArea ?? this.strengthArea,
  );
}

enum StudyPlanStatus {
  diagnosticPending,
  datePending,
  examFinished,
  noContent,
  allCompleted,
  ready;

  factory StudyPlanStatus.fromBackend(String value) => switch (value) {
    'DIAGNOSTICO_PENDIENTE' => StudyPlanStatus.diagnosticPending,
    'FECHA_PENDIENTE' => StudyPlanStatus.datePending,
    'CONVOCATORIA_FINALIZADA' => StudyPlanStatus.examFinished,
    'SIN_CONTENIDO' => StudyPlanStatus.noContent,
    'TODO_COMPLETADO' => StudyPlanStatus.allCompleted,
    'LISTO' => StudyPlanStatus.ready,
    _ => throw FormatException('Estado de plan no reconocido: $value'),
  };
}

enum StudyActivityType { study, mockExam, rest, exam }

class StudyActivity {
  const StudyActivity({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.detail,
    required this.minutes,
    required this.completed,
    this.area,
  });

  final String id;
  final DateTime date;
  final StudyActivityType type;
  final String title;
  final String detail;
  final int minutes;
  final bool completed;
  final AcademicArea? area;

  factory StudyActivity.fromJson(Map<String, dynamic> json) => StudyActivity(
    id: json['id'] as String,
    date: DateTime.parse(json['fecha'] as String),
    type: switch (json['tipo']) {
      'ESTUDIO' => StudyActivityType.study,
      'SIMULACRO' => StudyActivityType.mockExam,
      'DESCANSO' => StudyActivityType.rest,
      'EXAMEN' => StudyActivityType.exam,
      final value => throw FormatException(
        'Tipo de actividad no reconocido: $value',
      ),
    },
    title: json['titulo'] as String,
    detail: json['detalle'] as String,
    minutes: json['minutos'] as int,
    completed: json['completada'] as bool? ?? false,
    area: _optionalAcademicArea(json['area']),
  );
}

class StudyPlanSummary {
  const StudyPlanSummary({
    required this.status,
    this.targetSessions = 0,
    this.completedSessions = 0,
    this.targetMinutes = 0,
    this.percentage = 0,
    this.activities = const [],
  });

  final StudyPlanStatus status;
  final int targetSessions;
  final int completedSessions;
  final int targetMinutes;
  final int percentage;
  final List<StudyActivity> activities;

  StudyActivity? get nextActivity {
    for (final activity in activities) {
      if (!activity.completed &&
          (activity.type == StudyActivityType.study ||
              activity.type == StudyActivityType.mockExam)) {
        return activity;
      }
    }
    return null;
  }

  factory StudyPlanSummary.fromJson(Map<String, dynamic> json) {
    final status = StudyPlanStatus.fromBackend(json['estado'] as String);
    final summary = json['resumen'] as Map?;
    return StudyPlanSummary(
      status: status,
      targetSessions: summary?['sesionesObjetivo'] as int? ?? 0,
      completedSessions: summary?['sesionesCompletadas'] as int? ?? 0,
      targetMinutes: summary?['minutosObjetivoSemanal'] as int? ?? 0,
      percentage: summary?['porcentaje'] as int? ?? 0,
      activities:
          (json['dias'] as List<dynamic>?)
              ?.map(
                (item) => StudyActivity.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          const [],
    );
  }
}

class AcademicHomeData {
  const AcademicHomeData({
    required this.diagnostic,
    required this.plan,
    this.activeExam,
  });

  final ActiveExam? activeExam;
  final DiagnosticSummary diagnostic;
  final StudyPlanSummary plan;

  AcademicHomeData copyWith({
    ActiveExam? activeExam,
    DiagnosticSummary? diagnostic,
    StudyPlanSummary? plan,
  }) => AcademicHomeData(
    activeExam: activeExam ?? this.activeExam,
    diagnostic: diagnostic ?? this.diagnostic,
    plan: plan ?? this.plan,
  );

  static AcademicHomeData get demo => AcademicHomeData(
    activeExam: ActiveExam(
      id: 'demo-calendar',
      year: 2026,
      calendar: 'A',
      examDate: DateTime.now().add(const Duration(days: 84)),
    ),
    diagnostic: const DiagnosticSummary(
      status: DiagnosticStatus.completed,
      id: 'demo-diagnostic',
      totalQuestions: 15,
      correctAnswers: 9,
      percentage: 60,
      level: DiagnosticLevel.inProgress,
      priorityArea: AcademicArea.mathematics,
    ),
    plan: StudyPlanSummary(
      status: StudyPlanStatus.ready,
      targetSessions: 5,
      completedSessions: 3,
      targetMinutes: 200,
      percentage: 60,
      activities: [
        StudyActivity(
          id: 'demo-activity',
          date: DateTime.now(),
          type: StudyActivityType.study,
          title: 'Refuerzo de matemáticas',
          detail: 'Funciones lineales · sesión recomendada',
          minutes: 40,
          completed: false,
          area: AcademicArea.mathematics,
        ),
      ],
    ),
  );
}

DateTime? _optionalDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

DiagnosticLevel? _optionalDiagnosticLevel(Object? value) =>
    value is String ? DiagnosticLevel.fromBackend(value) : null;

AcademicArea? _optionalAcademicArea(Object? value) =>
    value is String ? AcademicArea.fromBackend(value) : null;
