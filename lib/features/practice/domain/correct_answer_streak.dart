import 'practice_models.dart';

class CorrectAnswerStreak {
  const CorrectAnswerStreak({required this.longestRun});

  static const achievementThreshold = 3;

  final int longestRun;

  bool get earnsFeedback => longestRun >= achievementThreshold;

  factory CorrectAnswerStreak.fromReview(
    Iterable<PracticeReviewQuestion> review,
  ) {
    var currentRun = 0;
    var longestRun = 0;
    for (final question in review) {
      if (question.isCorrect) {
        currentRun++;
        if (currentRun > longestRun) longestRun = currentRun;
      } else {
        currentRun = 0;
      }
    }
    return CorrectAnswerStreak(longestRun: longestRun);
  }
}
