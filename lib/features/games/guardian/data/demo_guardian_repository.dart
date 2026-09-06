import '../../../../core/network/api_error.dart';
import '../../../practice/data/demo_practice_repository.dart';
import '../../../practice/domain/practice_models.dart';
import '../domain/guardian_models.dart';

/// Solo cuentas demo: jamás envía ni guarda puntuaciones en el backend.
class DemoGuardianRepository implements GuardianRepository {
  final _practice = DemoPracticeRepository();
  GuardianAttempt? _attempt;
  List<PracticeQuestion> _questions = [];
  final Map<String, (String, String)> _keys = {};

  @override
  Future<GuardianAttempt?> active() async =>
      _attempt?.isActive == true ? _attempt : null;
  @override
  Future<GuardianAttempt> start(GuardianConfig config) async {
    if (_attempt?.isActive == true) return _attempt!;
    final session = await _practice.startRandomPractice(
      RandomPracticeConfig(
        areas: [config.area],
        questionCount: GuardianAttempt.maxQuestions,
      ),
    );
    _questions = session.questions;
    _keys.clear();
    return _attempt = GuardianAttempt(
      id: session.attemptId,
      config: config,
      status: GuardianStatus.active,
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      review: const [],
      question: _questions.first,
    );
  }

  @override
  Future<GuardianAttempt> get(String id) async {
    if (_attempt?.id != id) {
      throw const ApiError(
        code: 'not_found',
        message: 'Desafío demo no encontrado.',
      );
    }
    return _attempt!;
  }

  @override
  Future<GuardianAttempt> answer({
    required String id,
    required String questionId,
    required String answerId,
    required String idempotencyKey,
  }) async {
    final attempt = await get(id);
    if (_keys.containsKey(idempotencyKey)) {
      if (_keys[idempotencyKey] != (questionId, answerId)) {
        throw const ApiError(
          code: 'conflict',
          message: 'Este envío ya se usó.',
        );
      }
      return attempt;
    }
    if (!attempt.isActive ||
        attempt.question?.id != questionId ||
        !attempt.question!.options.any((o) => o.id == answerId)) {
      throw const ApiError(
        code: 'conflict',
        message: 'La pregunta no está disponible.',
      );
    }
    final result = await _practice.gradeRandomPractice(
      attemptId: id,
      answers: [
        PracticeAnswer(
          questionId: questionId,
          answerId: answerId,
          responseTimeSeconds: 0,
        ),
      ],
    );
    final evaluation = result.review.single;
    final reviews = [
      ...attempt.review,
      GuardianReview(
        question: attempt.question!,
        answerId: answerId,
        isCorrect: evaluation.isCorrect,
        correctAnswerId: evaluation.correctAnswerId,
        explanation: evaluation.explanation,
      ),
    ];
    final correct = reviews.where((r) => r.isCorrect).length;
    final status = correct >= GuardianAttempt.target
        ? GuardianStatus.victory
        : reviews.length - correct >= GuardianAttempt.shields
        ? GuardianStatus.defeat
        : GuardianStatus.active;
    _keys[idempotencyKey] = (questionId, answerId);
    return _attempt = GuardianAttempt(
      id: id,
      config: attempt.config,
      status: status,
      expiresAt: attempt.expiresAt,
      review: List.unmodifiable(reviews),
      question: status == GuardianStatus.active
          ? _questions[reviews.length]
          : null,
    );
  }

  @override
  Future<GuardianAttempt> abandon(String id) async {
    final a = await get(id);
    if (!a.isActive) return a;
    return _attempt = GuardianAttempt(
      id: a.id,
      config: a.config,
      status: GuardianStatus.abandoned,
      expiresAt: a.expiresAt,
      review: a.review,
    );
  }
}
