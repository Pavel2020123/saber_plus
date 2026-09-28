import 'package:flutter_test/flutter_test.dart';
import 'package:saber_plus/features/flashcards/domain/deferred_review.dart';

final start = DateTime.utc(2026, 9, 27, 22);
ReviewDecision record({
  DeferredReview? previous,
  DateTime? at,
  RecallOutcome outcome = RecallOutcome.remembered,
  int? revision,
  String user = 'A',
  String card = 'card',
}) => DeferredReviewPolicy.record(
  userId: user,
  cardId: card,
  outcome: outcome,
  reviewedAt: at ?? start,
  expectedRevision: revision ?? previous?.revision ?? 0,
  previous: previous,
);

void main() {
  test('first self-report schedules one day for either outcome', () {
    for (final outcome in RecallOutcome.values) {
      final result = record(outcome: outcome);
      expect(result.review.dueAt, start.add(const Duration(days: 1)));
      expect(result.review.step, 0);
      expect(result.review.revision, 1);
    }
  });
  test('success advances 1, 3, 7, 14, 30 then caps at 30 days', () {
    var state = record().review;
    for (final days in [3, 7, 14, 30, 30]) {
      final time = state.dueAt;
      state = record(previous: state, at: time).review;
      expect(state.dueAt.difference(time).inDays, days);
    }
  });
  test('failure at due time resets to one day', () {
    var state = record().review;
    state = record(previous: state, at: state.dueAt).review;
    final result = record(
      previous: state,
      at: state.dueAt,
      outcome: RecallOutcome.needsPractice,
    );
    expect(result.review.step, 0);
    expect(result.review.dueAt.difference(state.dueAt).inDays, 1);
  });
  test('early repetitions do not change date, stage or revision', () {
    final state = record().review;
    for (final outcome in RecallOutcome.values) {
      final result = record(
        previous: state,
        at: start.add(const Duration(hours: 4)),
        outcome: outcome,
      );
      expect(result.disposition, ReviewDisposition.tooEarly);
      expect(result.review, same(state));
    }
  });
  test('replayed stale revision never advances the schedule', () {
    final state = record().review;
    final result = record(previous: state, at: state.dueAt, revision: 0);
    expect(result.disposition, ReviewDisposition.stale);
    expect(result.review, same(state));
  });
  test('late review advances once from actual time, not missed dates', () {
    final state = record().review;
    final time = start.add(const Duration(days: 100));
    final result = record(previous: state, at: time);
    expect(result.review.step, 1);
    expect(result.review.dueAt, time.add(const Duration(days: 3)));
  });
  test('clock rollback cannot advance or postpone the schedule', () {
    final state = record().review;
    expect(
      record(
        previous: state,
        at: start.subtract(const Duration(days: 1)),
      ).changed,
      false,
    );
  });
  test('due boundary is inclusive and UTC offset represents same instant', () {
    final state = record().review;
    expect(
      state.isDue(state.dueAt.subtract(const Duration(microseconds: 1))),
      false,
    );
    expect(state.isDue(DateTime.parse('2026-09-28T17:00:00-05:00')), true);
  });
  test('rejects cross-account/card updates and invalid revisions', () {
    final state = record().review;
    expect(() => record(previous: state, user: 'B'), throwsArgumentError);
    expect(() => record(previous: state, card: 'other'), throwsArgumentError);
    expect(() => record(revision: -1), throwsArgumentError);
    expect(() => record(revision: 1), throwsStateError);
  });
  test(
    'agenda separates due/upcoming and excludes retired and other accounts',
    () {
      final a = record().review;
      final b = record(
        card: 'next',
        at: start.add(const Duration(days: 3)),
      ).review;
      final agenda = DeferredReviewAgenda.build(
        userId: 'A',
        reviews: [
          a,
          b,
          record(user: 'B').review,
          record(card: 'retired').review,
        ],
        availableCardIds: {'card', 'next'},
        now: a.dueAt,
      );
      expect(agenda.due.map((r) => r.cardId), ['card']);
      expect(agenda.upcoming.map((r) => r.cardId), ['next']);
      expect(() => agenda.due.clear(), throwsUnsupportedError);
    },
  );
  test('agenda does not invent overdue entries for unseen cards', () {
    final agenda = DeferredReviewAgenda.build(
      userId: 'A',
      reviews: [],
      availableCardIds: {'new'},
      now: start,
    );
    expect(agenda.due, isEmpty);
    expect(agenda.upcoming, isEmpty);
  });
  test('agenda rejects ambiguous duplicate persistence', () {
    final state = record().review;
    expect(
      () => DeferredReviewAgenda.build(
        userId: 'A',
        reviews: [state, state],
        availableCardIds: {'card'},
        now: start,
      ),
      throwsStateError,
    );
  });
}
