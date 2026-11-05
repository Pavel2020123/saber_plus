/// Contract of OV-1B. Parsing failures are surfaced instead of substituting data.
const vocationalFamilyNames = <String, String>{
  'TECNOLOGIA_INGENIERIA': 'Tecnología e ingeniería',
  'SALUD_CIENCIAS_VIDA': 'Salud y ciencias de la vida',
  'SOCIEDAD_DERECHO_COMUNICACION': 'Sociedad, derecho y comunicación',
  'NEGOCIOS_ORGANIZACION_EMPRENDIMIENTO':
      'Negocios, organización y emprendimiento',
  'EDUCACION_HUMANIDADES_IDIOMAS': 'Educación, humanidades e idiomas',
  'CREATIVIDAD_DISENO_ENTORNO': 'Creatividad, diseño y entorno',
};

enum VocationalAnswer {
  none(0, 'Nada me interesa'),
  little(1, 'Me interesa poco'),
  some(2, 'Me interesa algo'),
  quite(3, 'Me interesa bastante'),
  much(4, 'Me interesa mucho'),
  unsure('NO_SE', 'No sé');

  const VocationalAnswer(this.wireValue, this.label);
  final Object wireValue;
  final String label;

  static VocationalAnswer parse(Object? value) {
    for (final answer in values) {
      if (value.runtimeType == answer.wireValue.runtimeType &&
          value == answer.wireValue) {
        return answer;
      }
    }
    throw const FormatException('Respuesta vocacional incompatible.');
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map) {
    throw const FormatException('Respuesta OV-1 incompatible.');
  }
  final converted = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('Clave OV-1 incompatible.');
    }
    converted[entry.key as String] = entry.value;
  }
  return converted;
}

List<dynamic> _array(Object? value) {
  if (value is! List) throw const FormatException('Lista OV-1 incompatible.');
  return value;
}

String _string(Object? value) {
  if (value is! String || value.isEmpty) {
    throw const FormatException('Texto OV-1 incompatible.');
  }
  return value;
}

int _integer(Object? value) {
  if (value is! int) throw const FormatException('Número OV-1 incompatible.');
  return value;
}

DateTime _date(Object? value) {
  try {
    return DateTime.parse(_string(value)).toLocal();
  } on FormatException {
    throw const FormatException('Fecha OV-1 incompatible.');
  }
}

String _family(Object? value) {
  final id = _string(value);
  if (!vocationalFamilyNames.containsKey(id)) {
    throw const FormatException('Familia OV-1 incompatible.');
  }
  return id;
}

class VocationalQuestion {
  const VocationalQuestion({
    required this.id,
    required this.text,
    required this.family,
  });

  final String id;
  final String text;
  final String family;

  factory VocationalQuestion.parse(Object? value) {
    final json = _object(value);
    final id = _string(json['id']);
    final family = _family(json['familia']);
    const prefixes = ['T', 'S', 'C', 'N', 'H', 'D'];
    final prefix =
        prefixes[vocationalFamilyNames.keys.toList().indexOf(family)];
    if (!RegExp('^$prefix[1-5]\$').hasMatch(id)) {
      throw const FormatException('Pregunta OV-1 incompatible.');
    }
    return VocationalQuestion(
      id: id,
      text: _string(json['texto']),
      family: family,
    );
  }
}

class VocationalQuestionnaire {
  const VocationalQuestionnaire({
    required this.version,
    required this.questions,
  });

  final int version;
  final List<VocationalQuestion> questions;

  factory VocationalQuestionnaire.parse(Object? value) {
    final json = _object(value);
    final version = _integer(json['rulesVersion']);
    if (version != 1 || json['naturaleza'] != 'INTERESES_DECLARADOS') {
      throw const FormatException('Versión OV-1 no compatible.');
    }
    final scale = _array(json['escala']);
    if (scale.length != VocationalAnswer.values.length) {
      throw const FormatException('Escala OV-1 incompatible.');
    }
    for (var i = 0; i < scale.length; i++) {
      VocationalAnswer.parse(scale[i]);
      if (scale[i] != VocationalAnswer.values[i].wireValue) {
        throw const FormatException('Escala OV-1 incompatible.');
      }
    }
    final questions = _array(
      json['preguntas'],
    ).map(VocationalQuestion.parse).toList(growable: false);
    final ids = questions.map((q) => q.id).toSet();
    if (questions.length != 30 ||
        ids.length != 30 ||
        vocationalFamilyNames.keys.any(
          (family) => questions.where((q) => q.family == family).length != 5,
        )) {
      throw const FormatException('Cuestionario OV-1 incompatible.');
    }
    return VocationalQuestionnaire(version: version, questions: questions);
  }
}

class VocationalFamilyResult {
  const VocationalFamilyResult({
    required this.id,
    required this.validCount,
    required this.totalQuestions,
    required this.score,
  });

  final String id;
  final int validCount;
  final int totalQuestions;

  /// Server's declared-interest index, never an aptitude or probability.
  final double score;

  factory VocationalFamilyResult.parse(Object? value) {
    final json = _object(value);
    final valid = _integer(json['cantidadValidas']);
    final total = _integer(json['totalPreguntas']);
    final rawScore = json['puntaje'];
    if (valid < 0 ||
        valid > 5 ||
        total != 5 ||
        rawScore is! num ||
        !rawScore.isFinite ||
        rawScore < 0 ||
        rawScore > 100) {
      throw const FormatException('Resultado familiar OV-1 incompatible.');
    }
    return VocationalFamilyResult(
      id: _family(json['familia']),
      validCount: valid,
      totalQuestions: total,
      score: rawScore.toDouble(),
    );
  }
}

