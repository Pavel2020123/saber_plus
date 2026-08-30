import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/practice_history_models.dart';
import '../domain/simulation_comparison.dart';
import 'practice_providers.dart';

class SimulationComparisonPage extends ConsumerStatefulWidget {
  const SimulationComparisonPage({super.key});

  @override
  ConsumerState<SimulationComparisonPage> createState() =>
      _SimulationComparisonPageState();
}

class _SimulationComparisonPageState
    extends ConsumerState<SimulationComparisonPage> {
  late Future<SimulationHistory> _history;
  AcademicArea? _area;
  String? _previousId;
  String? _currentId;

  @override
  void initState() {
    super.initState();
    _history = _load();
  }

  Future<SimulationHistory> _load() =>
      ref.read(practiceRepositoryProvider).loadSimulationHistory();

  Future<void> _refresh() async {
    setState(() => _history = _load());
    await _history;
  }

  void _selectArea(AcademicArea? area) {
    if (area == null) return;
    setState(() {
      _area = area;
      _previousId = null;
      _currentId = null;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Comparar simulacros')),
    body: RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<SimulationHistory>(
        future: _history,
        builder: (context, snapshot) => switch (snapshot) {
          AsyncSnapshot(hasData: true, data: final history?) =>
            _ComparisonContent(
              history: history,
              selectedArea: _area,
              previousId: _previousId,
              currentId: _currentId,
              onAreaChanged: _selectArea,
              onPreviousChanged: (value) => setState(() => _previousId = value),
              onCurrentChanged: (value) => setState(() => _currentId = value),
            ),
          AsyncSnapshot(hasError: true, error: final error?) =>
            _ComparisonError(
              message: _messageFor(error),
              onRetry: () => setState(() => _history = _load()),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    ),
  );
}

class _ComparisonContent extends StatelessWidget {
  const _ComparisonContent({
    required this.history,
    required this.selectedArea,
    required this.previousId,
    required this.currentId,
    required this.onAreaChanged,
    required this.onPreviousChanged,
    required this.onCurrentChanged,
  });

  final SimulationHistory history;
  final AcademicArea? selectedArea;
  final String? previousId;
  final String? currentId;
  final ValueChanged<AcademicArea?> onAreaChanged;
  final ValueChanged<String?> onPreviousChanged;
  final ValueChanged<String?> onCurrentChanged;

  @override
  Widget build(BuildContext context) {
    final areas = comparableSimulationAreas(history);
    if (areas.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(28),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.compare_arrows_rounded, size: 64),
          SizedBox(height: 16),
          Text(
            'Necesitas dos simulacros de la misma materia',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Completa otro simulacro por área para medir tu evolución.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    final area = areas.contains(selectedArea) ? selectedArea! : areas.first;
    final trend = SimulationAreaTrend.fromHistory(history, area);
    final results = trend.results;
    final defaultCurrent = results.last;
    final selectedCurrent = _byId(results, currentId) ?? defaultCurrent;
    final defaultPrevious = results[results.length - 2];
    var selectedPrevious = _byId(results, previousId) ?? defaultPrevious;
    if (selectedPrevious.id == selectedCurrent.id) {
      selectedPrevious = results.firstWhere(
        (item) => item.id != selectedCurrent.id,
      );
    }
    final comparison = SimulationComparison.between(
      selectedPrevious,
      selectedCurrent,
    )!;

    return ListView(
      key: const Key('simulation-comparison-list'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Text(
          'Mide tu evolución',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Compara dos resultados oficiales de la misma materia. Los porcentajes provienen del backend y la app solo muestra sus diferencias.',
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<AcademicArea>(
          key: const Key('comparison-area-filter'),
          initialValue: area,
          decoration: const InputDecoration(labelText: 'Materia'),
          items: [
            for (final item in areas)
              DropdownMenuItem(value: item, child: Text(item.label)),
          ],
          onChanged: onAreaChanged,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: const Key('comparison-previous-result'),
          initialValue: selectedPrevious.id,
          decoration: const InputDecoration(labelText: 'Resultado anterior'),
          items: [
            for (final item in results.where(
              (item) => item.id != selectedCurrent.id,
            ))
              DropdownMenuItem(value: item.id, child: Text(_resultLabel(item))),
          ],
          onChanged: onPreviousChanged,
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: const Key('comparison-current-result'),
          initialValue: selectedCurrent.id,
          decoration: const InputDecoration(labelText: 'Resultado reciente'),
          items: [
            for (final item in results.where(
              (item) => item.id != selectedPrevious.id,
            ))
              DropdownMenuItem(value: item.id, child: Text(_resultLabel(item))),
          ],
          onChanged: onCurrentChanged,
        ),
        const SizedBox(height: 20),
        _ComparisonSummary(comparison: comparison),
        const SizedBox(height: 22),
        Text(
          'Evolución en la materia',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _TrendCard(trend: trend),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Comparación justa'),
            subtitle: Text(
              'Si cambia la cantidad de preguntas, prioriza el porcentaje. El número de respuestas correctas se muestra solo como contexto.',
            ),
          ),
        ),
      ],
    );
  }
}

class _ComparisonSummary extends StatelessWidget {
  const _ComparisonSummary({required this.comparison});

  final SimulationComparison comparison;

  @override
  Widget build(BuildContext context) {
    final direction = comparison.direction;
    final color = switch (direction) {
      SimulationTrendDirection.improved => Colors.green.shade700,
      SimulationTrendDirection.stable => Colors.blueGrey.shade700,
      SimulationTrendDirection.declined => Theme.of(context).colorScheme.error,
    };
    final icon = switch (direction) {
      SimulationTrendDirection.improved => Icons.trending_up_rounded,
      SimulationTrendDirection.stable => Icons.trending_flat_rounded,
      SimulationTrendDirection.declined => Icons.trending_down_rounded,
    };
    final title = switch (direction) {
      SimulationTrendDirection.improved => 'Mejora clara',
      SimulationTrendDirection.stable => 'Rendimiento estable',
      SimulationTrendDirection.declined => 'Oportunidad de refuerzo',
    };
    final delta = comparison.percentageDelta;
    final deltaLabel =
        '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} puntos';

    return Card(
      key: const Key('simulation-comparison-summary'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  deltaLabel,
                  key: const Key('simulation-comparison-delta'),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _ResultMetric(
                    label: 'Anterior',
                    result: comparison.previous,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.arrow_forward_rounded),
                ),
                Expanded(
                  child: _ResultMetric(
                    label: 'Reciente',
                    result: comparison.current,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.label, required this.result});

  final String label;
  final SimulationHistoryResult result;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      Text(
        '${result.percentage.toStringAsFixed(1)}%',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text('${result.correctAnswers}/${result.totalQuestions} correctas'),
      Text(_date(result.completedAt)),
    ],
  );
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend});

  final SimulationAreaTrend trend;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          for (final result in trend.results) ...[
            Row(
              children: [
                SizedBox(
                  width: 74,
                  child: Text(_shortDate(result.completedAt)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 12,
                      value: (result.percentage / 100).clamp(0, 1),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${result.percentage.round()}%',
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            if (result != trend.results.last) const SizedBox(height: 12),
          ],
        ],
      ),
    ),
  );
}

class _ComparisonError extends StatelessWidget {
  const _ComparisonError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(28),
    children: [
      const SizedBox(height: 100),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 16),
      Center(
        child: FilledButton.tonal(
          onPressed: onRetry,
          child: const Text('Reintentar'),
        ),
      ),
    ],
  );
}

SimulationHistoryResult? _byId(
  List<SimulationHistoryResult> results,
  String? id,
) {
  if (id == null) return null;
  for (final result in results) {
    if (result.id == id) return result;
  }
  return null;
}

String _resultLabel(SimulationHistoryResult result) =>
    '${_date(result.completedAt)} · ${result.percentage.round()}%';

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';

String _messageFor(Object error) => error is ApiError
    ? error.message
    : 'No pudimos cargar los simulacros. Intenta nuevamente.';
