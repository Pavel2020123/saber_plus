import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../academic/presentation/academic_home_controller.dart';
import '../../gamification/presentation/gamification_providers.dart';
import '../../study_time/domain/study_time_models.dart';
import '../../study_time/presentation/study_time_providers.dart';
import '../domain/academic_activity_report.dart';
import 'academic_profile_providers.dart';

class AcademicActivityReportPage extends ConsumerWidget {
  const AcademicActivityReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(academicActivityReportProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de actividad'),
        actions: [
          IconButton(
            key: const Key('refresh-academic-activity'),
            tooltip: 'Actualizar resumen',
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: report.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _LoadError(onRetry: () => _refresh(ref)),
        data: (data) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: ListView(
            key: const Key('academic-activity-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
            children: [
              Text(
                'Esta semana',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(_periodLabel(data.week)),
              const SizedBox(height: 16),
              _WeeklyMetrics(report: data),
              if (data.weeklyTargetProgress case final progress?) ...[
                const SizedBox(height: 14),
                _WeeklyTargetCard(report: data, progress: progress),
              ],
              const SizedBox(height: 20),
              _DailyActivityCard(report: data),
              const SizedBox(height: 24),
              Text(
                'Comparativo mensual',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              const Text(
                'Compara el mes calendario actual con el inmediatamente anterior.',
              ),
              const SizedBox(height: 12),
              _MonthlyComparisonCard(report: data),
              const SizedBox(height: 14),
              _DataSourceNotice(actionsAvailable: data.actionsAvailable),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(studyTimeRecordsProvider);
    ref.invalidate(gamificationSummaryProvider);
    await ref.read(academicHomeControllerProvider.notifier).reload();
    ref.invalidate(academicActivityReportProvider);
    try {
      await ref.read(academicActivityReportProvider.future);
    } on Object {
      // La pantalla representa el error y conserva una acción de reintento.
    }
  }
}

class _WeeklyMetrics extends StatelessWidget {
  const _WeeklyMetrics({required this.report});

  final AcademicActivityReport report;

  @override
  Widget build(BuildContext context) => GridView.count(
    key: const Key('weekly-activity-summary'),
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.45,
    children: [
      _SummaryMetric(
        icon: Icons.timer_outlined,
        value: formatStudyDuration(report.week.studySeconds),
        label: 'Tiempo estudiado',
      ),
      _SummaryMetric(
        icon: Icons.play_circle_outline_rounded,
        value: '${report.week.sessions}',
        label: 'Sesiones',
      ),
      _SummaryMetric(
        icon: Icons.calendar_today_outlined,
        value: '${report.week.activeDays}',
        label: 'Días activos',
      ),
      _SummaryMetric(
        icon: Icons.auto_graph_rounded,
        value: report.actionsAvailable ? '${report.week.actions}' : '—',
        label: 'Acciones académicas',
      ),
    ],
  );
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  );
}

class _WeeklyTargetCard extends StatelessWidget {
  const _WeeklyTargetCard({required this.report, required this.progress});

  final AcademicActivityReport report;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final targetMinutes = report.weeklyTargetMinutes!;
    final studiedMinutes = report.week.studySeconds ~/ 60;
    return Card(
      key: const Key('weekly-target-progress'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Meta semanal del plan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${(progress * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 8),
            Text('$studiedMinutes de $targetMinutes minutos registrados'),
          ],
        ),
      ),
    );
  }
}

class _DailyActivityCard extends StatelessWidget {
  const _DailyActivityCard({required this.report});

  final AcademicActivityReport report;

  @override
  Widget build(BuildContext context) {
    final maxSeconds = report.weekDays.fold<int>(
      0,
      (maximum, day) => day.studySeconds > maximum ? day.studySeconds : maximum,
    );
    return Card(
      key: const Key('weekly-daily-activity'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividad día por día',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 14),
            for (final day in report.weekDays)
              Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text(
                        _weekday(day.date),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: maxSeconds == 0
                            ? 0
                            : day.studySeconds / maxSeconds,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 58,
                      child: Text(
                        day.studySeconds == 0
                            ? '0 min'
                            : formatStudyDuration(day.studySeconds),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            if (report.actionsAvailable)
              Text(
                '${report.week.actions} acciones académicas confirmadas durante la semana.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyComparisonCard extends StatelessWidget {
  const _MonthlyComparisonCard({required this.report});

  final AcademicActivityReport report;

  @override
  Widget build(BuildContext context) {
    final current = report.currentMonth;
    final previous = report.previousMonth;
    final hasPreviousData = previous.studySeconds > 0 || previous.sessions > 0;

    return Card(
      key: const Key('monthly-activity-comparison'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: SizedBox()),
                Expanded(
                  child: Text(
                    _month(current.start),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  child: Text(
                    _month(previous.start),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            _ComparisonRow(
              label: 'Estudio',
              current: formatStudyDuration(current.studySeconds),
              previous: formatStudyDuration(previous.studySeconds),
            ),
            _ComparisonRow(
              label: 'Sesiones',
              current: '${current.sessions}',
              previous: '${previous.sessions}',
            ),
            _ComparisonRow(
              label: 'Días activos',
              current: '${current.activeDays}',
              previous: '${previous.activeDays}',
            ),
            const Divider(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                hasPreviousData
                    ? _monthlyDifference(report)
                    : 'Aún no hay una base del mes anterior para medir el cambio.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.previous,
  });

  final String label;
  final String current;
  final String previous;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Expanded(child: Text(current, textAlign: TextAlign.center)),
        Expanded(child: Text(previous, textAlign: TextAlign.center)),
      ],
    ),
  );
}

class _DataSourceNotice extends StatelessWidget {
  const _DataSourceNotice({required this.actionsAvailable});

  final bool actionsAvailable;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              actionsAvailable
                  ? 'El tiempo procede de actividades registradas en este dispositivo. Las acciones académicas son confirmadas por el servidor.'
                  : 'El tiempo local sigue disponible. Las acciones académicas no pudieron actualizarse desde el servidor.',
            ),
          ),
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
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: 12),
          const Text(
            'No pudimos preparar el resumen de actividad.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

String _periodLabel(AcademicPeriodSummary period) {
  final end = period.endExclusive.subtract(const Duration(days: 1));
  return '${period.start.day}–${end.day} ${_monthShort(end)}';
}

String _monthlyDifference(AcademicActivityReport report) {
  final difference = report.studySecondsDifference;
  if (difference == 0) {
    return 'Mantienes el mismo tiempo de estudio del mes anterior.';
  }
  final direction = difference > 0 ? 'más' : 'menos';
  return 'Llevas ${formatStudyDuration(difference.abs())} $direction de estudio que el mes anterior.';
}

String _weekday(DateTime date) =>
    const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][date.weekday - 1];

String _month(DateTime date) => const [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
][date.month - 1];

String _monthShort(DateTime date) => const [
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
][date.month - 1];
