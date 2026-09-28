import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/sync/safe_sync_models.dart';
import '../domain/deferred_review.dart';

const reviewContentVersion = 'library-v1';

Map<String, Object> reviewJson(DeferredReview row) => {
  'tarjetaId': row.cardId,
  'contenidoVersion': reviewContentVersion,
  'paso': row.step,
  'revision': row.revision,
  'revisadoEn': row.reviewedAt.toIso8601String(),
  'venceEn': row.dueAt.toIso8601String(),
};

DeferredReview parseReview(Object? raw, String userId, Set<String> allowed) {
  if (raw is! Map ||
      raw['contenidoVersion'] != reviewContentVersion ||
      raw['tarjetaId'] is! String ||
      !allowed.contains(raw['tarjetaId']) ||
      raw['paso'] is! int ||
      raw['revision'] is! int) {
    throw const FormatException('Agenda no válida.');
  }
  DateTime date(Object? value) {
    if (value is! String || !value.endsWith('Z')) {
      throw const FormatException('Fecha UTC requerida.');
    }
    return DateTime.parse(value).toUtc();
  }

  final row = DeferredReview(
    userId: userId,
    cardId: raw['tarjetaId'] as String,
    step: raw['paso'] as int,
    revision: raw['revision'] as int,
    reviewedAt: date(raw['revisadoEn']),
    dueAt: date(raw['venceEn']),
  );
  if (row.dueAt.difference(row.reviewedAt) !=
      Duration(days: DeferredReviewPolicy.intervals[row.step])) {
    throw const FormatException('Intervalo no válido.');
  }
  return row;
}

/// One durable in-flight event per card. The confirmed snapshot is never
/// overwritten by an offline prediction. UI integration is MA-3C.
class DeferredReviewRepository {
  DeferredReviewRepository(
    this.db,
    this.dio, {
    required this.currentSession,
    required Set<String> allowedCardIds,
    DateTime Function()? now,
  }) : allowedCardIds = Set.unmodifiable(allowedCardIds),
       now = now ?? DateTime.now;
  final AppDatabase db;
  final Dio dio;
  final SyncSessionSnapshot? Function() currentSession;
  final Set<String> allowedCardIds;
  final DateTime Function() now;
  Future<void>? _active;
  bool _disposed = false;
  final CancelToken _cancel = CancelToken();
  void dispose() {
    _disposed = true;
    _cancel.cancel();
  }

  bool _current(SyncSessionSnapshot s) {
    final actual = currentSession();
    return !_disposed &&
        s.userId == actual?.userId &&
        s.revision == actual?.revision;
  }

  SyncSessionSnapshot _session(String userId) {
    final s = currentSession();
    if (_disposed || s == null || s.userId != userId) {
      throw StateError('Sesión no disponible.');
    }
    return s;
  }

  Stream<List<DeferredReviewEntry>> watch(String userId) {
    _session(userId);
    return (db.select(
      db.deferredReviewEntries,
    )..where((r) => r.userId.equals(userId))).watch();
  }

  Future<DeferredReviewEntry?> _row(String userId, String cardId) =>
      (db.select(db.deferredReviewEntries)
            ..where((r) => r.userId.equals(userId) & r.cardId.equals(cardId)))
          .getSingleOrNull();

