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
  });
  final String id;
  final AcademicArea area;
  final KnowledgeShieldProgress progress;
  final PracticeQuestion? question;
  final bool? lastCorrect;
  final bool abandoned;
  bool get finished => abandoned || progress.finished;
}

abstract interface class KnowledgeShieldRepository {
  KnowledgeShieldAttempt? get current;
  Future<KnowledgeShieldAttempt> start(AcademicArea area);
  Future<KnowledgeShieldAttempt> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required String requestKey,
  });
  Future<KnowledgeShieldAttempt> abandon(String attemptId);
}
