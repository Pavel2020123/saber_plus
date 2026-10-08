import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';

class GuardianConfig {
  const GuardianConfig({
    required this.area,
    required this.difficulty,
    this.subtopicId,
  });
  final AcademicArea area;
  final PracticeDifficulty difficulty;
  final String? subtopicId;
  Map<String, dynamic> toJson() => {
    'area': area.backendValue,
    'dificultad': difficulty.backendValue,
    if (subtopicId != null) 'subtemaId': subtopicId,
  };
}

enum GuardianStatus { active, victory, defeat, abandoned, expired }

class GuardianReview {
  const GuardianReview({
    required this.question,
    required this.answerId,
    required this.isCorrect,
    required this.correctAnswerId,
    this.explanation,
  });
  final PracticeQuestion question;
  final String answerId;
  final bool isCorrect;
  final String correctAnswerId;
  final String? explanation;
  String get correctText =>
      question.options.firstWhere((o) => o.id == correctAnswerId).text;
  factory GuardianReview.fromJson(Map<String, dynamic> json) => GuardianReview(
    question: PracticeQuestion.fromJson(
      Map<String, dynamic>.from(json['pregunta'] as Map),
    ),
    answerId: json['respuestaId'] as String,
    isCorrect: json['esCorrecta'] == true,
    correctAnswerId: json['respuestaCorrectaId'] as String,
    explanation: json['explicacion'] as String?,
  );
}

class GuardianAttempt {
  const GuardianAttempt({
    required this.id,
    required this.config,
    required this.status,
    required this.expiresAt,
    required this.review,
    this.question,
    this.isCompetitive = false,
  });
  static const target = 6;
  static const shields = 3;
  static const maxQuestions = 8;
  final String id;
  final GuardianConfig config;
  final GuardianStatus status;
  final DateTime expiresAt;
  final List<GuardianReview> review;
  final PracticeQuestion? question;

  /// Admission confirmed by the server, not a locally awarded score.
  final bool isCompetitive;
  bool get isActive => status == GuardianStatus.active;
  int get correct => review.where((r) => r.isCorrect).length;
  int get mistakes => review.length - correct;
  int get shield => (shields - mistakes).clamp(0, shields);
  int get energy => (target - correct).clamp(0, target);
  Iterable<GuardianReview> get toReinforce => review.where((r) => !r.isCorrect);
  factory GuardianAttempt.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('competitive') && json['competitive'] is! bool) {
      throw const FormatException('Modalidad competitiva inválida.');
    }
    final rules = Map<String, dynamic>.from(json['reglas'] as Map);
    if (rules['version'] != 1 ||
        rules['target'] != target ||
        rules['shields'] != shields ||
        rules['questions'] != maxQuestions) {
      throw const FormatException(
        'Actualiza la app para usar estas reglas del guardián.',
      );
    }
    return GuardianAttempt(
      id: json['id'] as String,
      isCompetitive: json['competitive'] == true,
      config: GuardianConfig(
        area: AcademicArea.fromBackend(json['area'] as String),
        difficulty: PracticeDifficulty.fromBackend(
          json['dificultad'] as String,
        ),
        subtopicId: json['subtemaId'] as String?,
      ),
      status: switch (json['estado']) {
        'ACTIVO' => GuardianStatus.active,
        'VICTORIA' => GuardianStatus.victory,
        'DERROTA' => GuardianStatus.defeat,
        'ABANDONADO' => GuardianStatus.abandoned,
        'EXPIRADO' => GuardianStatus.expired,
        _ => throw const FormatException('Estado de desafío no reconocido.'),
      },
      expiresAt: DateTime.parse(json['venceEn'] as String),
      question: json['pregunta'] == null
          ? null
          : PracticeQuestion.fromJson(
              Map<String, dynamic>.from(json['pregunta'] as Map),
            ),
      review: List.unmodifiable(
        (json['revision'] as List).map(
          (r) => GuardianReview.fromJson(Map<String, dynamic>.from(r as Map)),
        ),
      ),
    );
  }
}

class GuardianPendingAnswer {
  const GuardianPendingAnswer({
    required this.attemptId,
    required this.questionId,
    required this.answerId,
    required this.idempotencyKey,
  });
  final String attemptId;
  final String questionId;
  final String answerId;
  final String idempotencyKey;
  Map<String, dynamic> toJson() => {
    'attemptId': attemptId,
    'questionId': questionId,
    'answerId': answerId,
    'idempotencyKey': idempotencyKey,
  };
  factory GuardianPendingAnswer.fromJson(Map<String, dynamic> json) {
    final pending = GuardianPendingAnswer(
      attemptId: json['attemptId'] as String,
      questionId: json['questionId'] as String,
      answerId: json['answerId'] as String,
      idempotencyKey: json['idempotencyKey'] as String,
    );
    if ([
          pending.attemptId,
          pending.questionId,
          pending.answerId,
        ].any((id) => id.isEmpty) ||
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(pending.idempotencyKey)) {
      throw const FormatException('Envío pendiente inválido.');
    }
    return pending;
  }
}

abstract interface class GuardianRepository {
  GuardianPendingAnswer? get pending;
  Future<GuardianAttempt?> active();
  Future<GuardianAttempt> start(
    GuardianConfig config, {
    bool competitive = false,
  });
  Future<GuardianAttempt> get(String id);
  Future<GuardianAttempt> answer({
    required String id,
    required String questionId,
    required String answerId,
    required String idempotencyKey,
  });
  Future<GuardianAttempt> abandon(String id);
}
