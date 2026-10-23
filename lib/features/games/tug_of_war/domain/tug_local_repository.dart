import '../../trivia_rush/domain/trivia_rush_models.dart';
import '../../trivia_rush/domain/trivia_rush_repository.dart';

/// Only the remote CPU duel can record an unanswered round without a reward.
abstract interface class TugLocalRepository implements TriviaRushRepository {
  Future<TugLocalRound> beginRound(String attemptId, String questionId);

  Future<TugLocalRound> setPaused({
    required String attemptId,
    required String questionId,
    required int version,
    required bool paused,
  });

  Future<TriviaRushSession> expireRound(String attemptId, String questionId);

  Future<void> abandon(String attemptId);
}

class TugLocalRound {
  const TugLocalRound({
    required this.session,
    required this.version,
    required this.paused,
    required this.remainingMilliseconds,
    this.receivedAt,
  });

  final TriviaRushSession session;
  final int version;
  final bool paused;
  final int remainingMilliseconds;
  final DateTime? receivedAt;

  int remainingAt(DateTime now) => paused || receivedAt == null
      ? remainingMilliseconds
      : (remainingMilliseconds - now.difference(receivedAt!).inMilliseconds)
            .clamp(0, 10000);
}
