/// MA-3A: deterministic scheduling only. Persistence and synchronization belong
/// to MA-3B. These self-reports never establish academic mastery or award XP.
enum RecallOutcome { remembered, needsPractice }

enum ReviewDisposition { scheduled, tooEarly, stale }

class DeferredReview {
  DeferredReview({
    required this.userId,
    required this.cardId,
    required this.step,
    required this.revision,
    required DateTime reviewedAt,
    required DateTime dueAt,
  }) : reviewedAt = reviewedAt.toUtc(),
       dueAt = dueAt.toUtc() {
    if (userId.trim().isEmpty ||
        cardId.trim().isEmpty ||
        step < 0 ||
        step >= DeferredReviewPolicy.intervals.length ||
        revision < 1 ||
        !this.dueAt.isAfter(this.reviewedAt)) {
      throw ArgumentError('Invalid deferred review state');
    }
  }

  final String userId;
  final String cardId;
  final int step;
  final int revision;
  final DateTime reviewedAt;
  final DateTime dueAt;

  bool isDue(DateTime now) => !dueAt.isAfter(now.toUtc());
}

class ReviewDecision {
  const ReviewDecision(this.disposition, this.review);
  final ReviewDisposition disposition;
  final DeferredReview review;
  bool get changed => disposition == ReviewDisposition.scheduled;
}

/// Intervals are elapsed UTC days (24 hours), not local calendar boundaries.
/// A late review advances at most one step, from the actual review time.
class DeferredReviewPolicy {
  static const version = 1;
  static const intervals = [1, 3, 7, 14, 30];

  static ReviewDecision record({
    required String userId,
    required String cardId,
    required RecallOutcome outcome,
    required DateTime reviewedAt,
    required int expectedRevision,
    DeferredReview? previous,
  }) {
    if (userId.trim().isEmpty ||
        cardId.trim().isEmpty ||
        expectedRevision < 0) {
      throw ArgumentError('Invalid identity or revision');
    }
    if (previous != null &&
        (previous.userId != userId || previous.cardId != cardId)) {
      throw ArgumentError('A review cannot cross accounts or cards');
    }
    if (expectedRevision != (previous?.revision ?? 0)) {
      if (previous == null) throw StateError('Missing previous revision');
      return ReviewDecision(ReviewDisposition.stale, previous);
    }
    final now = reviewedAt.toUtc();
    if (previous != null && !previous.isDue(now)) {
      // Practice is still permitted. It must not postpone or advance the agenda.
      return ReviewDecision(ReviewDisposition.tooEarly, previous);
    }
    final step = previous == null || outcome == RecallOutcome.needsPractice
        ? 0
        : (previous.step + 1).clamp(0, intervals.length - 1);
    return ReviewDecision(
      ReviewDisposition.scheduled,
      DeferredReview(
        userId: userId,
        cardId: cardId,
        step: step,
        revision: (previous?.revision ?? 0) + 1,
        reviewedAt: now,
        dueAt: now.add(Duration(days: intervals[step])),
      ),
    );
  }
}

class DeferredReviewAgenda {
  const DeferredReviewAgenda._(this.due, this.upcoming);
  final List<DeferredReview> due;
  final List<DeferredReview> upcoming;

  /// The caller supplies the currently available catalog, never retired cards.
  /// Missing agenda entries are new cards, not overdue cards.
  factory DeferredReviewAgenda.build({
    required String userId,
    required Iterable<DeferredReview> reviews,
    required Set<String> availableCardIds,
    required DateTime now,
  }) {
    if (userId.trim().isEmpty) throw ArgumentError('Missing account');
    final selected = <String, DeferredReview>{};
    for (final row in reviews) {
      if (row.userId != userId || !availableCardIds.contains(row.cardId)) {
        continue;
      }
      if (selected.containsKey(row.cardId)) {
        // Ambiguous persistence must be reconciled, not silently counted twice.
        throw StateError('Duplicate agenda entry');
      }
      selected[row.cardId] = row;
    }
    final ordered = selected.values.toList()
      ..sort((a, b) {
        final date = a.dueAt.compareTo(b.dueAt);
        return date != 0 ? date : a.cardId.compareTo(b.cardId);
      });
    return DeferredReviewAgenda._(
      List.unmodifiable(ordered.where((row) => row.isDue(now))),
      List.unmodifiable(ordered.where((row) => !row.isDue(now))),
    );
  }
}
