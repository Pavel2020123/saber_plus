import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../academic/domain/academic_models.dart';
import '../../academic/presentation/academic_home_controller.dart';
import '../domain/syllabus_countdown_models.dart';
import 'study_providers.dart';
import 'syllabus_countdown_providers.dart';

class SyllabusCountdownPage extends ConsumerWidget {
  const SyllabusCountdownPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(academicHomeControllerProvider);
    ref.invalidate(studyProgressProvider);
    for (final area in AcademicArea.values) {
      ref.invalidate(studyCatalogProvider(area));
    }
    ref.invalidate(syllabusCountdownProvider);
    await ref.read(syllabusCountdownProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countdown = ref.watch(syllabusCountdownProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Countdown del temario')),
      body: countdown.when(
        data: (value) => RefreshIndicator(
          onRefresh: () => _refresh(ref),
          child: _CountdownContent(value: value),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _CountdownError(onRetry: () => _refresh(ref)),
      ),
    );
  }
}

class _CountdownContent extends StatelessWidget {
  const _CountdownContent({required this.value});

  final SyllabusCountdown value;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('syllabus-countdown-list'),
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
    children: [
      Text(
        'Tu ruta antes del examen',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'El cálculo usa la convocatoria activa y los subtemas publicados. Se actualiza cuando completas una lección.',
      ),
      const SizedBox(height: 18),
      _CountdownSummary(value: value),
      const SizedBox(height: 24),
      Text(
        'Prioridad por materia',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      const Text('Las materias con más contenido pendiente aparecen primero.'),
      const SizedBox(height: 14),
      for (final area in value.areas) ...[
        _AreaCountdownCard(value: area, hasActiveDate: _hasActiveDate(value)),
        const SizedBox(height: 10),
      ],
    ],
  );
}

class _CountdownSummary extends StatelessWidget {
  const _CountdownSummary({required this.value});

  final SyllabusCountdown value;

  @override
  Widget build(BuildContext context) {
    final status = _statusContent(value.status);
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: const Key('syllabus-countdown-summary'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(status.icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(status.detail),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SummaryMetric(
                    value: value.daysRemaining == null
                        ? '—'
                        : '${value.daysRemaining!.clamp(0, 9999)}',
                    label: 'días',
                  ),
                ),
                Expanded(
                  child: _SummaryMetric(
                    key: const Key('syllabus-remaining-total'),
                    value: '${value.remainingSubtopics}',
                    label: 'subtemas pendientes',
                  ),
                ),
                Expanded(
                  child: _SummaryMetric(
                    value: _hasActiveDate(value)
                        ? value.requiredPerWeek.toStringAsFixed(1)
                        : '—',
                    label: 'por semana',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: value.totalSubtopics == 0
                  ? 0
                  : value.completedSubtopics / value.totalSubtopics,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: colors.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              '${value.completedSubtopics} de ${value.totalSubtopics} subtemas completados',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: Theme.of(context).textTheme.headlineSmall),
      Text(label, textAlign: TextAlign.center),
    ],
  );
}

class _AreaCountdownCard extends StatelessWidget {
  const _AreaCountdownCard({required this.value, required this.hasActiveDate});

  final SyllabusAreaCountdown value;
  final bool hasActiveDate;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      key: Key('syllabus-area-${value.area.slug}'),
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push('/student/study/${value.area.slug}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(_iconFor(value.area))),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value.area.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${value.averagePercentage}%'),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: value.averagePercentage / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 9),
            Text(
              '${value.completedSubtopics}/${value.totalSubtopics} completados · ${value.remainingSubtopics} pendientes',
            ),
            if (value.inProgressSubtopics > 0)
              Text('${value.inProgressSubtopics} en progreso'),
            if (hasActiveDate && value.remainingSubtopics > 0)
              Text(
                'Ritmo sugerido: ${value.requiredPerWeek.toStringAsFixed(1)} por semana',
              ),
            if (value.pendingSubtopics.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Siguiente: ${value.pendingSubtopics.take(2).join(' · ')}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _CountdownError extends StatelessWidget {
  const _CountdownError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(28),
    children: [
      const SizedBox(height: 100),
      const Icon(Icons.cloud_off_rounded, size: 58),
      const SizedBox(height: 14),
      const Text(
        'No pudimos calcular el temario pendiente.',
        textAlign: TextAlign.center,
      ),
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

bool _hasActiveDate(SyllabusCountdown value) =>
    value.exam != null && (value.daysRemaining ?? 0) > 0;

({String title, String detail, IconData icon}) _statusContent(
  SyllabusPaceStatus status,
) => switch (status) {
  SyllabusPaceStatus.dateMissing => (
    title: 'Fecha pendiente',
    detail: 'Configura la convocatoria para calcular el ritmo semanal.',
    icon: Icons.event_busy_outlined,
  ),
  SyllabusPaceStatus.examElapsed => (
    title: 'Convocatoria finalizada',
    detail: 'Actualiza la fecha para crear una nueva ruta.',
    icon: Icons.event_busy_outlined,
  ),
  SyllabusPaceStatus.noContent => (
    title: 'Temario pendiente',
    detail: 'Todavía no hay subtemas publicados.',
    icon: Icons.menu_book_outlined,
  ),
  SyllabusPaceStatus.completed => (
    title: 'Temario completado',
    detail: 'Mantén el conocimiento con repasos y simulacros.',
    icon: Icons.verified_rounded,
  ),
  SyllabusPaceStatus.manageable => (
    title: 'Ritmo alcanzable',
    detail: 'Avanza con constancia para cubrir todo el temario.',
    icon: Icons.route_rounded,
  ),
  SyllabusPaceStatus.demanding => (
    title: 'Ritmo exigente',
    detail: 'Prioriza las materias con más subtemas pendientes.',
    icon: Icons.speed_rounded,
  ),
  SyllabusPaceStatus.intensive => (
    title: 'Ritmo intensivo',
    detail: 'Reduce pendientes y enfócate primero en lo esencial.',
    icon: Icons.priority_high_rounded,
  ),
};

IconData _iconFor(AcademicArea area) => switch (area) {
  AcademicArea.criticalReading => Icons.auto_stories_rounded,
  AcademicArea.mathematics => Icons.calculate_rounded,
  AcademicArea.naturalSciences => Icons.science_rounded,
  AcademicArea.socialSciences => Icons.public_rounded,
  AcademicArea.english => Icons.translate_rounded,
};
