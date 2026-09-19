import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';

/// Initial play-test parameters, not a published server contract.
class StarRescueProgress {
  const StarRescueProgress._(this.answered, this.stars);
  const StarRescueProgress.initial() : this._(0, 0);
  static const target = 6;
  static const groupSize = 3;
  static const questionLimit = 10;
  final int answered;
  final int stars;
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
  });
  final String id;
  final AcademicArea area;
  final StarRescueProgress progress;
  final PracticeQuestion? question;
  final bool? lastCorrect;
  final bool abandoned;
  bool get finished => abandoned || progress.finished;
}

abstract interface class StarRescueRepository {
  StarRescueAttempt? get current;
  Future<StarRescueAttempt> start(AcademicArea area);
  Future<StarRescueAttempt> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required String requestKey,
  });
  Future<StarRescueAttempt> abandon(String attemptId);
}
