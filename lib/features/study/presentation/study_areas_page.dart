import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../academic/domain/academic_models.dart';
import '../domain/study_models.dart';
import 'study_providers.dart';

class StudyAreasPage extends ConsumerWidget {
  const StudyAreasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(studyProgressProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudiar'),
        actions: [
          IconButton(
            key: const Key('open-offline-downloads'),
            tooltip: 'Descargas',
            onPressed: () => context.push('/student/study/downloads'),
            icon: const Icon(Icons.download_done_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(studyProgressProvider.future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              'Contenido por área',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Elige un área para explorar sus temas, subtemas y lecciones.',
            ),
            const SizedBox(height: 20),
            _OverallProgress(progress: progress),
            const SizedBox(height: 22),
            for (final area in AcademicArea.values) ...[
              _AreaCard(area: area),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverallProgress extends StatelessWidget {
  const _OverallProgress({required this.progress});

  final AsyncValue<StudyProgress> progress;

  @override
  Widget build(BuildContext context) => progress.when(
    data: (value) => Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Progreso de contenido',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text('${value.overallPercentage}%'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: value.overallPercentage / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 9),
            Text(
              '${value.completedSubtopics} de ${value.totalSubtopics} subtemas completados',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
    loading: () => const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    ),
    error: (_, _) => const Card(
      child: ListTile(
        leading: Icon(Icons.info_outline_rounded),
        title: Text('El progreso no está disponible ahora'),
        subtitle: Text('Puedes continuar consultando las áreas.'),
      ),
    ),
  );
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area});

  final AcademicArea area;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      key: Key('study-area-${area.slug}'),
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.push('/student/study/${area.slug}'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(radius: 25, child: Icon(_iconFor(area))),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  const Text('Ver temas y lecciones'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}

IconData _iconFor(AcademicArea area) => switch (area) {
  AcademicArea.criticalReading => Icons.auto_stories_rounded,
  AcademicArea.mathematics => Icons.calculate_rounded,
  AcademicArea.naturalSciences => Icons.science_rounded,
  AcademicArea.socialSciences => Icons.public_rounded,
  AcademicArea.english => Icons.translate_rounded,
};
