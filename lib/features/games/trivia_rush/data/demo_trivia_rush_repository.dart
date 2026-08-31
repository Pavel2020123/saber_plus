import '../../../practice/data/demo_practice_repository.dart';
import '../../../practice/domain/practice_models.dart';
import '../../../practice/domain/practice_repository.dart';
import '../domain/trivia_rush_models.dart';
import '../domain/trivia_rush_repository.dart';

class DemoTriviaRushRepository implements TriviaRushRepository {
  DemoTriviaRushRepository({PracticeRepository? practiceRepository})
    : _practiceRepository = practiceRepository ?? DemoPracticeRepository();

  final PracticeRepository _practiceRepository;
  final Map<String, PracticeQuestion> _questions = {};

  @override
  Future<TriviaRushSession> start(TriviaRushConfig config) async {
    final practice = await _practiceRepository.startRandomPractice(
      RandomPracticeConfig(areas: config.areas, questionCount: 30),
    );
    final progressiveQuestions = <PracticeQuestion>[
      for (var index = 0; index < practice.questions.length; index++)
        _withProgressiveDifficulty(practice.questions[index], index),
    ];
    _questions
      ..clear()
      ..addEntries(
        progressiveQuestions.map((question) => MapEntry(question.id, question)),
      );
    return TriviaRushSession(
      attemptId: practice.attemptId,
      questions: List.unmodifiable(progressiveQuestions),
    );
  }

  @override
  Future<TriviaRushAnswerEvaluation> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required int responseTimeSeconds,
  }) async {
    final result = await _practiceRepository.gradeRandomPractice(
      attemptId: attemptId,
      answers: [
        PracticeAnswer(
          questionId: questionId,
          answerId: answerId,
          responseTimeSeconds: responseTimeSeconds,
        ),
      ],
    );
    final review = result.review.single;
    return TriviaRushAnswerEvaluation(
      questionId: questionId,
      isCorrect: review.isCorrect,
      correctAnswerId: review.correctAnswerId,
      explanation: review.explanation,
    );
  }

  @override
  Future<TriviaRushBoosterActivation> activateBooster({
    required String attemptId,
    required String questionId,
    required TriviaRushBooster booster,
  }) async {
    if (booster != TriviaRushBooster.fiftyFifty) {
      return const TriviaRushBoosterActivation();
    }
    final question = _questions[questionId];
    if (question == null) return const TriviaRushBoosterActivation();
    final incorrect = <String>[];
    for (final option in question.options) {
      final evaluation = await answer(
        attemptId: attemptId,
        questionId: questionId,
        answerId: option.id,
        responseTimeSeconds: 0,
      );
      if (!evaluation.isCorrect) incorrect.add(option.id);
      if (incorrect.length == 2) break;
    }
    return TriviaRushBoosterActivation(eliminatedAnswerIds: incorrect.toSet());
  }
}

PracticeQuestion _withProgressiveDifficulty(
  PracticeQuestion question,
  int index,
) => PracticeQuestion(
  id: question.id,
  statement: question.statement,
  difficulty: switch (index) {
    < 10 => 'BASICA',
    < 20 => 'MEDIA',
    _ => 'AVANZADA',
  },
  options: question.options,
  subtopicName: question.subtopicName,
  themeName: question.themeName,
  area: question.area,
  subtopicId: question.subtopicId,
  imageUrl: question.imageUrl,
  orderInCase: question.orderInCase,
  caseContent: question.caseContent,
);
