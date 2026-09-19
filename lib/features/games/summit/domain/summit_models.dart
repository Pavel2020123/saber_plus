import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';

/// Version 1 rules; remote progress is read from the server, never graded here.
class SummitProgress {
  const SummitProgress._(this.step, this.peak, this.answered, this.correct);
  const SummitProgress.initial() : this._(0, 0, 0, 0);

  static const target = 5;
  static const questionLimit = 12;
  final int step;
  final int peak;
  final int answered;
  final int correct;
  factory SummitProgress.fromServer(Map<String, dynamic> json) {
    final step = json['escalon'] as int;
    final peak = json['maximoEscalon'] as int;
    final answered = json['respondidas'] as int;
    final correct = json['aciertos'] as int;
    if (step < 0 ||
        step > target ||
        peak < step ||
        peak > target ||
        answered < 0 ||
        answered > questionLimit ||
        correct < 0 ||
        correct > answered ||
        peak > correct ||
        json['errores'] != answered - correct) {
      throw const FormatException('Progreso de partida inválido.');
    }
    return SummitProgress._(step, peak, answered, correct);
  }
  int get mistakes => answered - correct;
  bool get won => step == target;
  bool get finished => won || answered >= questionLimit;

  SummitProgress answer(bool isCorrect) {
    if (finished) throw StateError('Esta partida ya terminó.');
    final next = (step + (isCorrect ? 1 : -1)).clamp(0, target);
    return SummitProgress._(
      next,
      next > peak ? next : peak,
      answered + 1,
      correct + (isCorrect ? 1 : 0),
    );
  }
}

class SummitAttempt {
  const SummitAttempt({
    required this.id,
    required this.area,
    required this.progress,
    required this.question,
    this.lastCorrect,
    this.lastMovement = 0,
    this.status,
    this.expiresAt,
  });
  final String id;
  final AcademicArea area;
  final SummitProgress progress;
  final PracticeQuestion? question;
  final bool? lastCorrect;
  final int lastMovement;
  final String? status;
  final DateTime? expiresAt;
  bool get finished => status == null ? progress.finished : status != 'ACTIVO';

  factory SummitAttempt.fromJson(Map<String, dynamic> json) {
    final rules = json['reglas'] as Map;
    if (rules['version'] != 1 ||
        rules['target'] != SummitProgress.target ||
        rules['questions'] != SummitProgress.questionLimit) {
      throw const FormatException('Actualiza la app para estas reglas.');
    }
    final status = json['estado'] as String;
    if (!const {
      'ACTIVO',
      'VICTORIA',
      'AGOTADO',
      'ABANDONADO',
      'EXPIRADO',
    }.contains(status)) {
      throw const FormatException('Estado de partida desconocido.');
    }
    final progress = SummitProgress.fromServer(json);
    final area = AcademicArea.fromBackend(json['area'] as String);
    final question = json['pregunta'] == null
        ? null
        : PracticeQuestion.fromJson(
            Map<String, dynamic>.from(json['pregunta'] as Map),
          );
    final active = status == 'ACTIVO';
    if (active != (question != null) ||
        (active && progress.finished) ||
        (status == 'VICTORIA' && !progress.won) ||
        (status == 'AGOTADO' && (progress.answered != 12 || progress.won)) ||
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
      throw const FormatException('Partida incompleta o inconsistente.');
    }
    final last = json['ultimaRespuesta'] as Map?;
    final movement = json['ultimoMovimiento'] as int;
    if (movement < -1 ||
        movement > 1 ||
        (progress.answered > 0) != (last != null) ||
        (last != null &&
            (last['esCorrecta'] is! bool || last['movimiento'] != movement)) ||
        (json['id'] as String).isEmpty) {
      throw const FormatException('Respuesta de partida inconsistente.');
    }
    return SummitAttempt(
      id: json['id'] as String,
      area: area,
      progress: progress,
      question: question,
      status: status,
      expiresAt: DateTime.parse(json['venceEn'] as String),
      lastCorrect: last?['esCorrecta'] as bool?,
      lastMovement: movement,
    );
  }
}

class SummitPendingAnswer {
  const SummitPendingAnswer({
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
  factory SummitPendingAnswer.fromJson(Map<String, dynamic> json) =>
      SummitPendingAnswer(
        attemptId: json['attemptId'] as String,
        questionId: json['questionId'] as String,
        answerId: json['answerId'] as String,
        requestKey: json['requestKey'] as String,
      );
}

abstract interface class SummitRepository {
  bool get isDemo;
  SummitPendingAnswer? get pending;
  SummitAttempt? get current;
  Future<SummitAttempt?> restore();
  Future<SummitAttempt> abandon(String attemptId);
  Future<SummitAttempt> start(
    AcademicArea area, {
    String? themeId,
    String? subtopicId,
    PracticeDifficulty? difficulty,
  });
  Future<SummitAttempt> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required String requestKey,
  });
}
