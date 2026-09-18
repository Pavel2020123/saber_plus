import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';

/// Initial play-test rules. Authoritative remote rules are a separate delivery.
class SummitProgress {
  const SummitProgress._(this.step, this.peak, this.answered, this.correct);
  const SummitProgress.initial() : this._(0, 0, 0, 0);

  static const target = 5;
  static const questionLimit = 12;
  final int step;
  final int peak;
  final int answered;
  final int correct;
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
  });
  final String id;
  final AcademicArea area;
  final SummitProgress progress;
  final PracticeQuestion? question;
  final bool? lastCorrect;
  final int lastMovement;
}

abstract interface class SummitRepository {
  SummitAttempt? get current;
  Future<SummitAttempt> start(AcademicArea area);
  Future<SummitAttempt> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required String requestKey,
  });
}
