import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';

/// Version 1 rules. Real progress is confirmed by the server, not graded here.
class StarRescueProgress {
  const StarRescueProgress._(this.answered, this.stars);
  const StarRescueProgress.initial() : this._(0, 0);
  static const target = 6;
  static const groupSize = 3;
  static const questionLimit = 10;
  final int answered;
  final int stars;
  factory StarRescueProgress.fromServer(Map<String, dynamic> json) {
    final answered = json['respondidas'];
    final stars = json['estrellas'];
    if (answered is! int ||
        stars is! int ||
        answered < 0 ||
        answered > questionLimit ||
        stars < 0 ||
        stars > target ||
        stars > answered ||
        json['aciertos'] != stars ||
        json['errores'] != answered - stars ||
        json['constelaciones'] != stars ~/ groupSize) {
      throw const FormatException('Progreso del rescate inválido.');
    }
    return StarRescueProgress._(answered, stars);
  }
  int get mistakes => answered - stars;
  int get constellations => stars ~/ groupSize;
  bool get won => stars == target;
  bool get finished => won || answered == questionLimit;

  StarRescueProgress answer(bool correct) {
    if (finished) throw StateError('El rescate ya terminó.');
    return StarRescueProgress._(answered + 1, stars + (correct ? 1 : 0));
  }
}

class StarRescueAttempt {
  const StarRescueAttempt({
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
  final StarRescueProgress progress;
  final PracticeQuestion? question;
  final bool? lastCorrect;
  final bool abandoned;
  final String? status;
  final DateTime? expiresAt;
  bool get finished =>
      status == null ? abandoned || progress.finished : status != 'ACTIVO';

  factory StarRescueAttempt.fromJson(Map<String, dynamic> json) {
    final rules = json['reglas'];
    if (rules is! Map ||
        rules['version'] != 1 ||
        rules['target'] != StarRescueProgress.target ||
        rules['questions'] != StarRescueProgress.questionLimit ||
        rules['starsPerConstellation'] != StarRescueProgress.groupSize) {
      throw const FormatException('Actualiza la app para estas reglas.');
    }
    final status = json['estado'];
    if (status is! String ||
        !const {
          'ACTIVO',
          'VICTORIA',
          'AGOTADO',
          'ABANDONADO',
          'EXPIRADO',
        }.contains(status)) {
      throw const FormatException('Estado del rescate desconocido.');
    }
    final progress = StarRescueProgress.fromServer(json);
    final areaValue = json['area'];
    if (!AcademicArea.values.any((area) => area.backendValue == areaValue)) {
      throw const FormatException('Área del rescate desconocida.');
    }
    final area = AcademicArea.fromBackend(areaValue as String);
    final question = json['pregunta'] == null
        ? null
        : PracticeQuestion.fromJson(
            Map<String, dynamic>.from(json['pregunta'] as Map),
          );
    final active = status == 'ACTIVO';
    if (active != (question != null) ||
        (active && progress.finished) ||
        (status == 'VICTORIA' && !progress.won) ||
        (status == 'AGOTADO' &&
            (progress.answered != StarRescueProgress.questionLimit ||
                progress.won)) ||
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
      throw const FormatException('Rescate incompleto o inconsistente.');
    }
    final last = json['ultimaRespuesta'];
    if ((progress.answered > 0) != (last != null) ||
        (last != null &&
            (last is! Map ||
                last['esCorrecta'] is! bool ||
                last['estrellasGanadas'] !=
                    (last['esCorrecta'] == true ? 1 : 0) ||
                last['preguntaId'] is! String ||
                (last['preguntaId'] as String).isEmpty ||
                last['respuestaId'] is! String ||
                (last['respuestaId'] as String).isEmpty)) ||
        json['id'] is! String ||
        (json['id'] as String).isEmpty ||
        json['venceEn'] is! String ||
        DateTime.tryParse(json['venceEn'] as String) == null) {
      throw const FormatException('Respuesta del rescate inconsistente.');
    }
    return StarRescueAttempt(
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

class StarRescuePendingAnswer {
  const StarRescuePendingAnswer({
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
  factory StarRescuePendingAnswer.fromJson(Map<String, dynamic> json) {
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
    return StarRescuePendingAnswer(
      attemptId: json['attemptId'] as String,
      questionId: json['questionId'] as String,
      answerId: json['answerId'] as String,
      requestKey: json['requestKey'] as String,
    );
  }
}

abstract interface class StarRescueRepository {
  bool get isDemo;
  StarRescuePendingAnswer? get pending;
  StarRescueAttempt? get current;
  Future<StarRescueAttempt?> restore();
  Future<StarRescueAttempt> start(
    AcademicArea area, {
    String? themeId,
    String? subtopicId,
    PracticeDifficulty? difficulty,
  });
  Future<StarRescueAttempt> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required String requestKey,
  });
  Future<StarRescueAttempt> abandon(String attemptId);
}
