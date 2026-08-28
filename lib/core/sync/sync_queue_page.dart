import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'safe_sync_models.dart';
import 'sync_providers.dart';

class SyncQueuePage extends ConsumerWidget {
  const SyncQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operations = ref.watch(syncOperationsProvider);
    final syncState = ref.watch(safeSyncControllerProvider);
    ref.listen(safeSyncControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && error != previous?.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronización'),
        actions: [
          IconButton(
            key: const Key('synchronize-now'),
            tooltip: 'Sincronizar ahora',
            onPressed: syncState.isSyncing
                ? null
                : ref.read(safeSyncControllerProvider.notifier).synchronize,
            icon: syncState.isSyncing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: operations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _QueueError(),
        data: (items) {
          final blocked = items
              .where((item) => item.status == SyncOperationStatus.blocked)
              .length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _SyncSummary(
                total: items.length,
                blocked: blocked,
                syncing: syncState.isSyncing,
              ),
              const SizedBox(height: 16),
              const Text(
                'Solo se aplazan cambios seguros. Las respuestas, calificaciones, XP y pagos siempre requieren conexión.',
              ),
              const SizedBox(height: 18),
              if (items.isEmpty)
                const _EmptyQueue()
              else
                for (final item in items) ...[
                  _OperationCard(
                    operation: item,
                    syncing: syncState.isSyncing,
                    onRetry: () => ref
                        .read(safeSyncControllerProvider.notifier)
                        .retry(item.id),
                    onDiscard: () => _confirmDiscard(context, ref, item),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDiscard(
    BuildContext context,
    WidgetRef ref,
    SyncOperation operation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar cambio'),
        content: const Text(
          'Este cambio local no se enviará al servidor. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(safeSyncControllerProvider.notifier).discard(operation.id);
    }
  }
}

class _SyncSummary extends StatelessWidget {
  const _SyncSummary({
    required this.total,
    required this.blocked,
    required this.syncing,
  });

  final int total;
  final int blocked;
  final bool syncing;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(
            blocked > 0
                ? Icons.sync_problem_rounded
                : Icons.cloud_done_outlined,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  syncing
                      ? 'Sincronizando cambios'
                      : total == 0
                      ? 'Todo está sincronizado'
                      : '$total cambios por enviar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (blocked > 0) Text('$blocked requieren que los revises.'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({
    required this.operation,
    required this.syncing,
    required this.onRetry,
    required this.onDiscard,
  });

  final SyncOperation operation;
  final bool syncing;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final blocked = operation.status == SyncOperationStatus.blocked;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(blocked ? Icons.warning_amber_rounded : Icons.schedule),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    operation.kind.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(blocked ? 'Revisar' : 'Pendiente'),
              ],
            ),
            const SizedBox(height: 8),
            Text(_operationDescription(operation)),
            if (operation.lastError case final error?) ...[
              const SizedBox(height: 6),
              Text(error, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: syncing ? null : onDiscard,
                  child: const Text('Descartar'),
                ),
                if (blocked)
                  FilledButton.tonal(
                    onPressed: syncing ? null : onRetry,
                    child: const Text('Reintentar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        children: [
          Icon(Icons.cloud_done_outlined, size: 54),
          SizedBox(height: 12),
          Text('No tienes cambios pendientes.'),
        ],
      ),
    ),
  );
}

class _QueueError extends StatelessWidget {
  const _QueueError();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Text('No pudimos consultar la cola de sincronización.'),
    ),
  );
}

String _operationDescription(
  SyncOperation operation,
) => switch (operation.kind) {
  SyncOperationKind.studyProgress =>
    'Lección ${operation.entityId}: ${operation.payload['porcentaje'] ?? 0}%',
  SyncOperationKind.notebookEntry =>
    'Pregunta ${operation.entityId}: ${operation.payload['estado'] ?? ''}',
};
