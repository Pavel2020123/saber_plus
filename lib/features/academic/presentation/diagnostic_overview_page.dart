import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../core/network/api_error.dart';
import '../../exam_countdown/presentation/exam_countdown_banner.dart';
import '../data/diagnostic_draft_store.dart';
import '../domain/academic_models.dart';
import 'academic_home_controller.dart';

class DiagnosticOverviewPage extends ConsumerWidget {
  const DiagnosticOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final academic = ref.watch(academicHomeControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico inicial')),
      body: SafeArea(
        top: false,
        child: academic.when(
          data: (data) => _DiagnosticContent(diagnostic: data.diagnostic),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DiagnosticError(
            message: _messageFor(error),
            onRetry: () =>
                ref.read(academicHomeControllerProvider.notifier).reload(),
          ),
        ),
      ),
      bottomNavigationBar: const ExamCountdownBanner(
        includeBottomSafeArea: true,
      ),
    );
  }
}

class _DiagnosticContent extends ConsumerWidget {
  const _DiagnosticContent({required this.diagnostic});

  final DiagnosticSummary diagnostic;

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) => switch (diagnostic.status) {
    DiagnosticStatus.notStarted => _DiagnosticIntroduction(
      onStart: () =>
          ref.read(academicHomeControllerProvider.notifier).startDiagnostic(),
    ),
    DiagnosticStatus.inProgress => _DiagnosticSession(diagnostic: diagnostic),
    DiagnosticStatus.completed => _DiagnosticResults(diagnostic: diagnostic),
  };
}

class _DiagnosticIntroduction extends StatelessWidget {
  const _DiagnosticIntroduction({required this.onStart});

  final Future<bool> Function() onStart;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
    children: [
      Icon(
        Icons.explore_rounded,
        size: 88,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 22),
      Text(
        'Descubre tu punto de partida',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 10),
      Text(
        'Responderás una muestra de las cinco áreas. El resultado organizará las prioridades de tu plan de estudio.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
      ),
      const SizedBox(height: 28),
      const Row(
        children: [
          Expanded(
            child: _FactCard(value: '15', label: 'preguntas'),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _FactCard(value: '5', label: 'áreas ICFES'),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _FactCard(value: '∞', label: 'sin límite'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Respóndelo sin consultar apuntes. Las respuestas correctas se mantienen ocultas hasta finalizar.',
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        key: const Key('start-diagnostic-button'),
        onPressed: () async {
          final success = await onStart();
          if (!success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo iniciar el diagnóstico.'),
              ),
            );
          }
        },
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('Preparar diagnóstico'),
      ),
    ],
  );
}

class _DiagnosticSession extends ConsumerStatefulWidget {
  const _DiagnosticSession({required this.diagnostic});

  final DiagnosticSummary diagnostic;

  @override
  ConsumerState<_DiagnosticSession> createState() => _DiagnosticSessionState();
}

