enum SyncOperationKind {
  studyProgress('study_progress', 'Progreso de lección'),
  notebookEntry('notebook_entry', 'Cambio del cuaderno');

  const SyncOperationKind(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static SyncOperationKind fromWireValue(String value) => values.firstWhere(
    (kind) => kind.wireValue == value,
    orElse: () => throw FormatException('Operación desconocida: $value'),
  );
}

enum SyncOperationStatus {
  pending('pending'),
  blocked('blocked');

  const SyncOperationStatus(this.wireValue);

  final String wireValue;

  static SyncOperationStatus fromWireValue(String value) => values.firstWhere(
    (status) => status.wireValue == value,
    orElse: () => SyncOperationStatus.blocked,
  );
}

class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.userId,
    required this.kind,
    required this.entityId,
    required this.payload,
    required this.status,
    required this.attempts,
    required this.createdAt,
    required this.updatedAt,
    this.lastError,
  });

  final String id;
  final String userId;
  final SyncOperationKind kind;
  final String entityId;
  final Map<String, dynamic> payload;
  final SyncOperationStatus status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum SafeWriteDisposition { synced, queued, blocked }

class SafeWriteResult {
  const SafeWriteResult(this.disposition, {this.message});

  final SafeWriteDisposition disposition;
  final String? message;

  bool get isSynced => disposition == SafeWriteDisposition.synced;
}

class SyncReport {
  const SyncReport({
    required this.synced,
    required this.pending,
    required this.blocked,
  });

  final int synced;
  final int pending;
  final int blocked;
}
