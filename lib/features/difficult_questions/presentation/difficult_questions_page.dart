import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/drift_difficult_question_repository.dart';
import '../domain/difficult_question_models.dart';
import 'difficult_question_providers.dart';

class DifficultQuestionsPage extends ConsumerWidget {
  const DifficultQuestionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(difficultQuestionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Preguntas difíciles')),
      body: questions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _LoadError(
          onRetry: () => ref.invalidate(difficultQuestionsProvider),
        ),
        data: (items) => items.isEmpty
            ? const _EmptyQuestions()
            : ListView.separated(
                key: const Key('difficult-questions-list'),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                itemCount: items.length + 1,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  if (index == 0) return const _PrivacyNotice();
                  final mark = items[index - 1];
                  return _QuestionTile(
                    mark: mark,
                    onPractice: () =>
                        context.push(mark.practiceRoute ?? '/student/practice'),
                    onRemove: () => _remove(context, ref, mark),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    DifficultQuestionMark mark,
  ) async {
    try {
      await ref
          .read(difficultQuestionRepositoryProvider)
          .remove(mark.userId, mark.questionId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se quitó de preguntas difíciles.')),
      );
    } on Object {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos actualizar la marca.')),
      );
    }
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Aquí se guarda la referencia académica. Las preguntas y sus respuestas permanecen protegidas.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.mark,
    required this.onPractice,
    required this.onRemove,
  });

  final DifficultQuestionMark mark;
  final VoidCallback onPractice;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    key: Key('difficult-question-${mark.questionId}'),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      onTap: onPractice,
      leading: const CircleAvatar(child: Icon(Icons.flag_rounded)),
      title: Text(mark.title),
      subtitle: Text(
        '${mark.area.label} · ${mark.themeName}\n'
        '${_difficultyLabel(mark.difficulty)} · ${_dateLabel(mark.markedAt)}',
      ),
      isThreeLine: true,
      trailing: IconButton(
        key: Key('remove-difficult-question-${mark.questionId}'),
        tooltip: 'Quitar marca',
        onPressed: onRemove,
        icon: const Icon(Icons.flag_outlined),
      ),
    ),
  );
}

class _EmptyQuestions extends StatelessWidget {
  const _EmptyQuestions();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.outlined_flag_rounded, size: 58),
          const SizedBox(height: 14),
          Text(
            'No has marcado preguntas difíciles',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 7),
          const Text(
            'Durante una práctica, toca la bandera para recordar qué subtemas quieres reforzar.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => context.go('/student/practice'),
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Ir a practicar'),
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
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('No pudimos cargar tus preguntas difíciles.'),
        const SizedBox(height: 12),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    ),
  );
}

String _difficultyLabel(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return 'Dificultad sin registrar';
  return 'Dificultad ${normalized.replaceAll('_', ' ')}';
}

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return 'Marcada el $day/$month/${local.year}';
}