class _DiagnosticSessionState extends ConsumerState<_DiagnosticSession>
    with WidgetsBindingObserver {
  final _selectedAnswers = <String, String>{};
  final _responseTimes = <String, int>{};
  var _currentIndex = 0;
  var _restoring = true;
  var _submitting = false;
  var _completed = false;
  DateTime _questionOpenedAt = DateTime.now();
  late final DiagnosticDraftStore _draftStore;

  List<DiagnosticQuestion> get _questions => widget.diagnostic.questions;
  String get _diagnosticId => widget.diagnostic.id!;

  @override
  void initState() {
    super.initState();
    _draftStore = ref.read(diagnosticDraftStoreProvider);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_restoreDraft());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_completed) {
      _recordElapsedTime();
      unawaited(_saveDraft());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _recordElapsedTime();
      unawaited(_saveDraft());
    }
  }

  Future<void> _restoreDraft() async {
    if (_questions.isEmpty || widget.diagnostic.id == null) {
      if (mounted) setState(() => _restoring = false);
      return;
    }
    final draft = await _draftStore.read(_diagnosticId);
    if (!mounted) return;

    final questionsById = {
      for (final question in _questions) question.id: question,
    };
    if (draft != null) {
      for (final entry in draft.selectedAnswers.entries) {
        final question = questionsById[entry.key];
        if (question != null &&
            question.options.any((option) => option.id == entry.value)) {
          _selectedAnswers[entry.key] = entry.value;
        }
      }
      for (final entry in draft.responseTimesSeconds.entries) {
        if (questionsById.containsKey(entry.key)) {
          _responseTimes[entry.key] = entry.value.clamp(0, 7200);
        }
      }
      _currentIndex = draft.currentQuestionIndex.clamp(
        0,
        _questions.length - 1,
      );
    }
    _questionOpenedAt = DateTime.now();
    setState(() => _restoring = false);
  }

  void _recordElapsedTime() {
    if (_restoring || _questions.isEmpty) return;
    final now = DateTime.now();
    final questionId = _questions[_currentIndex].id;
    final elapsed = now.difference(_questionOpenedAt).inSeconds;
    _responseTimes[questionId] = ((_responseTimes[questionId] ?? 0) + elapsed)
        .clamp(0, 7200);
    _questionOpenedAt = now;
  }

  Future<void> _saveDraft() {
    if (_questions.isEmpty || widget.diagnostic.id == null) {
      return Future.value();
    }
    return _draftStore.save(
      DiagnosticDraft(
        diagnosticId: _diagnosticId,
        selectedAnswers: Map.unmodifiable(_selectedAnswers),
        responseTimesSeconds: Map.unmodifiable(_responseTimes),
        currentQuestionIndex: _currentIndex,
      ),
    );
  }

  void _selectAnswer(String answerId) {
    if (_submitting) return;
    _recordElapsedTime();
    final questionId = _questions[_currentIndex].id;
    setState(() => _selectedAnswers[questionId] = answerId);
    unawaited(_saveDraft());
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length || _submitting) return;
    _recordElapsedTime();
    setState(() => _currentIndex = index);
    _questionOpenedAt = DateTime.now();
    unawaited(_saveDraft());
  }

  Future<void> _finish() async {
    final missingIndex = _questions.indexWhere(
      (question) => !_selectedAnswers.containsKey(question.id),
    );
    if (missingIndex >= 0) {
      _goToQuestion(missingIndex);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Responde todas las preguntas antes de finalizar.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Finalizar diagnóstico?'),
        content: const Text(
          'Tus respuestas se enviarán para calcular el resultado. Después no podrás cambiarlas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Revisar'),
          ),
          FilledButton(
            key: const Key('confirm-finish-diagnostic-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    _recordElapsedTime();
    setState(() => _submitting = true);
    final answers = [
      for (final question in _questions)
        DiagnosticAnswer(
          questionId: question.id,
          answerId: _selectedAnswers[question.id]!,
          responseTimeSeconds: _responseTimes[question.id] ?? 0,
        ),
    ];

    try {
      final controller = ref.read(academicHomeControllerProvider.notifier);
      final result = await controller.finishDiagnostic(answers);
      _completed = true;
      await _draftStore.clear(_diagnosticId);
      if (!mounted) return;
      ref.invalidate(diagnosticWeakTopicsProvider);
      controller.acceptDiagnosticResult(result);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_restoring) return const Center(child: CircularProgressIndicator());
    if (_questions.isEmpty) {
      return _DiagnosticError(
        message: 'El servidor no entregó las preguntas reservadas.',
        onRetry: () =>
            ref.read(academicHomeControllerProvider.notifier).reload(),
      );
    }

    final question = _questions[_currentIndex];
    final selected = _selectedAnswers[question.id];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pregunta ${_currentIndex + 1} de ${_questions.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text('${_selectedAnswers.length} respondidas'),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(question.area.label)),
                  Chip(label: Text(question.subtopicName)),
                ],
              ),
              if (question.caseContent case final caseContent?) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (caseContent.title.isNotEmpty)
                          Text(
                            caseContent.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        if (caseContent.title.isNotEmpty &&
                            caseContent.context.isNotEmpty)
                          const SizedBox(height: 10),
                        if (caseContent.context.isNotEmpty)
                          Text(caseContent.context),
                        if (caseContent.imageUrl case final url?) ...[
                          const SizedBox(height: 14),
                          _RemoteQuestionImage(url: url),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                question.statement,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(height: 1.35),
              ),
              if (question.imageUrl case final url?) ...[
                const SizedBox(height: 14),
                _RemoteQuestionImage(url: url),
              ],
              const SizedBox(height: 20),
              for (var index = 0; index < question.options.length; index++) ...[
                _AnswerOption(
                  key: Key('diagnostic-option-${question.options[index].id}'),
                  letter: String.fromCharCode(65 + index),
                  option: question.options[index],
                  selected: selected == question.options[index].id,
                  onTap: () => _selectAnswer(question.options[index].id),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _currentIndex == 0 || _submitting
                        ? null
                        : () => _goToQuestion(_currentIndex - 1),
                    child: const Text('Anterior'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: Key(
                      _currentIndex == _questions.length - 1
                          ? 'finish-diagnostic-button'
                          : 'next-diagnostic-question-button',
                    ),
                    onPressed: _submitting
                        ? null
                        : _currentIndex == _questions.length - 1
                        ? _finish
                        : () => _goToQuestion(_currentIndex + 1),
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _currentIndex == _questions.length - 1
                                ? 'Finalizar'
                                : 'Siguiente',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    super.key,
    required this.letter,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final DiagnosticOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: selected
                      ? colors.primary
                      : colors.surfaceContainerHighest,
                  foregroundColor: selected
                      ? colors.onPrimary
                      : colors.onSurface,
                  child: Text(letter),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(option.text)),
                if (selected)
                  Icon(Icons.check_circle_rounded, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RemoteQuestionImage extends ConsumerWidget {
  const _RemoteQuestionImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsed = Uri.tryParse(url);
    final resolved = parsed?.hasScheme ?? false
        ? url
        : '${ref.watch(appConfigProvider).apiBaseUrl}/${url.replaceFirst(RegExp(r'^/+'), '')}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        resolved,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }
}

class _DiagnosticResults extends ConsumerWidget {
  const _DiagnosticResults({required this.diagnostic});

  final DiagnosticSummary diagnostic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weakTopicsAsync = diagnostic.weakTopics.isNotEmpty
        ? AsyncValue<List<WeakTopic>>.data(diagnostic.weakTopics)
        : ref.watch(diagnosticWeakTopicsProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu línea base',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '${_number(diagnostic.percentage)}%',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(
                  '${diagnostic.correctAnswers} de ${diagnostic.totalQuestions} respuestas correctas · ${diagnostic.level?.label ?? ''}',
                ),
                if (diagnostic.priorityArea case final area?) ...[
                  const SizedBox(height: 14),
                  Text('Área prioritaria: ${area.label}'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Resultado por área',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        for (final result in diagnostic.resultsByArea)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.area.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Text(result.level.label),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: result.percentage / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${result.correctAnswers}/${result.totalQuestions} · ${_number(result.percentage)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Temas para reforzar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          'Se calculan con las preguntas falladas guardadas en tu cuaderno de errores.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        weakTopicsAsync.when(
          data: (topics) => topics.isEmpty
              ? const Card(
                  child: ListTile(
                    leading: Icon(Icons.verified_rounded),
                    title: Text('No hay temas pendientes en el cuaderno'),
                  ),
                )
              : Column(
                  children: [
                    for (final topic in topics)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.school_outlined),
                            title: Text(topic.subtopic),
                            subtitle: Text(
                              '${topic.theme} · ${topic.area.label}',
                            ),
                            trailing: Text(
                              '${topic.failedQuestions} ${topic.failedQuestions == 1 ? 'error' : 'errores'}',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('No pudimos cargar los temas por reforzar'),
              subtitle: Text('Tu resultado general sí quedó guardado.'),
            ),
          ),
        ),
      ],
    );
  }
}

class _FactCard extends StatelessWidget {
  const _FactCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _DiagnosticError extends StatelessWidget {
  const _DiagnosticError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Intentar nuevamente'),
          ),
        ],
      ),
    ),
  );
}

String _messageFor(Object error) => error is ApiError
    ? error.message
    : 'No pudimos completar la operación académica.';

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
