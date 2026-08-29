import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../academic/domain/academic_models.dart';
import '../domain/flashcard_models.dart';
import 'flashcard_providers.dart';

class FlashcardsPage extends ConsumerStatefulWidget {
  const FlashcardsPage({super.key});

  @override
  ConsumerState<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends ConsumerState<FlashcardsPage> {
  FlashcardKind? _kind;
  AcademicArea? _area;
  int _count = 10;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(flashcardCatalogProvider);
    final progress = ref.watch(flashcardProgressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _LoadError(onRetry: () => ref.invalidate(flashcardCatalogProvider)),
        data: (cards) => progress.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _LoadError(),
          data: (savedProgress) => _buildContent(cards, savedProgress),
        ),
      ),
    );
  }

  Widget _buildContent(
    List<Flashcard> cards,
    List<FlashcardProgress> savedProgress,
  ) {
    final filtered = cards
        .where((card) {
          if (_kind != null && card.kind != _kind) return false;
          if (_area != null && card.area != _area) return false;
          return true;
        })
        .toList(growable: false);
    final progressById = {for (final item in savedProgress) item.cardId: item};
    final mastered = filtered
        .where((card) => progressById[card.id]?.mastered ?? false)
        .length;
    final selectedCount = filtered.isEmpty
        ? 0
        : _count.clamp(1, filtered.length);

    return ListView(
      key: const Key('flashcards-setup-list'),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
      children: [
        Text(
          'Repasa con memoria activa',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'Intenta recordar la respuesta antes de girar cada tarjeta. Las que marques para repasar tendrán prioridad en la próxima sesión.',
        ),
        const SizedBox(height: 18),
        _ProgressCard(
          mastered: mastered,
          total: filtered.length,
          reviewed: filtered
              .where((card) => progressById.containsKey(card.id))
              .length,
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<FlashcardKind?>(
          key: const Key('flashcard-kind-filter'),
          initialValue: _kind,
          decoration: const InputDecoration(labelText: 'Tipo de tarjetas'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas')),
            for (final kind in FlashcardKind.values)
              DropdownMenuItem(value: kind, child: Text(kind.label)),
          ],
          onChanged: (value) => setState(() => _kind = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<AcademicArea?>(
          key: const Key('flashcard-area-filter'),
          initialValue: _area,
          decoration: const InputDecoration(labelText: 'Área ICFES'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Todas las áreas')),
            for (final area in AcademicArea.values)
              DropdownMenuItem(value: area, child: Text(area.label)),
          ],
          onChanged: (value) => setState(() => _area = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          key: const Key('flashcard-count-filter'),
          initialValue: _count,
          decoration: const InputDecoration(labelText: 'Tarjetas por sesión'),
          items: const [
            DropdownMenuItem(value: 5, child: Text('5 tarjetas')),
            DropdownMenuItem(value: 10, child: Text('10 tarjetas')),
            DropdownMenuItem(value: 20, child: Text('20 tarjetas')),
            DropdownMenuItem(value: 30, child: Text('30 tarjetas')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _count = value);
          },
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const Key('start-flashcard-session'),
          onPressed: filtered.isEmpty
              ? null
              : () => context.push(
                  FlashcardSessionConfig(
                    kind: _kind,
                    area: _area,
                    count: selectedCount,
                  ).location,
                ),
          icon: const Icon(Icons.style_rounded),
          label: Text('Estudiar $selectedCount tarjetas'),
        ),
        const SizedBox(height: 12),
        Text(
          'Las tarjetas provienen de la biblioteca académica incluida en la app y están disponibles sin conexión.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.mastered,
    required this.total,
    required this.reviewed,
  });

  final int mastered;
  final int total;
  final int reviewed;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : mastered / total;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_alt_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$mastered de $total dominadas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: value),
            const SizedBox(height: 8),
            Text('$reviewed tarjetas estudiadas al menos una vez'),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_outlined, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No pudimos preparar las flashcards.',
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ],
      ),
    ),
  );
}
