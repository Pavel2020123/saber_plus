import 'trivia_rush_models.dart';

abstract interface class TriviaRushRepository {
  Future<TriviaRushSession> start(TriviaRushConfig config);

  Future<TriviaRushAnswerEvaluation> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required int responseTimeSeconds,
  });

  Future<TriviaRushBoosterActivation> activateBooster({
    required String attemptId,
    required String questionId,
    required TriviaRushBooster booster,
  });
}

abstract interface class AuthoritativeTriviaRushRepository {
  Future<TriviaRushSession> synchronize(String attemptId);

  Future<TriviaRushSession> finish(String attemptId);

  Future<void> abandon(String attemptId);
}