  Future<void> enqueue({
    required String userId,
    required String cardId,
    required RecallOutcome outcome,
  }) async {
    final session = _session(userId);
    if (!allowedCardIds.contains(cardId)) {
      throw ArgumentError('Tarjeta no disponible.');
    }
    await db.transaction(() async {
      if (!_current(session)) throw StateError('La sesión cambió.');
      final old = await _row(userId, cardId);
      if (old?.pendingJson != null) {
        throw StateError('Esta tarjeta ya tiene un repaso pendiente.');
      }
      final previous = old?.confirmedJson == null
          ? null
          : parseReview(
              jsonDecode(old!.confirmedJson!),
              userId,
              allowedCardIds,
            );
      final prediction = DeferredReviewPolicy.record(
        userId: userId,
        cardId: cardId,
        outcome: outcome,
        reviewedAt: now(),
        expectedRevision: previous?.revision ?? 0,
        previous: previous,
      );
      if (!prediction.changed) return;
      final payload = jsonEncode({
        'version': 1,
        'eventoId': _eventId(),
        'tarjetaId': cardId,
        'contenidoVersion': reviewContentVersion,
        'revision': previous?.revision ?? 0,
        'resultado': outcome.name,
      });
      if (!_current(session)) throw StateError('La sesión cambió.');
      await db
          .into(db.deferredReviewEntries)
          .insertOnConflictUpdate(
            DeferredReviewEntriesCompanion.insert(
              userId: userId,
              cardId: cardId,
              confirmedJson: Value(old?.confirmedJson),
              provisionalJson: Value(jsonEncode(reviewJson(prediction.review))),
              pendingJson: Value(payload),
              status: const Value('pending'),
            ),
          );
    });
  }

  Future<void> synchronize(String userId) {
    _session(userId);
    // A new account must not join another account's in-flight synchronization.
    if (_active != null) return _active!.then((_) => synchronize(userId));
    return _active = _run(userId).whenComplete(() => _active = null);
  }

  Options _options(SyncSessionSnapshot s) =>
      Options(extra: {AuthInterceptor.sessionRevisionKey: s.revision});
  Future<void> _run(String userId) async {
    final session = _session(userId);
    final rows =
        await (db.select(db.deferredReviewEntries)..where(
              (r) => r.userId.equals(userId) & r.status.equals('pending'),
            ))
            .get();
    for (final row in rows) {
      if (!_current(session)) return;
      if (row.pendingJson == null) continue;
      final payload = jsonDecode(row.pendingJson!) as Map<String, dynamic>;
      try {
        final response = await dio.post<Object?>(
          '/repasos-diferidos/me/eventos',
          data: payload,
          options: _options(session),
          cancelToken: _cancel,
        );
        if (!_current(session)) return;
        final raw = response.data;
        if (raw is! Map ||
            raw['version'] != 1 ||
            raw['eventoId'] != payload['eventoId'] ||
            !['scheduled', 'tooEarly'].contains(raw['estado'])) {
          throw const FormatException('Confirmación no válida.');
        }
        final confirmed = parseReview(raw['agenda'], userId, allowedCardIds);
        final expected = payload['revision'] as int;
        if (confirmed.cardId != row.cardId ||
            confirmed.revision !=
                expected + (raw['estado'] == 'scheduled' ? 1 : 0)) {
          throw const FormatException('Revisión no válida.');
        }
        await db.transaction(() async {
          if (!_current(session)) return;
          final latest = await _row(userId, row.cardId);
          if (latest?.pendingJson != row.pendingJson) return;
          final current = latest?.confirmedJson == null
              ? null
              : parseReview(
                  jsonDecode(latest!.confirmedJson!),
                  userId,
                  allowedCardIds,
                );
          final winner =
              current != null && current.revision > confirmed.revision
              ? current
              : confirmed;
          await (db.update(db.deferredReviewEntries)..where(
                (r) => r.userId.equals(userId) & r.cardId.equals(row.cardId),
              ))
              .write(
                DeferredReviewEntriesCompanion(
                  confirmedJson: Value(jsonEncode(reviewJson(winner))),
                  provisionalJson: const Value(null),
                  pendingJson: const Value(null),
                  status: const Value('synced'),
                ),
              );
        });
      } on DioException catch (error) {
        if (!_current(session)) return;
        final status = error.response?.statusCode;
        if (status == 409 || status == 410 || status == 400) {
          await _mark(
            row,
            session,
            status == 409
                ? 'conflict'
                : status == 410
                ? 'retired'
                : 'invalid',
          );
          continue;
        }
        // Network/401/403/429/5xx: retain identical request for explicit retry.
        return;
      } on FormatException {
        // The server might have saved it. Keep the SAME ID/body for retry.
        return;
      }
    }
    if (_current(session)) await refresh(userId);
  }

