import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../practice/domain/practice_models.dart';
import '../domain/historical_simulation_models.dart';
import 'historical_simulation_providers.dart';

class HistoricalSimulationDetailPage extends ConsumerWidget {
  const HistoricalSimulationDetailPage({super.key, required this.editionId});

  final String editionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(historicalSimulationCatalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la edición')),
      body: catalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text('No pudimos consultar esta edición.')),
        data: (value) {
          final edition = value.editions
              .where((item) => item.id == editionId)
              .firstOrNull;
          if (edition == null) {
            return const Center(child: Text('La edición no existe.'));
          }
          return _EditionDetail(edition: edition);
        },
      ),
    );
  }
}

class _EditionDetail extends StatelessWidget {
  const _EditionDetail({required this.edition});

  final HistoricalSimulationEdition edition;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
    children: [
      Text(edition.title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      Text('${edition.year} · ${edition.availability.label}'),
      const SizedBox(height: 16),
      Text(edition.description),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fuente y derechos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text('Proveedor: ${edition.provider}'),
              if (edition.rights case final rights?) ...[
                Text('Tipo: ${rights.type.label}'),
                Text('Titular: ${rights.holder}'),
                Text('Referencia: ${rights.reference}'),
              ] else
                const Text('No hay una autorización registrada.'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (edition.canStart) ...[
        Text('Jornadas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final block in OfficialSimulationBlock.values) ...[
          Card(
            child: ListTile(
              key: Key('start-historical-${block.slug}'),
              leading: const CircleAvatar(
                child: Icon(Icons.assignment_outlined),
              ),
              title: Text(block.label),
              subtitle: const Text('75 preguntas protegidas'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(
                '/student/practice/past/${Uri.encodeComponent(edition.id)}/${block.slug}',
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ] else
        const Card(
          key: Key('historical-edition-locked'),
          child: ListTile(
            leading: Icon(Icons.lock_outline_rounded),
            title: Text('Contenido todavía no disponible'),
            subtitle: Text(
              'Se habilitará únicamente después de verificar la fuente, los derechos y las 150 preguntas.',
            ),
          ),
        ),
    ],
  );
}
