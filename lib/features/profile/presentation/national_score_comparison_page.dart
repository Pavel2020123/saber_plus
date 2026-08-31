import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/national_score_comparison.dart';
import '../domain/score_projection.dart';
import 'academic_profile_providers.dart';
import 'national_score_comparison_providers.dart';

class NationalScoreComparisonPage extends ConsumerStatefulWidget {
  const NationalScoreComparisonPage({super.key});

  @override
  ConsumerState<NationalScoreComparisonPage> createState() =>
      _NationalScoreComparisonPageState();
}

class _NationalScoreComparisonPageState
    extends ConsumerState<NationalScoreComparisonPage> {
  Saber11Calendar _calendar = Saber11Calendar.calendarA;

  @override
  Widget build(BuildContext context) {
    final references = ref.watch(nationalScoreReferencesProvider);
    final reference = references.firstWhere(
      (item) => item.calendar == _calendar,
      orElse: () => referenceForCalendar(_calendar),
    );
    final projection = ref.watch(scoreProjectionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referencia nacional'),
        actions: [
          IconButton(
            key: const Key('refresh-national-comparison'),
            tooltip: 'Actualizar estimación',
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        key: const Key('national-score-comparison-list'),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.public_rounded, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    'Pon tu avance en contexto',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Compara la estimación educativa de SaberPlus con el promedio global publicado por el ICFES para el calendario correspondiente.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Selecciona tu calendario',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final calendar in Saber11Calendar.values)
                ChoiceChip(
                  key: Key('national-calendar-${calendar.name}'),
                  label: Text(calendar.label),
                  selected: _calendar == calendar,
                  onSelected: (_) => setState(() => _calendar = calendar),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _NationalReferenceCard(reference: reference),
          const SizedBox(height: 14),
          projection.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, _) => _ProjectionError(onRetry: () => _refresh(ref)),
            data: (value) => value == null
                ? const _MissingProjection()
                : _ComparisonCard(projection: value, reference: reference),
          ),
          const SizedBox(height: 14),
          Card(
            key: const Key('national-comparison-method-notice'),
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Esta diferencia no es un percentil, puesto, resultado oficial ni garantía de admisión. La estimación usa tus actividades en SaberPlus y el promedio pertenece a la población definida metodológicamente por el ICFES.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('open-official-national-statistics'),
            onPressed: () => _openOfficial(reference.sourceUri),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Consultar estadísticas oficiales'),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(academicProfileProgressProvider);
    ref.invalidate(scoreProjectionProvider);
    try {
      await ref.read(scoreProjectionProvider.future);
    } on Object {
      // La sección de proyección conserva su estado de error.
    }
  }

  Future<void> _openOfficial(Uri uri) async {
    if (!isTrustedNationalStatisticsUri(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La fuente no es un sitio autorizado.')),
        );
      }
      return;
    }
    var opened = false;
    try {
      opened = await ref.read(nationalStatisticsLinkOpenerProvider)(uri);
    } on Object {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir la fuente oficial.')),
      );
    }
  }
}

class _NationalReferenceCard extends StatelessWidget {
  const _NationalReferenceCard({required this.reference});

  final NationalScoreReference reference;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('national-score-reference'),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promedio nacional ${reference.year}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(reference.calendar.label),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                reference.averageGlobalScore.toStringAsFixed(1),
                key: const Key('national-average-score'),
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const Padding(
                padding: EdgeInsets.only(left: 6, bottom: 5),
                child: Text('de 500'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Fuente: ICFES · Verificado ${_formatDate(reference.verifiedOn)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({required this.projection, required this.reference});

  final ScoreProjection projection;
  final NationalScoreReference reference;

  @override
  Widget build(BuildContext context) {
    final comparison = NationalScoreComparison(
      estimatedScore: projection.estimatedGlobalScore,
      reference: reference,
    );
    final difference = comparison.difference.abs().toStringAsFixed(1);
    final description = comparison.isAboveReference
        ? 'La estimación está $difference puntos por encima del referente.'
        : comparison.isBelowReference
        ? 'La estimación está $difference puntos por debajo del referente.'
        : 'La estimación coincide con el referente nacional.';
    return Card(
      key: const Key('national-score-comparison-result'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparación orientativa',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _ScoreBar(
              label: 'Estimación SaberPlus',
              value: projection.estimatedGlobalScore.toDouble(),
              valueLabel: '${projection.estimatedGlobalScore}',
            ),
            const SizedBox(height: 14),
            _ScoreBar(
              label: 'Promedio ${reference.calendar.label}',
              value: reference.averageGlobalScore,
              valueLabel: reference.averageGlobalScore.toStringAsFixed(1),
            ),
            const SizedBox(height: 14),
            Text(description, key: const Key('national-score-difference')),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.value,
    required this.valueLabel,
  });

  final String label;
  final double value;
  final String valueLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          Text(valueLabel),
        ],
      ),
      const SizedBox(height: 7),
      LinearProgressIndicator(
        value: (value / 500).clamp(0, 1),
        minHeight: 8,
        borderRadius: BorderRadius.circular(99),
      ),
    ],
  );
}

class _MissingProjection extends StatelessWidget {
  const _MissingProjection();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(18),
      child: Text(
        'Completa actividades en las cinco materias para comparar una estimación responsable.',
      ),
    ),
  );
}

class _ProjectionError extends StatelessWidget {
  const _ProjectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No pudimos actualizar tu estimación.'),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _formatDate(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  const months = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (month == null || month < 1 || month > 12 || day == null) return isoDate;
  return '$day ${months[month - 1]} ${parts[0]}';
}
