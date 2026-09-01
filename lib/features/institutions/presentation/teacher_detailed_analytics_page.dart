import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/network/api_error.dart';
import '../domain/teacher_detailed_analytics_models.dart';
import '../domain/teacher_detailed_analytics_repository.dart';
import 'teacher_detailed_analytics_providers.dart';

class TeacherDetailedAnalyticsPage extends ConsumerStatefulWidget {
  const TeacherDetailedAnalyticsPage({super.key});

  @override
  ConsumerState<TeacherDetailedAnalyticsPage> createState() =>
      _TeacherDetailedAnalyticsPageState();
}

class _TeacherDetailedAnalyticsPageState
    extends ConsumerState<TeacherDetailedAnalyticsPage> {
  var _exporting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teacherDetailedAnalyticsControllerProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analítica detallada'),
          actions: [
            PopupMenuButton<InstitutionReportFormat>(
              key: const Key('institution-report-menu'),
              tooltip: 'Exportar reporte',
              enabled: !_exporting,
              onSelected: _export,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: InstitutionReportFormat.csv,
                  child: ListTile(
                    leading: Icon(Icons.table_view_outlined),
                    title: Text('Exportar CSV'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: InstitutionReportFormat.pdf,
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf_outlined),
                    title: Text('Exportar PDF'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            IconButton(
              tooltip: 'Actualizar',
              onPressed: _exporting
                  ? null
                  : () => ref
                        .read(
                          teacherDetailedAnalyticsControllerProvider.notifier,
                        )
                        .reload(),
              icon: _exporting
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.query_stats_rounded), text: 'Resumen'),
              Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Alertas'),
              Tab(
                icon: Icon(Icons.people_outline_rounded),
                text: 'Estudiantes',
              ),
            ],
          ),
        ),
        body: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _LoadError(
            message: _message(error),
            onRetry: () => ref
                .read(teacherDetailedAnalyticsControllerProvider.notifier)
                .reload(),
          ),
          data: (dashboard) => TabBarView(
            children: [
              _SummaryTab(analytics: dashboard.analytics),
              _AlertsTab(report: dashboard.risks),
              _StudentsTab(students: dashboard.analytics.students),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _export(InstitutionReportFormat format) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          format == InstitutionReportFormat.csv
              ? 'Exportar archivo CSV'
              : 'Exportar reporte PDF',
        ),
        content: const Text(
          'El archivo contiene nombres, correos y resultados académicos. Guárdalo solamente en un dispositivo autorizado y no lo compartas por canales inseguros.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm-institution-report'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _exporting = true);
    try {
      final report = await ref
          .read(teacherDetailedAnalyticsRepositoryProvider)
          .downloadReport(format);
      await OpenFilex.open(report.path);
      if (mounted) _snack('Reporte guardado como ${report.fileName}.');
    } on Object catch (error) {
      if (mounted) _snack(_message(error));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.analytics});

  final TeacherDetailedAnalytics analytics;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('teacher-detailed-summary'),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
    children: [
      Card(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.workspace_premium_outlined, size: 36),
              const SizedBox(height: 10),
              Text(
                'Plan sin anuncios',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${analytics.groupLimit ?? '—'} grupos · ${analytics.studentLimit ?? '—'} estudiantes · analítica detallada',
              ),
              if (analytics.expiresAt case final expiration?) ...[
                const SizedBox(height: 4),
                Text('Vigente hasta ${_date(expiration)}.'),
              ],
              const SizedBox(height: 6),
              Text(
                analytics.scope == 'GRUPOS_ASIGNADOS'
                    ? 'Solo se incluyen tus grupos asignados.'
                    : 'Se incluyen todos los grupos de la institución.',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.25,
        children: [
          _Metric(
            icon: Icons.people_outline_rounded,
            value: '${analytics.summary.totalStudents}',
            label: 'Estudiantes',
          ),
          _Metric(
            icon: Icons.assignment_outlined,
            value: '${analytics.summary.totalSimulations}',
            label: 'Simulacros',
          ),
          _Metric(
            icon: Icons.track_changes_outlined,
            value: _decimal(analytics.summary.averageScore),
            label: 'Promedio / 100',
          ),
          _Metric(
            icon: Icons.support_outlined,
            value: '${analytics.summary.studentsNeedingSupport}',
            label: 'Por reforzar',
          ),
        ],
      ),
      const SizedBox(height: 18),
      Text('Áreas prioritarias', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      if (analytics.priorities.isEmpty)
        const Card(
          child: ListTile(
            leading: Icon(Icons.hourglass_empty_rounded),
            title: Text('Aún no hay evidencia suficiente'),
            subtitle: Text(
              'Las prioridades aparecerán al registrar diagnósticos o simulacros.',
            ),
          ),
        )
      else
        for (final priority in analytics.priorities)
          Card(
            key: Key('institution-priority-${priority.area}'),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.flag_outlined)),
              title: Text(priority.areaLabel),
              subtitle: Text(
                '${priority.students} estudiante(s) la tienen como prioridad',
              ),
              trailing: Text(
                priority.average == null
                    ? 'Sin promedio'
                    : _decimal(priority.average!),
              ),
            ),
          ),
      const SizedBox(height: 12),
      Text(
        'Actualizado ${_dateTime(analytics.generatedAt)}. Estos indicadores orientan el acompañamiento y no sustituyen los resultados oficiales del ICFES.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _AlertsTab extends StatelessWidget {
  const _AlertsTab({required this.report});

  final TeacherRiskReport report;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('teacher-risk-alerts'),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Chip(label: Text('${report.summary.atRisk} en riesgo')),
          Chip(label: Text('${report.summary.critical} críticas')),
          Chip(label: Text('${report.summary.high} altas')),
          Chip(label: Text('${report.summary.attention} en atención')),
        ],
      ),
      const SizedBox(height: 12),
      if (report.alerts.isEmpty)
        const Card(
          child: ListTile(
            leading: Icon(Icons.check_circle_outline_rounded),
            title: Text('No hay alertas activas'),
            subtitle: Text(
              'El sistema continuará revisando actividad y rendimiento.',
            ),
          ),
        )
      else
        for (final alert in report.alerts)
          Card(
            key: Key('risk-alert-${alert.studentId}'),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _riskColor(context, alert.level),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              title: Text(alert.name),
              subtitle: Text(
                '${_riskLabel(alert.level)} · ${alert.groups.join(', ')}',
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.email),
                const SizedBox(height: 4),
                Text('${alert.daysInactive} día(s) sin actividad.'),
                if (alert.priorityAreaLabel case final area?)
                  Text('Prioridad sugerida: $area.'),
                const Divider(height: 20),
                for (final reason in alert.reasons) ...[
                  Text(
                    reason.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(reason.detail),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
      const SizedBox(height: 10),
      const Text(
        'Las alertas son orientativas. Antes de tomar decisiones, revisa el contexto del estudiante y confirma la información.',
      ),
    ],
  );
}

