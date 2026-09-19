import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
import '../../../practice/data/demo_practice_repository.dart';
import '../../../practice/domain/practice_models.dart';
import '../domain/summit_models.dart';

/// In-memory demo only. Never uses a real practice attempt or grants its XP.
class DemoSummitRepository implements SummitRepository {
  @override
  bool get isDemo => true;
  @override
  SummitPendingAnswer? get pending => null;
  @override
  Future<SummitAttempt?> restore() async => _current;
  @override
  Future<SummitAttempt> abandon(String attemptId) async {
    final attempt = _current;
    if (_busy || attempt == null || attempt.id != attemptId) {
      _conflict('No se puede abandonar esta partida.');
    }
    if (attempt.finished) return attempt;
    return _current = SummitAttempt(
      id: attempt.id,
      area: attempt.area,
      progress: attempt.progress,
      question: null,
      status: 'ABANDONADO',
    );
  }

  final _practice = DemoPracticeRepository();
  List<PracticeQuestion> _questions = const [];
  final _requests = <String, (String, String)>{};
  bool _busy = false;
  SummitAttempt? _current;

  @override
  SummitAttempt? get current => _current;

  Never _conflict(String message) =>
      throw ApiError(code: 'conflict', message: message);

  @override
  Future<SummitAttempt> start(
    AcademicArea area, {
    String? themeId,
    String? subtopicId,
    PracticeDifficulty? difficulty,
  }) async {
    if (_busy) _conflict('Espera a que termine el envío.');
    final previous = _current;
    if (previous != null && !previous.finished) {
      if (previous.area != area) {
        _conflict('Termina tu partida actual primero.');
      }
      return previous;
    }
    _busy = true;
    try {
      final session = await _practice.startRandomPractice(
        RandomPracticeConfig(
          areas: [area],
          questionCount: SummitProgress.questionLimit,
        ),
      );
      if (session.questions.length != SummitProgress.questionLimit ||
          session.questions.map((q) => q.id).toSet().length !=
              session.questions.length ||
          session.questions.any((q) => q.options.length < 2)) {
        throw const ApiError(
          code: 'insufficient_content',
          message: 'No hay suficientes preguntas para iniciar.',
        );
      }
      _questions = List.unmodifiable(session.questions);
      _requests.clear();
      return _current = SummitAttempt(
        id: session.attemptId,
        area: area,
        progress: const SummitProgress.initial(),
        question: _questions.first,
      );
    } finally {
      _busy = false;
    }
  }

  @override
  Future<SummitAttempt> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required String requestKey,
  }) async {
    final attempt = _current;
    if (attempt == null || attempt.id != attemptId) {
      _conflict('Partida no encontrada.');
    }
    if (requestKey.isEmpty) _conflict('El envío necesita un identificador.');
    final previous = _requests[requestKey];
    if (previous != null) {
      if (previous != (questionId, answerId)) {
        _conflict('Ese envío corresponde a otra respuesta.');
      }
      return attempt;
    }
    if (_busy) _conflict('Espera a que termine el envío.');
    final question = attempt.question;
    if (attempt.finished ||
        question == null ||
        question.id != questionId ||
        !question.options.any((option) => option.id == answerId)) {
      _conflict('Esa respuesta no corresponde a la pregunta actual.');
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
      final correct = result.review.single.isCorrect;
      final progress = attempt.progress.answer(correct);
      final next = SummitAttempt(
        id: attempt.id,
        area: attempt.area,
        progress: progress,
        question: progress.finished ? null : _questions[progress.answered],
        lastCorrect: correct,
        lastMovement: progress.step - attempt.progress.step,
      );
      _requests[requestKey] = (questionId, answerId);
      return _current = next;
    } finally {
      _busy = false;
    }
  }
}
