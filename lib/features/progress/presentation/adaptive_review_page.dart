import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../domain/progress_models.dart';
import 'progress_providers.dart';

class AdaptiveReviewPage extends ConsumerStatefulWidget {
  const AdaptiveReviewPage({super.key});

  @override
  ConsumerState<AdaptiveReviewPage> createState() => _AdaptiveReviewPageState();
}

class _AdaptiveReviewPageState extends ConsumerState<AdaptiveReviewPage> {
  var _questionCount = 15;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(adaptiveProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Repaso inteligente')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ProfileError(
          message: _messageFor(error),
          onRetry: () => ref.invalidate(adaptiveProfileProvider),
        ),
        data: (data) => _content(context, data),
      ),
    );
  }

  Widget _content(BuildContext context, AdaptiveProfile profile) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
    children: [
      Text(
        'Una sesión hecha para ti',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      const Text(
        'SaberPlus usa tu rendimiento reciente para elegir áreas y dificultades que necesitas reforzar.',
      ),
      const SizedBox(height: 18),
      _ProfileSummary(profile: profile),
      const SizedBox(height: 14),
      _PriorityAreas(areas: profile.priorityAreas),
      const SizedBox(height: 14),
      _DifficultyMix(mix: profile.recommendedMix),
      const SizedBox(height: 22),
      Text(
        'Cantidad de preguntas',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final count in const [5, 10, 15, 20, 30])
            ChoiceChip(
              label: Text('$count'),
              selected: _questionCount == count,
              onSelected: (_) => setState(() => _questionCount = count),
            ),
        ],
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        key: const Key('start-adaptive-review-button'),
        onPressed: () => context.push(
          '/student/progress/adaptive/session?cantidad=$_questionCount',
        ),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: Text('Comenzar repaso de $_questionCount'),
      ),
      const SizedBox(height: 24),
      Text(
        'Cómo decide el sistema',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 10),
      for (final performance in profile.areaPerformance) ...[
        _AreaPriorityRow(performance: performance),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 4),
      Text(
        'El perfil se actualiza al terminar cada sesión.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final AdaptiveProfile profile;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            child: Text(
              profile.recentAccuracy == null
                  ? '—'
                  : '${profile.recentAccuracy!.round()}%',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nivel objetivo: ${profile.targetLevel.label}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  profile.analyzedAttempts == 0
                      ? 'Aún no hay respuestas; comenzarás con un nivel equilibrado.'
                      : '${profile.analyzedAttempts} respuestas analizadas',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PriorityAreas extends StatelessWidget {
  const _PriorityAreas({required this.areas});

  final List<AcademicArea> areas;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Áreas prioritarias',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < areas.length; index++)
                Chip(
                  avatar: CircleAvatar(child: Text('${index + 1}')),
                  label: Text(areas[index].label),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _DifficultyMix extends StatelessWidget {
  const _DifficultyMix({required this.mix});

  final AdaptiveDifficultyMix mix;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mezcla recomendada',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MixValue(label: 'Básica', value: mix.basic),
              ),
              Expanded(
                child: _MixValue(label: 'Media', value: mix.medium),
              ),
              Expanded(
                child: _MixValue(label: 'Avanzada', value: mix.advanced),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _MixValue extends StatelessWidget {
  const _MixValue({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('$value%', style: Theme.of(context).textTheme.titleLarge),
      Text(label),
    ],
  );
}

class _AreaPriorityRow extends StatelessWidget {
  const _AreaPriorityRow({required this.performance});

  final AdaptiveAreaPerformance performance;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  performance.area.label,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  performance.accuracy == null
                      ? 'Sin respuestas previas'
                      : '${performance.accuracy!.round()}% de precisión · ${performance.attempts} intentos',
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('Prioridad ${performance.priority}'),
        ],
      ),
    ),
  );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 48),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
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

String _messageFor(Object error) => error is ApiError
    ? error.message
    : 'No pudimos preparar tu perfil adaptativo. Intenta nuevamente.';
