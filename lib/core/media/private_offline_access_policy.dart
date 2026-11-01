import 'dart:math';

/// Security policy for future private lesson packages, never exported PDFs.
/// No wall-clock reads, disk writes, token storage or offline identity creation.
class OfflineClockSample {
  const OfflineClockSample({required this.bootId, required this.elapsed});

  final String bootId;
  // Platform adapter must use elapsed time INCLUDING device sleep.
  final Duration elapsed;

  bool get isValid => bootId.isNotEmpty && !elapsed.isNegative;
}

class PrivateOfflineGrant {
  const PrivateOfflineGrant({
    required this.ownerId,
    required this.contextId,
    required this.validatedAt,
    required this.expiresAt,
    required this.requestNonce,
  });

  final String ownerId;
  final String contextId;
  // These values come from successful backend permission validation, not a
  // generic HTTP success, login, local cache hit or device DateTime.now().
  final DateTime validatedAt;
  final DateTime expiresAt;
  final String requestNonce;
}

class OfflineValidationAttempt {
  const OfflineValidationAttempt._(
    this.ownerId,
    this.contextId,
    this.generation,
    this.sequence,
    this.started,
    this.requestNonce,
  );

  final String ownerId;
  final String contextId;
  final int generation;
  final int sequence;
  final OfflineClockSample started;
  final String requestNonce;
}

enum PrivateOfflineAccess { allowed, revalidationRequired }

class _Lease {
  _Lease(this.anchor) : lastObserved = anchor.elapsed;
  final OfflineClockSample anchor;
  Duration lastObserved;
}

class PrivateOfflineAccessPolicy {
  static const window = Duration(hours: 72);

  String? _ownerId;
  var _generation = 0;
  var _sequence = 0;
  final _random = Random.secure();
  final _leases = <String, _Lease>{};
  final _attempts = <String, OfflineValidationAttempt>{};

  void changeAccount(String? ownerId) {
    if (ownerId != null && ownerId.trim().isEmpty) {
      throw ArgumentError.value(ownerId, 'ownerId');
    }
    if (_ownerId == ownerId) return;
    _ownerId = ownerId;
    _invalidateAll();
  }

  OfflineValidationAttempt beginValidation(
    String contextId,
    OfflineClockSample started,
  ) {
    if (_ownerId == null || contextId.isEmpty || !started.isValid) {
      throw StateError('Se requiere cuenta, contexto y reloj confiable.');
    }
    final sequence = ++_sequence;
    final attempt = OfflineValidationAttempt._(
      _ownerId!,
      contextId,
      _generation,
      sequence,
      started,
      List.generate(
        32,
        (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join(),
    );
    _attempts[contextId] = attempt;
    return attempt;
  }

  /// Accept only an authorized backend grant for this exact account/context.
  /// Anchor at REQUEST START: slow responses must never extend the 72 hours.
  bool acceptValidation(
    OfflineValidationAttempt attempt,
    PrivateOfflineGrant grant,
    OfflineClockSample received,
  ) {
    if (_ownerId != attempt.ownerId ||
        attempt.generation != _generation ||
        !identical(_attempts[attempt.contextId], attempt)) {
      return false;
    }
    _attempts.remove(attempt.contextId);
    if (grant.ownerId != _ownerId ||
        grant.requestNonce != attempt.requestNonce ||
        grant.contextId != attempt.contextId ||
        !grant.validatedAt.isUtc ||
        !grant.expiresAt.isUtc ||
        grant.expiresAt.difference(grant.validatedAt) != window ||
        !_sameBoot(attempt.started, received) ||
        received.elapsed - attempt.started.elapsed >= window) {
      _leases.remove(attempt.contextId);
      return false;
    }
    _leases[attempt.contextId] = _Lease(attempt.started);
    return true;
  }

  Duration remaining(String ownerId, String contextId, OfflineClockSample now) {
    final lease = _leases[contextId];
    if (ownerId != _ownerId || lease == null) return Duration.zero;
    if (!_sameBoot(lease.anchor, now) || now.elapsed < lease.lastObserved) {
      _leases.remove(contextId);
      return Duration.zero;
    }
    lease.lastObserved = now.elapsed;
    final remaining = window - (now.elapsed - lease.anchor.elapsed);
    if (remaining <= Duration.zero) {
      _leases.remove(contextId);
      return Duration.zero;
    }
    return remaining;
  }

  PrivateOfflineAccess access(
    String ownerId,
    String contextId,
    OfflineClockSample now,
  ) => remaining(ownerId, contextId, now) > Duration.zero
      ? PrivateOfflineAccess.allowed
      : PrivateOfflineAccess.revalidationRequired;

  /// Confirmed revocation wins synchronously, including over late HTTP replies.
  void confirmRevocation(String contextId) {
    _generation++;
    _attempts.clear();
    _leases.remove(contextId);
  }

  /// Confirmed suspension/invalid session must block every private package.
  void confirmSuspension() => _invalidateAll();

  void logout() {
    _ownerId = null;
    _invalidateAll();
  }

  void _invalidateAll() {
    _generation++;
    _attempts.clear();
    _leases.clear();
  }

  static bool _sameBoot(OfflineClockSample start, OfflineClockSample end) =>
      start.isValid &&
      end.isValid &&
      start.bootId == end.bootId &&
      end.elapsed >= start.elapsed;
}
