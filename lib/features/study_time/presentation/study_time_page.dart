import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/study_time_models.dart';
import 'study_time_providers.dart';

class StudyTimePage extends ConsumerWidget {
  const StudyTimePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(studyTimeSummaryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tiempo estudiado')),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _LoadError(onRetry: () => ref.invalidate(studyTimeRecordsProvider)),
        data: (value) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studyTimeRecordsProvider);
            await ref.read(studyTimeRecordsProvider.future);
          },
          child: ListView(
            key: const Key('study-time-list'),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _TotalCard(summary: value),
              const SizedBox(height: 16),
              Text(
                'Por actividad',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (final source in StudyTimeSource.values)
                Card(
                  child: ListTile(
                    key: Key('study-time-source-${source.name}'),
                    leading: CircleAvatar(child: Icon(_iconFor(source))),
                    title: Text(source.label),
                    trailing: Text(
                      formatStudyDuration(value.secondsBySource[source] ?? 0),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Se cuentan Pomodoros completados y tiempos de evaluaciones confirmadas en este dispositivo. Abrir una pantalla sin estudiar no suma tiempo.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.summary});

  final StudyTimeSummary summary;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule_rounded, size: 38),
          const SizedBox(height: 12),
          Text(
            formatStudyDuration(summary.totalSeconds),
            key: const Key('study-time-total'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Text('Tiempo total registrado'),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _TimeMetric(
                  label: 'Hoy',
                  value: formatStudyDuration(summary.todaySeconds),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeMetric(
                  label: 'Últimos 7 días',
                  value: formatStudyDuration(summary.lastSevenDaysSeconds),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${summary.sessionCount} actividades registradas'),
        ],
      ),
    ),
  );
}

class _TimeMetric extends StatelessWidget {
  const _TimeMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No pudimos cargar tu tiempo de estudio.'),
        const SizedBox(height: 12),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

IconData _iconFor(StudyTimeSource source) => switch (source) {
  StudyTimeSource.pomodoro => Icons.timer_outlined,
  StudyTimeSource.practice => Icons.quiz_outlined,
  StudyTimeSource.diagnostic => Icons.fact_check_outlined,
};