class VocationalResult {
  const VocationalResult({
    required this.version,
    required this.validCount,
    required this.totalQuestions,
    required this.families,
    required this.mainFamilies,
    required this.completedAt,
    required this.questions,
    required this.answers,
  });

  final int version;
  final int validCount;
  final int totalQuestions;
  final List<VocationalFamilyResult> families;

  /// Preserve the server's complete list, including any tie at third place.
  final List<String> mainFamilies;
  final DateTime completedAt;
  final List<VocationalQuestion> questions;
  final Map<String, VocationalAnswer> answers;

  factory VocationalResult.parse(Object? value) {
    final json = _object(value);
    if (_integer(json['ov1RulesVersion']) != 1 ||
        json['finalizable'] != true ||
        json['naturaleza'] != 'INTERESES_DECLARADOS') {
      throw const FormatException('Resultado OV-1 incompatible.');
    }
    final valid = _integer(json['cantidadValidas']);
    final total = _integer(json['totalPreguntas']);
    final families = _array(
      json['familias'],
    ).map(VocationalFamilyResult.parse).toList(growable: false);
    final main = _array(
      json['principales'],
    ).map(_family).toList(growable: false);
    final questions = _array(
      json['preguntas'],
    ).map(VocationalQuestion.parse).toList(growable: false);
    final answers = parseVocationalAnswers(json['respuestas']);
    if (valid < 0 ||
        valid > 30 ||
        total != 30 ||
        families.length != 6 ||
        families.map((f) => f.id).toSet().length != 6 ||
        main.isEmpty ||
        main.length > 6 ||
        main.toSet().length != main.length ||
        main.any((f) => !families.any((entry) => entry.id == f)) ||
        questions.length != 30 ||
        questions.map((q) => q.id).toSet().length != 30 ||
        answers.keys.any((id) => !questions.any((q) => q.id == id))) {
      throw const FormatException('Resultado OV-1 incompatible.');
    }
    return VocationalResult(
      version: 1,
      validCount: valid,
      totalQuestions: total,
      families: families,
      mainFamilies: main,
      completedAt: _date(json['completadoEn']),
      questions: questions,
      answers: answers,
    );
  }
}

Map<String, VocationalAnswer> parseVocationalAnswers(Object? value) {
  final result = <String, VocationalAnswer>{};
  for (final item in _array(value)) {
    final json = _object(item);
    final id = _string(json['preguntaId']);
    if (!RegExp(r'^[TSCNHD][1-5]$').hasMatch(id) || result.containsKey(id)) {
      throw const FormatException('Respuesta OV-1 incompatible.');
    }
    result[id] = VocationalAnswer.parse(json['valor']);
  }
  return Map.unmodifiable(result);
}

class VocationalAttempt {
  const VocationalAttempt({
    required this.id,
    required this.version,
    required this.completed,
    required this.startedAt,
    required this.updatedAt,
    required this.completedAt,
    required this.answers,
    required this.result,
  });

  final String id;
  final int version;
  final bool completed;
  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final Map<String, VocationalAnswer> answers;
  final VocationalResult? result;

  factory VocationalAttempt.parse(Object? value) {
    final json = _object(value);
    final id = _string(json['id']);
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(id)) {
      throw const FormatException('Identificador OV-1 incompatible.');
    }
    if (!json.containsKey('completadoEn') || !json.containsKey('resultado')) {
      throw const FormatException('Campos de intento OV-1 incompletos.');
    }
    final version = _integer(json['rulesVersion']);
    final state = _string(json['estado']);
    if (version != 1 || !{'EN_PROGRESO', 'COMPLETADO'}.contains(state)) {
      throw const FormatException('Estado OV-1 incompatible.');
    }
    final completed = state == 'COMPLETADO';
    final completedAt = json['completadoEn'] == null
        ? null
        : _date(json['completadoEn']);
    final result = json['resultado'] == null
        ? null
        : VocationalResult.parse(json['resultado']);
    final answers = parseVocationalAnswers(json['respuestas']);
    if (completed != (completedAt != null && result != null) ||
        (result != null &&
            (result.version != version ||
                result.completedAt != completedAt ||
                result.answers.length != answers.length ||
                result.answers.entries.any(
                  (entry) => answers[entry.key] != entry.value,
                )))) {
      throw const FormatException('Terminal OV-1 incompatible.');
    }
    return VocationalAttempt(
      id: id,
      version: version,
      completed: completed,
      startedAt: _date(json['iniciadoEn']),
      updatedAt: _date(json['actualizadoEn']),
      completedAt: completedAt,
      answers: answers,
      result: result,
    );
  }
}

class VocationalHistory {
  const VocationalHistory({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.attempts,
  });
  final int page;
  final int pageSize;
  final int total;
  final List<VocationalAttempt> attempts;

  factory VocationalHistory.parse(Object? value) {
    final json = _object(value);
    final page = _integer(json['pagina']);
    final pageSize = _integer(json['porPagina']);
    final total = _integer(json['total']);
    final attempts = _array(
      json['intentos'],
    ).map(VocationalAttempt.parse).toList(growable: false);
    if (page < 1 || pageSize != 20 || total < 0 || attempts.length > pageSize) {
      throw const FormatException('Historial OV-1 incompatible.');
    }
    return VocationalHistory(
      page: page,
      pageSize: pageSize,
      total: total,
      attempts: attempts,
    );
  }
}

VocationalAttempt? parseCurrentVocationalAttempt(Object? value) {
  final json = _object(value);
  if (!json.containsKey('intento')) {
    throw const FormatException('Estado actual OV-1 incompatible.');
  }
  final raw = json['intento'];
  if (raw == null) return null;
  final attempt = VocationalAttempt.parse(raw);
  if (attempt.completed) {
    throw const FormatException('Intento activo incompatible.');
  }
  return attempt;
}
