import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/academic_profile_models.dart';
import '../domain/score_projection.dart';
import 'academic_profile_providers.dart';

class ScoreProjectionPage extends ConsumerWidget {
  const ScoreProjectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projection = ref.watch(scoreProjectionProvider);
    final goal = ref.watch(examGoalControllerProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puntaje proyectado'),
        actions: [
          IconButton(
            key: const Key('refresh-score-projection'),
            tooltip: 'Actualizar proyección',
            onPressed: () => _refresh(ref),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: projection.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ProjectionError(onRetry: () => _refresh(ref)),
        data: (data) => data == null
            ? const _InsufficientEvidence()
            : _ProjectionContent(projection: data, goal: goal),
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(academicProfileProgressProvider);
    ref.invalidate(scoreProjectionProvider);
    try {
      await ref.read(scoreProjectionProvider.future);
    } on Object {
      // La pantalla conserva el error y permite volver a intentar.
    }
  }
}

class _ProjectionContent extends StatelessWidget {
  const _ProjectionContent({required this.projection, required this.goal});

  final ScoreProjection projection;
  final PersonalExamGoal? goal;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('score-projection-list'),
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(18, 10, 18, 32),
    children: [
      Card(
        key: const Key('score-projection-result'),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTIMACIÓN ACTUAL',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 5),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${projection.estimatedGlobalScore}',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 6, bottom: 5),
                    child: Text('de 500'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Rango orientativo: ${projection.lowerBound}–${projection.upperBound}',
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      _ConfidenceCard(projection: projection),
      const SizedBox(height: 14),
      _GoalComparison(projection: projection, goal: goal),
      const SizedBox(height: 24),
      Text(
        'Estimación por materia',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 5),
      const Text(
        'Los simulacros recientes tienen prioridad sobre otras prácticas.',
      ),
      const SizedBox(height: 12),
      Card(
        key: const Key('score-projection-areas'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              for (
                var index = 0;
                index < projection.areaScores.length;
                index++
              ) ...[
                _AreaScoreRow(score: projection.areaScores[index]),
                if (index < projection.areaScores.length - 1)
                  const Divider(height: 24),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      const _MethodNotice(),
    ],
  );
}

class _ConfidenceCard extends StatelessWidget {
  const _ConfidenceCard({required this.projection});

  final ScoreProjection projection;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('score-projection-confidence'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.analytics_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confianza ${projection.confidence.label.toLowerCase()}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${projection.simulatedAreaCount} de 5 materias con simulacros · '
                  '${projection.simulationQuestionCount} preguntas consideradas',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _GoalComparison extends StatelessWidget {
  const _GoalComparison({required this.projection, required this.goal});

  final ScoreProjection projection;
  final PersonalExamGoal? goal;

  @override
  Widget build(BuildContext context) {
    final target = goal?.targetScore;
    final difference = target == null
        ? null
        : projection.estimatedGlobalScore - target;
    return Card(
      key: const Key('score-projection-goal'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.flag_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target == null
                        ? 'Aún no definiste un objetivo'
                        : 'Tu objetivo: $target puntos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    difference == null
                        ? 'Puedes crearlo desde tu perfil académico.'
                        : difference >= 0
                        ? 'La estimación está ${difference.abs()} puntos por encima.'
                        : 'La estimación está ${difference.abs()} puntos por debajo.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaScoreRow extends StatelessWidget {
  const _AreaScoreRow({required this.score});

  final ProjectedAreaScore score;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              score.area.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text('${score.score.round()}/100'),
        ],
      ),
      const SizedBox(height: 8),
      LinearProgressIndicator(
        value: score.score / 100,
        minHeight: 8,
        borderRadius: BorderRadius.circular(99),
      ),
      const SizedBox(height: 6),
      Text(
        '${score.source.label} · ${score.evidenceQuestions} preguntas',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _MethodNotice extends StatelessWidget {
  const _MethodNotice();

  @override
  Widget build(BuildContext context) => Card(
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
              'Esta es una estimación educativa de SaberPlus, no un resultado oficial del ICFES. Los porcentajes de práctica no sustituyen el modelo estadístico usado en el examen real.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _InsufficientEvidence extends StatelessWidget {
  const _InsufficientEvidence();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.query_stats_rounded, size: 48),
          const SizedBox(height: 14),
          Text(
            'Aún faltan datos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Necesitamos resultados en las cinco materias para crear una estimación responsable.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.tonalIcon(
            onPressed: () => context.go('/student/practice'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Ir a practicar'),
          ),
        ],
      ),
    ),
  );
}

class _ProjectionError extends StatelessWidget {
  const _ProjectionError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44),
          const SizedBox(height: 12),
          const Text('No pudimos actualizar la proyección.'),
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
