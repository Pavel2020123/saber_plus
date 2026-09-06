import '../../academic/domain/academic_models.dart';

enum EvidenceLevel {
  insufficient,
  needsReview,
  developing,
  strength;

  String get label => switch (this) {
    insufficient => 'Evidencia insuficiente',
    needsReview => 'Conviene reforzar',
    developing => 'En proceso',
    strength => 'Fortaleza en lo evaluado',
  };

  static EvidenceLevel parse(Object? value) => switch (value) {
    'EVIDENCIA_INSUFICIENTE' => insufficient,
    'POR_REFORZAR' => needsReview,
    'EN_PROCESO' => developing,
    'FORTALEZA' => strength,
    _ => throw const FormatException('Estado de evidencia no reconocido.'),
  };
}

class EvidenceItem {
  const EvidenceItem({
    required this.id,
    required this.name,
    required this.area,
    required this.questions,
    required this.correct,
    required this.sessions,
    required this.days,
    required this.percentage,
    required this.level,
    this.subtopics = const [],
  });

  final String id;
  final String name;
  final AcademicArea area;
  final int questions;
  final int correct;
  final int sessions;
  final int days;
  final double percentage;
  final EvidenceLevel level;
  final List<EvidenceItem> subtopics;

  static EvidenceItem parse(
    Map<String, dynamic> json,
    EvidencePolicy policy,
    bool partial, {
    AcademicArea? parentArea,
  }) {
    final area = parentArea ?? AcademicArea.fromBackend(_text(json['area']));
    final questions = _integer(json['preguntasUnicas'], minimum: 1);
    final correct = _integer(json['correctas']);
    final incorrect = _integer(json['incorrectas']);
    final sessions = _integer(json['sesiones'], minimum: 1);
    final days = _integer(json['dias'], minimum: 1);
    final percentage = json['porcentaje'];
    final level = EvidenceLevel.parse(json['estado']);
    if (correct + incorrect != questions ||
        sessions > questions ||
        days > questions ||
        percentage is! num ||
        !percentage.isFinite ||
        percentage < 0 ||
        percentage > 100 ||
        (percentage - correct * 100 / questions).abs() > 0.11) {
      throw const FormatException('Métricas de evidencia inconsistentes.');
    }
    if (level != EvidenceLevel.insufficient &&
        (partial ||
            questions <
                (parentArea == null
                    ? policy.themeMinimum
                    : policy.subtopicMinimum) ||
            sessions < policy.sessionsMinimum ||
            days < policy.daysMinimum)) {
      throw const FormatException('Conclusión sin evidencia suficiente.');
    }
    final rawPercentage = correct * 100 / questions;
    if ((level == EvidenceLevel.needsReview && rawPercentage >= 60) ||
        (level == EvidenceLevel.strength && rawPercentage < 80) ||
        (level == EvidenceLevel.developing &&
            (rawPercentage < 60 || rawPercentage >= 80))) {
      throw const FormatException('Conclusión incompatible con los aciertos.');
    }
    final children = parentArea == null
        ? _list(json['subtemas'])
              .map((row) => parse(_map(row), policy, partial, parentArea: area))
              .toList()
        : <EvidenceItem>[];
    if (parentArea == null &&
        (children.fold<int>(0, (sum, row) => sum + row.questions) !=
                questions ||
            children.fold<int>(0, (sum, row) => sum + row.correct) != correct ||
            children.map((row) => row.id).toSet().length != children.length)) {
      throw const FormatException('Subtemas de evidencia inconsistentes.');
    }
    return EvidenceItem(
      id: _text(json['id']),
      name: _text(json['nombre']),
      area: area,
      questions: questions,
      correct: correct,
      sessions: sessions,
      days: days,
      percentage: percentage.toDouble(),
      level: level,
      subtopics: List.unmodifiable(children),
    );
  }
}

class EvidencePolicy {
  const EvidencePolicy({
    required this.windowDays,
    required this.subtopicMinimum,
    required this.themeMinimum,
    required this.sessionsMinimum,
    required this.daysMinimum,
  });
  final int windowDays;
  final int subtopicMinimum;
  final int themeMinimum;
  final int sessionsMinimum;
  final int daysMinimum;

  factory EvidencePolicy.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 ||
        json['zonaHoraria'] != 'America/Bogota' ||
        json['criterioRepeticiones'] !=
            'PRIMERA_RESPUESTA_POR_PREGUNTA_EN_VENTANA' ||
        json['umbralRefuerzo'] != 60 ||
        json['umbralFortaleza'] != 80) {
      throw const FormatException('Política de evidencia no compatible.');
    }
    return EvidencePolicy(
      windowDays: _integer(json['ventanaDias'], minimum: 1),
      subtopicMinimum: _integer(json['minimoPreguntasSubtema'], minimum: 1),
      themeMinimum: _integer(json['minimoPreguntasTema'], minimum: 1),
      sessionsMinimum: _integer(json['minimoSesiones'], minimum: 1),
      daysMinimum: _integer(json['minimoDias'], minimum: 1),
    );
  }
}

class LearningEvidence {
  const LearningEvidence({
    required this.policy,
    required this.partial,
    required this.excluded,
    required this.repeated,
    required this.since,
    required this.until,
    required this.topics,
    this.isDemo = false,
  });
  final EvidencePolicy policy;
  final bool partial;
  final int excluded;
  final int repeated;
  final DateTime since;
  final DateTime until;
  final List<EvidenceItem> topics;
  final bool isDemo;

  factory LearningEvidence.fromJson(
    Map<String, dynamic> json, {
    bool isDemo = false,
  }) {
    if (json['version'] != 1 || json['parcial'] is! bool) {
      throw const FormatException('Informe de evidencia no compatible.');
    }
    final policy = EvidencePolicy.fromJson(_map(json['politica']));
    final partial = json['parcial'] as bool;
    final since = DateTime.parse(_text(json['desde']));
    final until = DateTime.parse(_text(json['hasta']));
    final topics = _list(
      json['temas'],
    ).map((row) => EvidenceItem.parse(_map(row), policy, partial)).toList();
    if (until.isBefore(since) ||
        topics.map((row) => row.id).toSet().length != topics.length) {
      throw const FormatException('Informe inconsistente.');
    }
    return LearningEvidence(
      policy: policy,
      partial: partial,
      excluded: _integer(json['registrosExcluidos']),
      repeated: _integer(json['repeticionesIgnoradas']),
      since: since,
      until: until,
      topics: List.unmodifiable(topics),
      isDemo: isDemo,
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Objeto esperado.');
  }
  return value;
}

List<dynamic> _list(Object? value) {
  if (value is! List) throw const FormatException('Lista esperada.');
  return value;
}

String _text(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Texto esperado.');
  }
  return value;
}

int _integer(Object? value, {int minimum = 0}) {
  if (value is! int || value < minimum || value > 10000) {
    throw const FormatException('Entero fuera de rango.');
  }
  return value;
}
