import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/historical_simulation_models.dart';
import 'historical_simulation_providers.dart';

class HistoricalSimulationsPage extends ConsumerStatefulWidget {
  const HistoricalSimulationsPage({super.key});

  @override
  ConsumerState<HistoricalSimulationsPage> createState() =>
      _HistoricalSimulationsPageState();
}

class _HistoricalSimulationsPageState
    extends ConsumerState<HistoricalSimulationsPage> {
  int? _year;
  HistoricalSimulationAvailability? _availability;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(historicalSimulationCatalogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Simulacros por año')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(historicalSimulationCatalogProvider.future),
        child: catalog.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CatalogError(
            onRetry: () => ref.invalidate(historicalSimulationCatalogProvider),
          ),
          data: _buildCatalog,
        ),
      ),
    );
  }

  Widget _buildCatalog(HistoricalSimulationCatalog catalog) {
    final filtered = catalog.editions
        .where((edition) {
          if (_year != null && edition.year != _year) return false;
          if (_availability != null && edition.availability != _availability) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    return ListView(
      key: const Key('historical-simulation-list'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text(
          'Banco con trazabilidad de derechos',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Cada edición debe indicar su fuente y autorización antes de habilitar preguntas. Los elementos bloqueados muestran únicamente metadatos.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                key: const Key('historical-year-filter'),
                initialValue: _year,
                decoration: const InputDecoration(labelText: 'Año'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  for (final year in catalog.years)
                    DropdownMenuItem(value: year, child: Text('$year')),
                ],
                onChanged: (value) => setState(() => _year = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<HistoricalSimulationAvailability?>(
                key: const Key('historical-status-filter'),
                initialValue: _availability,
                decoration: const InputDecoration(labelText: 'Estado'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  for (final status in HistoricalSimulationAvailability.values)
                    DropdownMenuItem(value: status, child: Text(status.label)),
                ],
                onChanged: (value) => setState(() => _availability = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (filtered.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No hay ediciones con estos filtros.'),
            ),
          )
        else
          for (final edition in filtered) ...[
            _EditionCard(
              edition: edition,
              onTap: () => context.push(
                '/student/practice/past/${Uri.encodeComponent(edition.id)}',
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _EditionCard extends StatelessWidget {
  const _EditionCard({required this.edition, required this.onTap});

  final HistoricalSimulationEdition edition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      key: Key('historical-edition-${edition.id}'),
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(child: Text('${edition.year}')),
      title: Text(edition.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text('${edition.provider}\n${edition.availability.label}'),
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    ),
  );
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Icon(Icons.cloud_off_outlined, size: 48),
      const SizedBox(height: 12),
      const Text(
        'No pudimos consultar el catálogo histórico.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 14),
      FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
    ],
  );
}
