import 'practice_history_models.dart';

class DailyMistakeReview {
  const DailyMistakeReview({required this.day, required this.mistakes});

  final DateTime day;
  final List<AnswerHistoryItem> mistakes;

  factory DailyMistakeReview.fromHistory(
    AnswerHistory history, {
    required DateTime day,
  }) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final latestByQuestion = <String, AnswerHistoryItem>{};
    for (final answer in history.answers) {
      if (answer.isCorrect || !_isSameDay(answer.answeredAt, normalizedDay)) {
        continue;
      }
      final previous = latestByQuestion[answer.questionId];
      if (previous == null || answer.answeredAt.isAfter(previous.answeredAt)) {
        latestByQuestion[answer.questionId] = answer;
      }
    }
    final mistakes = latestByQuestion.values.toList()
      ..sort((a, b) => b.answeredAt.compareTo(a.answeredAt));
    return DailyMistakeReview(
      day: normalizedDay,
      mistakes: List.unmodifiable(mistakes),
    );
  }
}

bool _isSameDay(DateTime value, DateTime day) {
  final local = value.toLocal();
  return local.year == day.year &&
      local.month == day.month &&
      local.day == day.day;
}
