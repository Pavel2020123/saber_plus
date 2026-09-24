import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';

/// Provisional demo rules v1. No clock, XP, ranking or academic completion.
class KnowledgeShieldProgress {
  const KnowledgeShieldProgress._(
    this.answered,
    this.correct,
    this.shield,
    this.pages,
  );
  const KnowledgeShieldProgress.initial() : this._(0, 0, maximumShield, 0);

  static const maximumShield = 3;
  static const rounds = 3;
  static const questionsPerRound = 4;
  static const questionLimit = rounds * questionsPerRound;
  final int answered;
  final int correct;
  final int shield;
  final int pages;
  factory KnowledgeShieldProgress.fromServer(Map<String, dynamic> json) {
    final answered = json['respondidas'];
    final correct = json['aciertos'];
    final shield = json['escudo'];
    final pages = json['paginas'];
    if (answered is! int ||
        correct is! int ||
        shield is! int ||
        pages is! int ||
        !_reachable.contains('$answered/$correct/$shield/$pages') ||
        json['errores'] != answered - correct) {
      throw const FormatException('Progreso de la defensa inválido.');
    }
    return KnowledgeShieldProgress._(answered, correct, shield, pages);
  }

  // Validate summaries without grading a real question or exposing its solution.
  static final Set<String> _reachable = _reachableStates();
  static Set<String> _reachableStates() {
    String key(KnowledgeShieldProgress p) =>
        '${p.answered}/${p.correct}/${p.shield}/${p.pages}';
    const initial = KnowledgeShieldProgress.initial();
    final states = <String, KnowledgeShieldProgress>{key(initial): initial};
    var frontier = [initial];
    while (frontier.isNotEmpty) {
      final next = <KnowledgeShieldProgress>[];
      for (final p in frontier) {
        if (p.finished) continue;
        for (final correct in [true, false]) {
          final candidate = p.answer(correct);
          if (!states.containsKey(key(candidate))) {
            states[key(candidate)] = candidate;
            next.add(candidate);
          }
        }
      }
      frontier = next;
    }
    return states.keys.toSet();
  }

  int get mistakes => answered - correct;
  bool get finished => shield == 0 || answered == questionLimit;
  bool get won => answered == questionLimit && shield > 0;
  int get round => (answered ~/ questionsPerRound + 1).clamp(1, rounds);
  bool get roundEnded => answered > 0 && answered % questionsPerRound == 0;

  KnowledgeShieldProgress answer(bool isCorrect) {
    if (finished) throw StateError('La defensa ya terminó.');
    final nextAnswered = answered + 1;
    var nextShield = (shield + (isCorrect ? 1 : -1)).clamp(0, maximumShield);
    var nextPages = pages;
    // An end-of-round attack follows grading. A depleted shield cannot recover.
    if (nextAnswered % questionsPerRound == 0 && nextShield > 0) {
      nextShield--;
      if (nextShield > 0) nextPages++;
    }
    return KnowledgeShieldProgress._(
      nextAnswered,
      correct + (isCorrect ? 1 : 0),
      nextShield,
      nextPages,
    );
  }
}

class KnowledgeShieldAttempt {
  const KnowledgeShieldAttempt({
    required this.id,
    required this.area,
    required this.progress,
    required this.question,
    this.lastCorrect,
    this.abandoned = false,
    this.status,
    this.expiresAt,
  });
  final String id;
  final AcademicArea area;
  final KnowledgeShieldProgress progress;
  final PracticeQuestion? question;
  final bool? lastCorrect;
  final bool abandoned;
  final String? status;
  final DateTime? expiresAt;
  bool get finished =>
      status == null ? abandoned || progress.finished : status != 'ACTIVO';

