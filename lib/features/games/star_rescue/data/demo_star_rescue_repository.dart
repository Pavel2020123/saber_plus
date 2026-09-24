import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
import '../../../practice/data/demo_practice_repository.dart';
import '../../../practice/domain/practice_models.dart';
import '../domain/star_rescue_models.dart';

/// Uses only local demonstration content. Never forwards simulated XP/results.
class DemoStarRescueRepository implements StarRescueRepository {
  final _practice = DemoPracticeRepository();
  final _requests = <String, (String, String)>{};
  List<PracticeQuestion> _questions = const [];
  StarRescueAttempt? _current;
  bool _busy = false;
  bool _disposed = false;
  @override
  StarRescueAttempt? get current => _current;
  @override
  bool get isDemo => true;
  @override
  StarRescuePendingAnswer? get pending => null;
  @override
  Future<StarRescueAttempt?> restore() async {
    _check();
    return _current;
  }

  void dispose() {
    _disposed = true;
    _current = null;
    _questions = const [];
    _requests.clear();
  }

  Never _fail(String message) =>
      throw ApiError(code: 'star_rescue_conflict', message: message);
  void _check() {
    if (_disposed) _fail('La cuenta cambió. Abre el juego nuevamente.');
    if (_busy) _fail('Espera a que termine la operación.');
  }

  void _checkAccount() {
    if (_disposed) _fail('La cuenta cambió. Abre el juego nuevamente.');
  }

  @override
  Future<StarRescueAttempt> start(
    AcademicArea area, {
    String? themeId,
    String? subtopicId,
    PracticeDifficulty? difficulty,
  }) async {
    _check();
    final previous = _current;
    if (previous != null && !previous.finished) {
      if (previous.area != area) {
        _fail('Termina o abandona el rescate actual antes de cambiar de área.');
      }
      return previous;
    }
    _busy = true;
    try {
      final session = await _practice.startRandomPractice(
        RandomPracticeConfig(
          areas: [area],
          questionCount: StarRescueProgress.questionLimit,
        ),
      );
      _checkAccount();
      if (session.questions.length != StarRescueProgress.questionLimit ||
          session.questions.map((q) => q.id).toSet().length !=
              session.questions.length ||
          session.questions.any(
            (q) => q.options.length < 2 || q.area != area,
          )) {
        _fail('No hay suficientes preguntas de ejemplo para iniciar.');
      }
      _questions = List.unmodifiable(session.questions);
      _requests.clear();
      return _current = StarRescueAttempt(
        id: session.attemptId,
        area: area,
        progress: const StarRescueProgress.initial(),
        question: _questions.first,
      );
    } finally {
      _busy = false;
    }
  }

  @override
  Future<StarRescueAttempt> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required String requestKey,
  }) async {
    _check();
    final attempt = _current;
    if (attempt == null || attempt.id != attemptId) {
      _fail('Rescate no encontrado.');
    }
    if (requestKey.trim().isEmpty) _fail('El envío necesita un identificador.');
    final duplicate = _requests[requestKey];
    if (duplicate != null) {
      if (duplicate != (questionId, answerId)) {
        _fail('Ese envío corresponde a otra respuesta.');
      }
      return attempt;
    }
    final question = attempt.question;
    if (attempt.finished ||
        question?.id != questionId ||
        !question!.options.any((option) => option.id == answerId)) {
      _fail('La respuesta no corresponde a la pregunta actual.');
    }
    _busy = true;
    try {
      final result = await _practice.gradeRandomPractice(
        attemptId: attemptId,
        answers: [
          PracticeAnswer(
            questionId: questionId,
            answerId: answerId,
            responseTimeSeconds: 0,
          ),
        ],
      );
      _checkAccount();
      final correct = result.review.single.isCorrect;
      final progress = attempt.progress.answer(correct);
      final next = StarRescueAttempt(
        id: attempt.id,
        area: attempt.area,
        progress: progress,
        question: progress.finished ? null : _questions[progress.answered],
        lastCorrect: correct,
      );
      _requests[requestKey] = (questionId, answerId);
      return _current = next;
    } finally {
      _busy = false;
    }
  }

  @override
  Future<StarRescueAttempt> abandon(String attemptId) async {
    _check();
    final attempt = _current;
    if (attempt == null || attempt.id != attemptId) {
      _fail('Rescate no encontrado.');
    }
    if (attempt.finished) return attempt;
    return _current = StarRescueAttempt(
      id: attempt.id,
      area: attempt.area,
      progress: attempt.progress,
      question: null,
      abandoned: true,
    );
  }
}
