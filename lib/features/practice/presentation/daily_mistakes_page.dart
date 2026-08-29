import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../domain/daily_mistake_review.dart';
import '../domain/practice_history_models.dart';
import 'practice_providers.dart';

class DailyMistakesPage extends ConsumerStatefulWidget {
  const DailyMistakesPage({super.key, this.now});

  final DateTime? now;

  @override
  ConsumerState<DailyMistakesPage> createState() => _DailyMistakesPageState();
}

class _DailyMistakesPageState extends ConsumerState<DailyMistakesPage> {
  final _reviewedQuestionIds = <String>{};
  late Future<DailyMistakeReview> _review;

  DateTime get _today => widget.now ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _review = _load();
  }

  Future<DailyMistakeReview> _load() async {
    final history = await ref
        .read(practiceRepositoryProvider)
        .loadAnswerHistory(
          const AnswerHistoryFilter(
            outcome: AnswerOutcomeFilter.incorrect,
            limit: 100,
          ),
        );
    return DailyMistakeReview.fromHistory(history, day: _today);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _review = next);
    final result = await next;
    if (!mounted) return;
    final available = result.mistakes.map((item) => item.questionId).toSet();
    setState(
      () => _reviewedQuestionIds.removeWhere(
        (questionId) => !available.contains(questionId),
      ),
    );
  }

  void _toggleReviewed(String questionId) {
    setState(() {
      if (!_reviewedQuestionIds.remove(questionId)) {
        _reviewedQuestionIds.add(questionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Repaso de hoy')),
    body: FutureBuilder<DailyMistakeReview>(
      future: _review,
      builder: (context, snapshot) => switch (snapshot) {
        AsyncSnapshot(hasData: true, data: final review?) => _content(
          context,
          review,
        ),
        AsyncSnapshot(hasError: true, error: final error?) => _LoadError(
          message: _messageFor(error),
          onRetry: () => setState(() => _review = _load()),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    ),
  );

  Widget _content(BuildContext context, DailyMistakeReview review) {
    final items = review.mistakes;
    if (items.isEmpty) {
      return RefreshIndicator(onRefresh: _refresh, child: const _EmptyReview());
    }
    final reviewed = items
        .where((item) => _reviewedQuestionIds.contains(item.questionId))
        .length;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        key: const Key('daily-mistakes-list'),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _ReviewProgress(reviewed: reviewed, total: items.length),
          const SizedBox(height: 14),
          const Text(
            'Revisa por qué fallaste cada pregunta. Solo aparecen respuestas calificadas durante el día de hoy.',
          ),
          const SizedBox(height: 16),
          for (final item in items) ...[
            _DailyMistakeCard(
              answer: item,
              reviewed: _reviewedQuestionIds.contains(item.questionId),
              onToggleReviewed: () => _toggleReviewed(item.questionId),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            key: const Key('open-adaptive-from-daily-review'),
            onPressed: () => context.push('/student/progress/adaptive'),
            icon: const Icon(Icons.auto_awesome_rounded),
            label: const Text('Preparar repaso inteligente'),
          ),
        ],
      ),
    );
  }
}

class _ReviewProgress extends StatelessWidget {
  const _ReviewProgress({required this.reviewed, required this.total});

  final int reviewed;
  final int total;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$reviewed de $total repasadas',
                  key: const Key('daily-review-progress-label'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: total == 0 ? 0 : reviewed / total),
        ],
      ),
    ),
  );
}

class _DailyMistakeCard extends StatelessWidget {
  const _DailyMistakeCard({
    required this.answer,
    required this.reviewed,
    required this.onToggleReviewed,
  });

  final AnswerHistoryItem answer;
  final bool reviewed;
  final VoidCallback onToggleReviewed;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      key: Key('daily-mistake-${answer.questionId}'),
      initiallyExpanded: !reviewed,
      leading: Icon(
        reviewed ? Icons.check_circle_rounded : Icons.error_outline_rounded,
        color: reviewed ? Colors.green.shade700 : Colors.orange.shade800,
      ),
      title: Text(answer.subtopic),
      subtitle: Text('${answer.area.label} · ${answer.theme}'),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(answer.statement),
        const SizedBox(height: 12),
        Text('Tu respuesta: ${answer.selectedAnswer?.text ?? 'No disponible'}'),
        const SizedBox(height: 4),
        Text(
          'Respuesta correcta: ${answer.correctAnswer?.text ?? 'No disponible'}',
        ),
        if (answer.explanation case final explanation?) ...[
          const SizedBox(height: 12),
          Text('Explicación', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(explanation),
        ],
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.tonalIcon(
            key: Key('review-daily-mistake-${answer.questionId}'),
            onPressed: onToggleReviewed,
            icon: Icon(
              reviewed ? Icons.undo_rounded : Icons.check_circle_outline,
            ),
            label: Text(reviewed ? 'Marcar pendiente' : 'Ya la repasé'),
          ),
        ),
      ],
    ),
  );
}

class _EmptyReview extends StatelessWidget {
  const _EmptyReview();

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('empty-daily-review'),
    padding: const EdgeInsets.all(28),
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      const SizedBox(height: 100),
      const Icon(Icons.task_alt_rounded, size: 62),
      const SizedBox(height: 14),
      Text(
        'No tienes errores registrados hoy',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 8),
      const Text(
        'Cuando completes una práctica, aquí aparecerán las preguntas que necesites revisar.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      Center(
        child: FilledButton.tonalIcon(
          onPressed: () => context.go('/student/practice'),
          icon: const Icon(Icons.quiz_outlined),
          label: const Text('Ir a practicar'),
        ),
      ),
    ],
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
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
    : 'No pudimos cargar los errores de hoy. Intenta nuevamente.';