  factory KnowledgeShieldAttempt.fromJson(Map<String, dynamic> json) {
    final rules = json['reglas'];
    if (rules is! Map ||
        rules['version'] != 1 ||
        rules['maximumShield'] != KnowledgeShieldProgress.maximumShield ||
        rules['rounds'] != KnowledgeShieldProgress.rounds ||
        rules['questionsPerRound'] !=
            KnowledgeShieldProgress.questionsPerRound ||
        rules['questions'] != KnowledgeShieldProgress.questionLimit) {
      throw const FormatException('Actualiza la app para estas reglas.');
    }
    final status = json['estado'];
    if (status is! String ||
        !const {
          'ACTIVO',
          'VICTORIA',
          'DERROTA',
          'ABANDONADO',
          'EXPIRADO',
        }.contains(status)) {
      throw const FormatException('Estado de la defensa desconocido.');
    }
    final progress = KnowledgeShieldProgress.fromServer(json);
    final areaValue = json['area'];
    if (!AcademicArea.values.any((area) => area.backendValue == areaValue)) {
      throw const FormatException('Área de la defensa desconocida.');
    }
    final area = AcademicArea.fromBackend(areaValue as String);
    final question = json['pregunta'] == null
        ? null
        : PracticeQuestion.fromJson(
            Map<String, dynamic>.from(json['pregunta'] as Map),
          );
    if ((status == 'ACTIVO') != (question != null) ||
        (status == 'ACTIVO' && progress.finished) ||
        (status == 'VICTORIA' && !progress.won) ||
        (status == 'DERROTA' && progress.shield != 0) ||
        ((status == 'ABANDONADO' || status == 'EXPIRADO') &&
            progress.finished) ||
        (question != null &&
            (question.area != area ||
                question.id.isEmpty ||
                question.statement.trim().isEmpty ||
                question.options.length < 2 ||
                question.options.length > 6 ||
                question.options.map((o) => o.id).toSet().length !=
                    question.options.length ||
                question.options.any(
                  (o) => o.id.isEmpty || o.text.trim().isEmpty,
                )))) {
      throw const FormatException('Defensa incompleta o inconsistente.');
    }
    final last = json['ultimaRespuesta'];
    if ((progress.answered > 0) != (last != null) ||
        json['id'] is! String ||
        (json['id'] as String).isEmpty ||
        json['venceEn'] is! String ||
        DateTime.tryParse(json['venceEn'] as String) == null) {
      throw const FormatException('Respuesta de la defensa inconsistente.');
    }
    if (last != null) {
      if (last is! Map ||
          last['esCorrecta'] is! bool ||
          last['escudoAntes'] is! int ||
          last['paginasRecuperadas'] is! int ||
          last['preguntaId'] is! String ||
          (last['preguntaId'] as String).isEmpty ||
          last['respuestaId'] is! String ||
          (last['respuestaId'] as String).isEmpty ||
          last['rondaFinalizada'] != progress.roundEnded ||
          last['escudoDespues'] != progress.shield) {
        throw const FormatException('Última respuesta inválida.');
      }
      final before = KnowledgeShieldProgress.fromServer({
        'respondidas': progress.answered - 1,
        'aciertos': progress.correct - (last['esCorrecta'] == true ? 1 : 0),
        'errores': progress.mistakes - (last['esCorrecta'] == false ? 1 : 0),
        'escudo': last['escudoAntes'],
        'paginas': progress.pages - (last['paginasRecuperadas'] as int),
      });
      if (before.finished) {
        throw const FormatException('Respuesta tras el final.');
      }
      final after = before.answer(last['esCorrecta'] as bool);
      if (after.shield != progress.shield || after.pages != progress.pages) {
        throw const FormatException('Transición de defensa inválida.');
      }
    }
    return KnowledgeShieldAttempt(
      id: json['id'] as String,
      area: area,
      progress: progress,
      question: question,
      lastCorrect: last == null ? null : (last as Map)['esCorrecta'] as bool,
      abandoned: status == 'ABANDONADO',
      status: status,
      expiresAt: DateTime.parse(json['venceEn'] as String),
    );
  }
}

class KnowledgeShieldPendingAnswer {
  const KnowledgeShieldPendingAnswer({
    required this.attemptId,
    required this.questionId,
    required this.answerId,
    required this.requestKey,
  });
  final String attemptId;
  final String questionId;
  final String answerId;
  final String requestKey;
  Map<String, dynamic> toJson() => {
    'attemptId': attemptId,
    'questionId': questionId,
    'answerId': answerId,
    'requestKey': requestKey,
  };
  factory KnowledgeShieldPendingAnswer.fromJson(Map<String, dynamic> json) {
    for (final field in ['attemptId', 'questionId', 'answerId', 'requestKey']) {
      if (json[field] is! String || (json[field] as String).trim().isEmpty) {
        throw const FormatException('Envío pendiente inválido.');
      }
    }
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    ).hasMatch(json['requestKey'] as String)) {
      throw const FormatException('Clave pendiente inválida.');
    }
    return KnowledgeShieldPendingAnswer(
      attemptId: json['attemptId'] as String,
      questionId: json['questionId'] as String,
      answerId: json['answerId'] as String,
      requestKey: json['requestKey'] as String,
    );
  }
}

abstract interface class KnowledgeShieldRepository {
  bool get isDemo;
  KnowledgeShieldPendingAnswer? get pending;
  KnowledgeShieldAttempt? get current;
  Future<KnowledgeShieldAttempt?> restore();
  Future<KnowledgeShieldAttempt> start(
    AcademicArea area, {
    String? themeId,
    String? subtopicId,
    PracticeDifficulty? difficulty,
  });
  Future<KnowledgeShieldAttempt> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required String requestKey,
  });
  Future<KnowledgeShieldAttempt> abandon(String attemptId);
}
