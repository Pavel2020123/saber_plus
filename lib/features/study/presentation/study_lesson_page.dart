import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/environment.dart';
import '../../../core/config/resource_url.dart';
import '../../../core/network/api_error.dart';
import '../../academic/domain/academic_models.dart';
import '../../auth/presentation/session_controller.dart';
import '../data/remote_study_repository.dart';
import '../domain/study_models.dart';
import 'study_providers.dart';

class StudyLessonPage extends ConsumerStatefulWidget {
  const StudyLessonPage({
    super.key,
    required this.area,
    required this.themeId,
    required this.subtopicId,
  });

  final AcademicArea area;
  final String themeId;
  final String subtopicId;

  @override
  ConsumerState<StudyLessonPage> createState() => _StudyLessonPageState();
}

class _StudyLessonPageState extends ConsumerState<StudyLessonPage> {
  var _saving = false;
  var _completedLocally = false;

  Future<void> _markComplete() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final isDemo = ref.read(sessionControllerProvider).user?.isDemo ?? false;
      if (!isDemo) {
        await ref
            .read(studyRepositoryProvider)
            .updateSubtopicProgress(widget.subtopicId, 100);
        ref.invalidate(studyProgressProvider);
      }
      if (!mounted) return;
      setState(() => _completedLocally = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lección marcada como completada.')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(studyCatalogProvider(widget.area));
    final savedPercentage = ref
        .watch(studyProgressProvider)
        .valueOrNull
        ?.percentageFor(widget.subtopicId);
    return Scaffold(
      appBar: AppBar(title: const Text('Lección')),
      body: catalog.when(
        data: (value) {
          final theme = value.findTheme(widget.themeId);
          final subtopic = value.findSubtopic(
            widget.themeId,
            widget.subtopicId,
          );
          if (theme == null || subtopic == null) {
            return const _MissingLesson();
          }
          return _LessonContent(
            area: widget.area,
            theme: theme,
            subtopic: subtopic,
            completed: _completedLocally || savedPercentage == 100,
            saving: _saving,
            onMarkComplete: _markComplete,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LessonError(
          message: _errorMessage(error),
          onRetry: () => ref.invalidate(studyCatalogProvider(widget.area)),
        ),
      ),
    );
  }
}

class _LessonContent extends ConsumerWidget {
  const _LessonContent({
    required this.area,
    required this.theme,
    required this.subtopic,
    required this.completed,
    required this.saving,
    required this.onMarkComplete,
  });

  final AcademicArea area;
  final StudyTheme theme;
  final StudySubtopic subtopic;
  final bool completed;
  final bool saving;
  final VoidCallback onMarkComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(area.label)),
            Chip(label: Text(theme.name)),
          ],
        ),
        const SizedBox(height: 14),
        Text(subtopic.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${subtopic.totalQuestions} preguntas de práctica disponibles',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        if (!subtopic.hasLearningResource)
          const _NoResources()
        else ...[
          if (subtopic.content case final content?)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: MarkdownBody(
                  data: content,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                  onTapLink: (text, href, title) {
                    if (href != null) _openExternal(context, href);
                  },
                  imageBuilder: (uri, title, alt) => _LessonImage(
                    url: resolveResourceUrl(config, uri.toString()),
                  ),
                ),
              ),
            ),
          if (subtopic.videoUrl case final videoUrl?) ...[
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.play_arrow_rounded),
                ),
                title: const Text('Video de la lección'),
                subtitle: const Text('Se abrirá en el reproductor disponible.'),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => _openExternal(context, videoUrl),
              ),
            ),
          ],
          if (subtopic.imageUrl case final imageUrl?) ...[
            const SizedBox(height: 14),
            _LessonImage(url: resolveResourceUrl(config, imageUrl)),
          ],
          if (subtopic.clozeActivity case final activity?) ...[
            const SizedBox(height: 18),
            _ClozeExercise(activity: activity),
          ],
        ],
        const SizedBox(height: 22),
        FilledButton.icon(
          key: const Key('complete-study-lesson-button'),
          onPressed: completed || saving ? null : onMarkComplete,
          icon: saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.task_alt_rounded,
                ),
          label: Text(
            completed ? 'Lección completada' : 'Marcar como completada',
          ),
        ),
        if (subtopic.totalQuestions > 0) ...[
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            key: const Key('start-subtopic-practice-button'),
            onPressed: () => context.push(
              '/student/practice/subtopic/${area.slug}/${subtopic.id}',
            ),
            icon: const Icon(Icons.quiz_rounded),
            label: Text('Practicar ${subtopic.totalQuestions} preguntas'),
          ),
        ],
      ],
    );
  }
}

