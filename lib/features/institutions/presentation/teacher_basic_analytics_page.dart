import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../domain/teacher_basic_analytics_models.dart';
import 'teacher_basic_analytics_providers.dart';

class TeacherBasicAnalyticsPage extends ConsumerWidget {
  const TeacherBasicAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teacherBasicAnalyticsControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indicadores básicos'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: () => ref
                .read(teacherBasicAnalyticsControllerProvider.notifier)
                .reload(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AnalyticsError(
          message: _message(error),
          onRetry: () => ref
              .read(teacherBasicAnalyticsControllerProvider.notifier)
              .reload(),
        ),
        data: (analytics) => RefreshIndicator(
          onRefresh: () => ref
              .read(teacherBasicAnalyticsControllerProvider.notifier)
              .reload(),
          child: ListView(
            key: const Key('teacher-basic-analytics-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _AnalyticsHeader(analytics: analytics),
              const SizedBox(height: 14),
              _MetricsGrid(metrics: analytics.summary),
              const SizedBox(height: 14),
              _PlanCard(plan: analytics.plan),
              const SizedBox(height: 14),
              _PrivacyCard(description: analytics.privacyDescription),
              const SizedBox(height: 18),
              Text(
                analytics.scope == 'GRUPOS_ASIGNADOS'
                    ? 'Tus grupos asignados'
                    : 'Grupos de la institución',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (analytics.groups.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No hay grupos disponibles para calcular indicadores.',
                    ),
                  ),
                )
              else
                for (final group in analytics.groups) ...[
                  _GroupAnalyticsCard(group: group),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({required this.analytics});

  final TeacherBasicAnalytics analytics;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.analytics_outlined, size: 38),
          const SizedBox(height: 10),
          Text(
            'Actividad de los últimos ${analytics.periodDays} días',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Actualizado ${_dateTime(analytics.generatedAt)}. Los resultados muestran tendencias agregadas, no calificaciones oficiales.',
          ),
        ],
      ),
    ),
  );
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final BasicAnalyticsMetrics metrics;

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.28,
    children: [
      _MetricCard(
        icon: Icons.people_outline_rounded,
        value: '${metrics.totalStudents}',
        label: 'Estudiantes',
      ),
      _MetricCard(
        icon: Icons.bolt_outlined,
        value: '${metrics.activeStudents}',
        label: 'Con actividad',
      ),
      _MetricCard(
        icon: Icons.assignment_outlined,
        value: '${metrics.totalSimulations}',
        label: 'Simulacros',
      ),
      _MetricCard(
        icon: Icons.track_changes_outlined,
        value: _decimal(metrics.averageScore),
        label: 'Promedio / 100',
      ),
      _MetricCard(
        icon: Icons.menu_book_outlined,
        value: '${_decimal(metrics.averageProgress)}%',
        label: 'Avance promedio',
      ),
      _MetricCard(
        icon: Icons.schedule_outlined,
        value: metrics.lastActivity == null
            ? 'Sin datos'
            : _shortDate(metrics.lastActivity!),
        label: 'Última actividad',
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(height: 6),
          FittedBox(
            child: Text(value, style: Theme.of(context).textTheme.titleLarge),
          ),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final BasicAnalyticsPlan plan;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_outlined),
              const SizedBox(width: 8),
              Text(
                'Plan ${plan.name.toLowerCase()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${plan.groupLimit ?? 'Sin límite'} grupo(s) · ${plan.studentLimit ?? 'Sin límite'} estudiantes',
          ),
          const SizedBox(height: 4),
          Text(
            plan.advertisingEnabled
                ? 'Incluye publicidad moderada fuera de pantallas de concentración.'
                : 'Sin anuncios.',
          ),
        ],
      ),
    ),
  );
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.privacy_tip_outlined),
      title: const Text('Privacidad por diseño'),
      subtitle: Text(description),
    ),
  );
}

class _GroupAnalyticsCard extends StatelessWidget {
  const _GroupAnalyticsCard({required this.group});

  final BasicGroupAnalytics group;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('basic-analytics-group-${group.id}'),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.name, style: Theme.of(context).textTheme.titleLarge),
          Text(group.grade.label),
          const Divider(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('${group.totalStudents} estudiantes')),
              Chip(label: Text('${group.activeStudents} activos')),
              Chip(label: Text('${group.totalSimulations} simulacros')),
              Chip(label: Text('${_decimal(group.averageScore)} promedio')),
            ],
          ),
          const SizedBox(height: 12),
          Text('Avance promedio: ${_decimal(group.averageProgress)}%'),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (group.averageProgress / 100).clamp(0, 1),
          ),
        ],
      ),
    ),
  );
}

class _AnalyticsError extends StatelessWidget {
  const _AnalyticsError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.query_stats_outlined, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _decimal(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';

String _dateTime(DateTime value) =>
    '${_shortDate(value)}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _message(Object error) => switch (error) {
  ApiError() => error.message,
  FormatException() => error.message,
  StateError() => error.message,
  _ => 'No pudimos cargar los indicadores. Inténtalo nuevamente.',
};