class _StudentsTab extends StatelessWidget {
  const _StudentsTab({required this.students});

  final List<DetailedStudentAnalytics> students;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('teacher-detailed-students'),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
    children: [
      for (final student in students)
        Card(
          key: Key('detailed-student-${student.id}'),
          child: ExpansionTile(
            leading: CircleAvatar(
              child: Text(
                student.name.isEmpty ? '?' : student.name[0].toUpperCase(),
              ),
            ),
            title: Text(student.name),
            subtitle: Text(
              '${student.groups.join(', ')} · promedio ${_decimal(student.averageScore)}',
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.email),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('${student.totalSimulations} simulacros')),
                  Chip(label: Text('${student.xp} XP')),
                  Chip(label: Text('${_decimal(student.progress)}% avance')),
                  Chip(label: Text(_academicLabel(student.academicStatus))),
                ],
              ),
              if (student.priorityAreaLabel case final priority?) ...[
                const SizedBox(height: 10),
                Text('Prioridad sugerida: $priority'),
              ],
              if (student.areas.isNotEmpty) ...[
                const Divider(height: 22),
                for (final area in student.areas)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(area.areaLabel)),
                        Text(
                          '${_decimal(area.average)} · ${area.attempts} intento(s)',
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      if (students.isEmpty)
        const Card(
          child: ListTile(
            leading: Icon(Icons.people_outline_rounded),
            title: Text('No hay estudiantes en este alcance'),
          ),
        ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

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
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

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

Color _riskColor(BuildContext context, String level) => switch (level) {
  'CRITICA' => Theme.of(context).colorScheme.errorContainer,
  'ALTA' => Colors.orange.shade200,
  _ => Colors.amber.shade100,
};

String _riskLabel(String level) => switch (level) {
  'CRITICA' => 'Crítica',
  'ALTA' => 'Alta',
  _ => 'Atención',
};

String _academicLabel(String status) => switch (status) {
  'REFUERZO' => 'Por reforzar',
  'ATENCION' => 'Atención',
  'ESTABLE' => 'Estable',
  _ => 'Sin datos',
};

String _decimal(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateTime(DateTime value) =>
    '${_date(value)} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

String _message(Object error) => switch (error) {
  ApiError() => error.message,
  FormatException() => error.message,
  StateError() => error.message,
  _ => 'No pudimos cargar la analítica detallada. Inténtalo nuevamente.',
};