  Future<void> _mark(
    DeferredReviewEntry row,
    SyncSessionSnapshot session,
    String status,
  ) async {
    if (!_current(session)) return;
    await (db.update(db.deferredReviewEntries)..where(
          (r) =>
              r.userId.equals(row.userId) &
              r.cardId.equals(row.cardId) &
              r.pendingJson.equals(row.pendingJson!),
        ))
        .write(DeferredReviewEntriesCompanion(status: Value(status)));
  }

  Future<void> refresh(String userId) async {
    final session = _session(userId);
    final baseline = await (db.select(
      db.deferredReviewEntries,
    )..where((r) => r.userId.equals(userId))).get();
    if (!_current(session)) return;
    final response = await dio.get<Object?>(
      '/repasos-diferidos/me',
      options: _options(session),
      cancelToken: _cancel,
    );
    if (!_current(session)) return;
    final raw = response.data;
    if (raw is! Map ||
        raw['version'] != 1 ||
        raw['contenidoVersion'] != reviewContentVersion ||
        raw['agenda'] is! List) {
      throw const FormatException('Agenda no válida.');
    }
    final values = raw['agenda'] as List;
    if (values.length > allowedCardIds.length) {
      throw const FormatException('Agenda demasiado grande.');
    }
    final parsed = values
        .map((v) => parseReview(v, userId, allowedCardIds))
        .toList();
    if (parsed.map((r) => r.cardId).toSet().length != parsed.length) {
      throw const FormatException('Agenda repetida.');
    }
    await db.transaction(() async {
      final returned = parsed.map((r) => r.cardId).toSet();
      for (final old in baseline) {
        if (!_current(session)) throw StateError('La sesión cambió.');
        if (returned.contains(old.cardId) ||
            old.pendingJson != null ||
            old.confirmedJson == null) {
          continue;
        }
        // Remove retired server snapshots only if no newer local write occurred
        // while GET was in flight. Never erase an unsent event.
        await (db.delete(db.deferredReviewEntries)..where(
              (r) =>
                  r.userId.equals(userId) &
                  r.cardId.equals(old.cardId) &
                  r.pendingJson.isNull() &
                  r.confirmedJson.equals(old.confirmedJson!),
            ))
            .go();
      }
      for (final remote in parsed) {
        if (!_current(session)) throw StateError('La sesión cambió.');
        final old = await _row(userId, remote.cardId);
        final previous = old?.confirmedJson == null
            ? null
            : parseReview(
                jsonDecode(old!.confirmedJson!),
                userId,
                allowedCardIds,
              );
        if (previous != null && previous.revision >= remote.revision) continue;
        await db
            .into(db.deferredReviewEntries)
            .insertOnConflictUpdate(
              DeferredReviewEntriesCompanion.insert(
                userId: userId,
                cardId: remote.cardId,
                confirmedJson: Value(jsonEncode(reviewJson(remote))),
                provisionalJson: Value(old?.provisionalJson),
                pendingJson: Value(old?.pendingJson),
                status: Value(old?.status ?? 'synced'),
              ),
            );
      }
    });
  }

  /// Explicit user action only; never discard an uncertain/pending request.
  /// A conflict first retrieves the server state, then drops the obsolete answer.
  Future<void> discardBlocked(String userId, String cardId) async {
    final session = _session(userId);
    final old = await _row(userId, cardId);
    if (old == null ||
        !['conflict', 'retired', 'invalid'].contains(old.status)) {
      throw StateError(
        'Solo se pueden descartar eventos bloqueados confirmados.',
      );
    }
    if (old.status == 'conflict') await refresh(userId);
    if (!_current(session)) return;
    await (db.update(db.deferredReviewEntries)..where(
          (r) =>
              r.userId.equals(userId) &
              r.cardId.equals(cardId) &
              r.pendingJson.equals(old.pendingJson!) &
              r.status.equals(old.status),
        ))
        .write(
          DeferredReviewEntriesCompanion(
            pendingJson: const Value(null),
            provisionalJson: const Value(null),
            status: Value(old.status == 'retired' ? 'retired' : 'synced'),
          ),
        );
  }
}

String _eventId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}
