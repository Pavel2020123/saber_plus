import '../../../../core/network/api_error.dart';
import '../domain/trivia_rush_models.dart';
import '../domain/trivia_rush_repository.dart';

class PendingTriviaRushRepository implements TriviaRushRepository {
  const PendingTriviaRushRepository();

  Never _pending() => throw const ApiError(
    code: 'trivia_rush_backend_pending',
    message:
        'Trivia Rush está listo en la app, pero falta publicar su validación segura en el servidor.',
  );

  @override
  Future<TriviaRushSession> start(TriviaRushConfig config) async => _pending();

  @override
  Future<TriviaRushAnswerEvaluation> answer({
    required String attemptId,
    required String questionId,
    required String answerId,
    required int responseTimeSeconds,
  }) async => _pending();

  @override
  Future<TriviaRushBoosterActivation> activateBooster({
    required String attemptId,
    required String questionId,
    required TriviaRushBooster booster,
  }) async => _pending();
}
