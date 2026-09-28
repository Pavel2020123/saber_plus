import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/app_database.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/deferred_review_repository.dart';
import '../domain/flashcard_models.dart';
import 'deferred_review_providers.dart';
import 'flashcard_providers.dart';

final reviewClockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

class DeferredReviewPage extends ConsumerStatefulWidget {
  const DeferredReviewPage({super.key});
  @override
  ConsumerState<DeferredReviewPage> createState() => _DeferredReviewPageState();
}

class _DeferredReviewPageState extends ConsumerState<DeferredReviewPage> {
  bool _busy = false;
  String? _message;
  String? _account;
  Future<void> _action(
    Future<void> Function(DeferredReviewRepository, String) action,
  ) async {
    final user = ref.read(sessionControllerProvider).user;
    if (_busy || user == null || user.isDemo) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final repo = await ref.read(deferredReviewRepositoryProvider.future);
      if (!mounted || ref.read(sessionControllerProvider).user?.id != user.id) {
        return;
      }
      await action(repo, user.id);
      if (mounted && ref.read(sessionControllerProvider).user?.id == user.id) {
        setState(
          () => _message =
              'Revisión terminada. Comprueba el estado de cada tarjeta; los envíos pendientes se conservan.',
        );
      }
    } on Object {
      if (mounted && ref.read(sessionControllerProvider).user?.id == user.id) {
        setState(
          () => _message =
              'No pudimos conectar o completar la operación. Los cambios locales se conservan; vuelve a intentarlo.',
        );
      }
    } finally {
      if (mounted && ref.read(sessionControllerProvider).user?.id == user.id) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _discard(DeferredReviewEntry row) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar respuesta bloqueada'),
        content: const Text(
          'No se reenviará esta respuesta. En un conflicto recuperaremos primero la agenda del servidor. Esta acción no borra tu progreso de estudio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (accepted == true &&
        mounted &&
        ref.read(sessionControllerProvider).user?.id == row.userId) {
      await _action((repo, id) => repo.discardBlocked(id, row.cardId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).user;
    if (user != null && !user.isDemo) {
      ref.watch(deferredReviewRepositoryProvider);
    }
    if (_account != user?.id) {
      _account = user?.id;
      _busy = false;
      _message = null;
    }
    final now = ref.watch(reviewClockProvider).valueOrNull ?? DateTime.now();
    final cards = ref.watch(flashcardCatalogProvider);
    final rows = ref.watch(deferredReviewRowsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de repasos')),
      body: user == null || user.isDemo
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'La agenda sincronizada requiere una cuenta real. En la demo puedes continuar con la práctica libre; no se enviarán datos.',
                ),
              ),
            )
          : cards.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(flashcardCatalogProvider),
                  child: const Text('Reintentar catálogo'),
                ),
              ),
              data: (catalog) => rows.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(deferredReviewRowsProvider),
                    child: const Text('Reintentar agenda local'),
                  ),
                ),
                data: (entries) => _content(
                  catalog,
                  entries.where((r) => r.userId == user.id).toList(),
                  now,
                ),
              ),
            ),
    );
  }

  Widget _content(
    List<Flashcard> catalog,
    List<DeferredReviewEntry> entries,
    DateTime now,
  ) {
    final byId = {for (final c in catalog) c.id: c};
    final saved = {for (final r in entries) r.cardId: r};
    final due = <Widget>[],
        next = <Widget>[],
        pending = <Widget>[],
        fresh = <Widget>[];
    for (final card in catalog) {
      final row = saved[card.id];
      if (row?.pendingJson != null || (row != null && row.status != 'synced')) {
        final label = switch (row!.status) {
          'conflict' => 'Conflicto: requiere revisión',
          'retired' => 'Tarjeta retirada',
          'invalid' => 'Respuesta rechazada',
          _ => 'Pendiente de sincronizar · fecha sin confirmar',
        };
        pending.add(
          ListTile(
            title: Text(card.front),
            subtitle: Text(label),
            trailing:
                ['conflict', 'retired', 'invalid'].contains(row.status) &&
                    row.pendingJson != null
                ? IconButton(
                    tooltip: 'Revisar respuesta bloqueada',
                    onPressed: _busy ? null : () => _discard(row),
                    icon: const Icon(Icons.info_outline),
                  )
                : null,
          ),
        );
        continue;
      }
      if (row?.confirmedJson == null) {
        fresh.add(_card(card, 'Nueva · programa el primer repaso', true));
        continue;
      }
      try {
        final review = parseReview(
          jsonDecode(row!.confirmedJson!),
          row.userId,
          byId.keys.toSet(),
        );
        final date = review.dueAt.toLocal();
        final label =
            '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        (review.isDue(now) ? due : next).add(
          _card(
            card,
            review.isDue(now) ? 'Pendiente desde $label' : 'Próximo: $label',
            review.isDue(now),
          ),
        );
      } on Object {
        pending.add(
          ListTile(
            title: Text(card.front),
            subtitle: const Text(
              'No se pudo leer esta agenda. Intenta sincronizar.',
            ),
          ),
        );
      }
    }
    // Preserve visibility of blocked events whose content was removed locally.
    for (final row in entries.where(
      (r) => !byId.containsKey(r.cardId) && r.pendingJson != null,
    )) {
      pending.add(
        ListTile(
          title: const Text('Tarjeta no disponible'),
          subtitle: Text(row.status),
          trailing: ['conflict', 'retired', 'invalid'].contains(row.status)
              ? IconButton(
                  tooltip: 'Revisar respuesta bloqueada',
                  onPressed: _busy ? null : () => _discard(row),
                  icon: const Icon(Icons.info_outline),
                )
              : null,
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Autoevaluación, no dominio acreditado. Intervalos: 1, 3, 7, 14 y 30 días. La práctica libre no modifica esta agenda.',
        ),
        const Text(
          'Sin conexión se conserva una previsión. El servidor confirma la fecha al recibir el repaso; las horas se muestran según tu dispositivo.',
        ),
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _action((repo, id) => repo.synchronize(id)),
          icon: const Icon(Icons.sync),
          label: Text(_busy ? 'Sincronizando…' : 'Sincronizar agenda'),
        ),
        if (_message != null)
          Text(_message!, key: const Key('review-sync-message')),
        Text(
          'Pendientes (${due.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (due.isEmpty)
          const Text(
            'No hay repasos vencidos en la agenda local. Sincroniza para consultar otros dispositivos.',
          ),
        ...due,
        ExpansionTile(title: Text('Próximos (${next.length})'), children: next),
        ExpansionTile(
          initiallyExpanded: true,
          title: Text('Sin confirmar o bloqueados (${pending.length})'),
          children: pending,
        ),
        ExpansionTile(
          title: Text('Añadir tarjetas (${fresh.length})'),
          children: fresh,
        ),
        const Divider(),
        const Text(
          'Otros repasos existentes · no cambian los intervalos de las flashcards',
        ),
        TextButton(
          onPressed: () => context.push('/student/practice/daily-review'),
          child: const Text('Repasar errores de hoy'),
        ),
        TextButton(
          onPressed: () => context.push('/student/progress'),
          child: const Text('Abrir cuaderno de errores'),
        ),
      ],
    );
  }

  Widget _card(Flashcard card, String label, bool enabled) => ListTile(
    title: Text(card.front),
    subtitle: Text(label),
    trailing: enabled ? const Icon(Icons.chevron_right) : null,
    onTap: enabled && !_busy
        ? () => context.push(
            FlashcardSessionConfig(reviewCardId: card.id, count: 1).location,
          )
        : null,
  );
}
