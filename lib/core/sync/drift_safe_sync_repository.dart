import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../network/api_client.dart';
import 'safe_sync_models.dart';
import 'safe_sync_repository.dart';

class DriftSafeSyncRepository implements SafeSyncRepository {
  DriftSafeSyncRepository(this._dio, this._database);

  final Dio _dio;
  final AppDatabase _database;
  final Map<String, Future<SyncReport>> _activeSynchronizations = {};

  @override
  Stream<List<SyncOperation>> watchOperations(String userId) => _database
      .watchPendingOperations(userId)
      .map((rows) => rows.map(_fromRow).toList(growable: false));

  @override
  Future<SafeWriteResult> saveStudyProgress({
    required String userId,
    required String subtopicId,
    required int percentage,
  }) async {
    final operationId = _operationId(
      userId,
      SyncOperationKind.studyProgress,
      subtopicId,
    );
    await _enqueueProgress(
      id: operationId,
      userId: userId,
      subtopicId: subtopicId,
      percentage: percentage.clamp(0, 100),
    );
    await synchronize(userId);
    return _resultFor(operationId);
  }

  @override
  Future<SafeWriteResult> saveNotebookEntry({
    required String userId,
    required String questionId,
    required String note,
    required String status,
  }) async {
    final operationId = _operationId(
      userId,
      SyncOperationKind.notebookEntry,
      questionId,
    );
    await _enqueue(
      id: operationId,
      userId: userId,
      kind: SyncOperationKind.notebookEntry,
      entityId: questionId,
      payload: {'nota': note.trim(), 'estado': status},
    );
    await synchronize(userId);
    return _resultFor(operationId);
  }

  @override
  Future<SyncReport> synchronize(String userId) async {
    final active = _activeSynchronizations[userId];
    if (active != null) return active;
    final future = _performSynchronization(userId);
    _activeSynchronizations[userId] = future;
    try {
      return await future;
    } finally {
      _activeSynchronizations.remove(userId);
    }
  }

  @override
  Future<SyncReport> retry(String userId, String operationId) async {
    final row = await _database.findPendingOperation(operationId);
    if (row != null && row.userId == userId) {
      await _database.savePendingOperation(
        _companionFromRow(
          row,
          status: SyncOperationStatus.pending,
          clearError: true,
        ),
      );
    }
    return synchronize(userId);
  }

  @override
  Future<void> discard(String userId, String operationId) async {
    final operation = await _database.findPendingOperation(operationId);
    if (operation?.userId == userId) {
      await _database.removePendingOperation(operationId);
    }
  }

  Future<SyncReport> _performSynchronization(String userId) async {
    final operations = await _database.getPendingOperations(userId);
    var synced = 0;
    Map<String, int>? remoteProgress;

    for (final row in operations) {
      if (row.status == SyncOperationStatus.blocked.wireValue) continue;
      try {
        final kind = SyncOperationKind.fromWireValue(row.kind);
        final payload = _decodePayload(row.payloadJson);
        switch (kind) {
          case SyncOperationKind.studyProgress:
            remoteProgress ??= await _loadRemoteProgress();
            final localPercentage = _readPercentage(payload);
            final percentage =
                localPercentage > (remoteProgress[row.entityId] ?? 0)
                ? localPercentage
                : remoteProgress[row.entityId] ?? 0;
            await _dio.post<Map<String, dynamic>>(
              '/simulacros/progreso',
              data: {'subtemaId': row.entityId, 'porcentaje': percentage},
            );
            remoteProgress[row.entityId] = percentage;
          case SyncOperationKind.notebookEntry:
            await _dio.patch<Map<String, dynamic>>(
              '/cuaderno-errores/${Uri.encodeComponent(row.entityId)}',
              data: {
                'nota': payload['nota'] as String? ?? '',
                'estado': payload['estado'] as String,
              },
            );
        }
        await _database.removePendingOperation(row.id);
        synced++;
      } on DioException catch (error) {
        if (_shouldWaitForConnection(error)) break;
        await _markBlocked(row, _messageFrom(error));
      } on Object {
        await _markBlocked(
          row,
          'La operación guardada no tiene un formato válido.',
        );
      }
    }

    final remaining = await _database.getPendingOperations(userId);
    return SyncReport(
      synced: synced,
      pending: remaining
          .where((row) => row.status == SyncOperationStatus.pending.wireValue)
          .length,
      blocked: remaining
          .where((row) => row.status == SyncOperationStatus.blocked.wireValue)
          .length,
    );
  }