class _LessonImage extends StatelessWidget {
  const _LessonImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        padding: const EdgeInsets.all(22),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined),
            SizedBox(width: 9),
            Flexible(child: Text('La imagen no está disponible.')),
          ],
        ),
      ),
    ),
  );
}

class _ClozeExercise extends StatefulWidget {
  const _ClozeExercise({required this.activity});

  final ClozeActivity activity;

  @override
  State<_ClozeExercise> createState() => _ClozeExerciseState();
}

class _ClozeExerciseState extends State<_ClozeExercise> {
  late List<int?> _answers;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _answers = List<int?>.filled(widget.activity.blanks.length, null);
  }

  void _reset() {
    setState(() {
      _answers = List<int?>.filled(widget.activity.blanks.length, null);
      _checked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final correct = List.generate(
      widget.activity.blanks.length,
      (index) => _answers[index] == widget.activity.blanks[index].correctIndex,
    ).where((value) => value).length;
    final ready = _answers.every((answer) => answer != null);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividad interactiva',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(widget.activity.textWithBlanks),
            const SizedBox(height: 16),
            for (
              var index = 0;
              index < widget.activity.blanks.length;
              index++
            ) ...[
              DropdownButtonFormField<int>(
                key: Key('cloze-answer-$index'),
                initialValue: _answers[index],
                decoration: InputDecoration(
                  labelText: 'Espacio ${index + 1}',
                  suffixIcon: _checked
                      ? Icon(
                          _answers[index] ==
                                  widget.activity.blanks[index].correctIndex
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                        )
                      : null,
                ),
                items: [
                  for (
                    var optionIndex = 0;
                    optionIndex < widget.activity.blanks[index].options.length;
                    optionIndex++
                  )
                    DropdownMenuItem(
                      value: optionIndex,
                      child: Text(
                        widget.activity.blanks[index].options[optionIndex],
                      ),
                    ),
                ],
                onChanged: _checked
                    ? null
                    : (value) => setState(() => _answers[index] = value),
              ),
              const SizedBox(height: 10),
            ],
            if (_checked) ...[
              Text('$correct de ${widget.activity.blanks.length} correctas'),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: ready && !_checked
                        ? () => setState(() => _checked = true)
                        : null,
                    child: const Text('Comprobar'),
                  ),
                ),
                if (_checked) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: _reset,
                    child: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResources extends StatelessWidget {
  const _NoResources();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 48),
          SizedBox(height: 10),
          Text('El contenido de esta lección se agregará pronto.'),
        ],
      ),
    ),
  );
}

class _MissingLesson extends StatelessWidget {
  const _MissingLesson();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(28),
      child: Text('Esta lección ya no está disponible.'),
    ),
  );
}

class _LessonError extends StatelessWidget {
  const _LessonError({required this.message, required this.onRetry});

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

Future<void> _openExternal(BuildContext context, String value) async {
  final uri = Uri.tryParse(value);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('El enlace de este recurso no es válido.')),
    );
    return;
  }
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No pudimos abrir este recurso.')),
    );
  }
}

String _errorMessage(Object error) =>
    error is ApiError ? error.message : 'No pudimos cargar esta lección.';