  Future<Map<String, int>> _loadRemoteProgress() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/simulacros/progreso',
    );
    final body = _body(response.data);
    final raw = body['porSubtema'];
    if (raw is! Map) return {};
    return raw.map(
      (key, value) => MapEntry(
        key.toString(),
        value is num ? value.toInt().clamp(0, 100) : 0,
      ),
    );
  }

  Future<void> _enqueueProgress({
    required String id,
    required String userId,
    required String subtopicId,
    required int percentage,
  }) async {
    await _database.transaction(() async {
      final existing = await _database.findPendingOperation(id);
      var resolvedPercentage = percentage;
      if (existing != null) {
        final previous = _readPercentage(_decodePayload(existing.payloadJson));
        if (previous > resolvedPercentage) resolvedPercentage = previous;
      }
      await _enqueue(
        id: id,
        userId: userId,
        kind: SyncOperationKind.studyProgress,
        entityId: subtopicId,
        payload: {'porcentaje': resolvedPercentage},
        existing: existing,
      );
    });
  }

  Future<void> _enqueue({
    required String id,
    required String userId,
    required SyncOperationKind kind,
    required String entityId,
    required Map<String, dynamic> payload,
    PendingOperation? existing,
  }) async {
    final now = DateTime.now().toUtc();
    final previous = existing ?? await _database.findPendingOperation(id);
    await _database.savePendingOperation(
      PendingOperationsCompanion.insert(
        id: id,
        userId: userId,
        kind: kind.wireValue,
        entityId: entityId,
        payloadJson: jsonEncode(payload),
        status: Value(SyncOperationStatus.pending.wireValue),
        attempts: const Value(0),
        lastError: const Value(null),
        createdAt: previous?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<SafeWriteResult> _resultFor(String operationId) async {
    final operation = await _database.findPendingOperation(operationId);
    if (operation == null) {
      return const SafeWriteResult(SafeWriteDisposition.synced);
    }
    if (operation.status == SyncOperationStatus.blocked.wireValue) {
      return SafeWriteResult(
        SafeWriteDisposition.blocked,
        message: operation.lastError,
      );
    }
    return const SafeWriteResult(SafeWriteDisposition.queued);
  }

  Future<void> _markBlocked(PendingOperation row, String message) =>
      _database.savePendingOperation(
        _companionFromRow(
          row,
          status: SyncOperationStatus.blocked,
          lastError: message,
          attempts: row.attempts + 1,
        ),
      );

  PendingOperationsCompanion _companionFromRow(
    PendingOperation row, {
    SyncOperationStatus? status,
    String? lastError,
    bool clearError = false,
    int? attempts,
  }) => PendingOperationsCompanion.insert(
    id: row.id,
    userId: row.userId,
    kind: row.kind,
    entityId: row.entityId,
    payloadJson: row.payloadJson,
    status: Value(status?.wireValue ?? row.status),
    attempts: Value(attempts ?? row.attempts),
    lastError: Value(clearError ? null : lastError ?? row.lastError),
    createdAt: row.createdAt,
    updatedAt: DateTime.now().toUtc(),
  );

  SyncOperation _fromRow(PendingOperation row) => SyncOperation(
    id: row.id,
    userId: row.userId,
    kind: SyncOperationKind.fromWireValue(row.kind),
    entityId: row.entityId,
    payload: _decodePayload(row.payloadJson),
    status: SyncOperationStatus.fromWireValue(row.status),
    attempts: row.attempts,
    lastError: row.lastError,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  Map<String, dynamic> _decodePayload(String value) =>
      Map<String, dynamic>.from(jsonDecode(value) as Map);

  int _readPercentage(Map<String, dynamic> payload) {
    final value = payload['porcentaje'];
    if (value is! num) throw const FormatException('Porcentaje inválido');
    return value.toInt().clamp(0, 100);
  }

  Map<String, dynamic> _body(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final data = body['data'];
    return data is Map<String, dynamic> ? data : body;
  }

  bool _shouldWaitForConnection(DioException error) {
    final status = error.response?.statusCode;
    if (status == 401 || status == 403) return true;
    if (status == 408 || status == 429 || (status != null && status >= 500)) {
      return true;
    }
    return error.response == null &&
        error.type != DioExceptionType.cancel &&
        error.type != DioExceptionType.badCertificate;
  }

  String _messageFrom(DioException error) {
    final body = error.response?.data;
    if (body is Map) {
      final message = body['message'] ?? body['mensaje'];
      if (message is String && message.isNotEmpty) return message;
      if (message is List && message.isNotEmpty) return message.join('\n');
    }
    return 'El servidor rechazó esta operación.';
  }

  String _operationId(String userId, SyncOperationKind kind, String entityId) =>
      '$userId::${kind.wireValue}::$entityId';
}

final safeSyncRepositoryProvider = Provider<SafeSyncRepository>(
  (ref) => DriftSafeSyncRepository(
    ref.watch(dioProvider),
    ref.watch(appDatabaseProvider),
  ),
);
