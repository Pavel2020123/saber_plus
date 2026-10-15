import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../auth/presentation/session_controller.dart';
import '../domain/vocational_orientation.dart';
import 'vocational_orientation_providers.dart';

class VocationalOrientationPage extends ConsumerStatefulWidget {
  const VocationalOrientationPage({super.key});

  static final programsUri = Uri.parse(
    'https://hecaa.mineducacion.gov.co/consultaspublicas/programas',
  );

  @override
  ConsumerState<VocationalOrientationPage> createState() =>
      _VocationalOrientationPageState();
}

class _VocationalOrientationPageState
    extends ConsumerState<VocationalOrientationPage> {
  VocationalQuestionnaire? _questionnaire;
  VocationalAttempt? _attempt;
  final _history = <VocationalAttempt>[];
  int _historyTotal = 0;
  int _historyPage = 0;
  int _questionIndex = 0;
  int _generation = 0;
  bool _loading = true;
  bool _busy = false;
  bool _inQuestions = false;
  bool _showResult = false;
  bool _showHistory = false;
  String? _loadError;
  String? _actionError;
  String? _pendingQuestionId;
  VocationalAnswer? _pendingAnswer;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  void _resetForAccount() {
    _generation++;
    setState(() {
      _questionnaire = null;
      _attempt = null;
      _history.clear();
      _historyPage = 0;
      _historyTotal = 0;
      _inQuestions = false;
      _showResult = false;
      _showHistory = false;
      _pendingQuestionId = null;
      _pendingAnswer = null;
      _actionError = null;
      _loadError = null;
      _busy = false;
      _loading = true;
    });
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final generation = _generation;
    final user = ref.read(sessionControllerProvider).user;
    if (user == null || user.isDemo) {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
      return;
    }
    setState(() {
      _loading = true;
      _loadError = null;
      _actionError = null;
      _inQuestions = false;
      _showResult = false;
      _showHistory = false;
    });
    try {
      final repository = ref.read(vocationalOrientationRepositoryProvider);
      final questionnaire = await repository.questionnaire();
      final attempt = await repository.current();
      if (!mounted || generation != _generation) return;
      setState(() {
        _questionnaire = questionnaire;
        _attempt = attempt;
        _pendingQuestionId = null;
        _pendingAnswer = null;
        _questionIndex = 0;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _loadError = _errorText(error);
      });
    }
  }

  Future<void> _start() async {
    final questionnaire = _questionnaire;
    if (_busy || questionnaire == null) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      final attempt = await ref
          .read(vocationalOrientationRepositoryProvider)
          .start();
      if (!mounted || generation != _generation) return;
      setState(() {
        _attempt = attempt;
        _questionIndex = _firstUnansweredIndex(questionnaire, attempt);
        _inQuestions = true;
        _showResult = false;
        _showHistory = false;
      });
    } on Object catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _actionError = _errorText(error));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _save(String questionId, VocationalAnswer answer) async {
    if (_busy || _attempt == null || _attempt!.completed) return;
    final generation = _generation;
    final attemptId = _attempt!.id;
    setState(() {
      _busy = true;
      _pendingQuestionId = questionId;
      _pendingAnswer = answer;
      _actionError = null;
    });
    try {
      final saved = await ref
          .read(vocationalOrientationRepositoryProvider)
          .saveAnswer(attemptId, questionId, answer);
      if (!mounted || generation != _generation || _attempt?.id != attemptId) {
        return;
      }
      if (saved.id != attemptId ||
          saved.completed ||
          saved.answers[questionId] != answer) {
        throw const FormatException('Guardado OV-1 incompatible.');
      }
      setState(() {
        _attempt = saved;
        _pendingQuestionId = null;
        _pendingAnswer = null;
      });
    } on Object catch (error) {
      if (mounted && generation == _generation && _attempt?.id == attemptId) {
        setState(
          () => _actionError =
              'No se guardó esta respuesta. ${_errorText(error)} Reintenta antes de continuar.',
        );
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    if (_busy || _attempt == null || _pendingQuestionId != null) return;
    final generation = _generation;
    final attemptId = _attempt!.id;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      final completed = await ref
          .read(vocationalOrientationRepositoryProvider)
          .finish(attemptId);
      if (!mounted || generation != _generation || _attempt?.id != attemptId) {
        return;
      }
      if (!completed.completed ||
          completed.result == null ||
          completed.id != attemptId) {
        throw const FormatException('Finalización OV-1 incompatible.');
      }
      setState(() {
        _attempt = completed;
        _inQuestions = false;
        _showResult = true;
      });
    } on Object catch (error) {
      if (mounted && generation == _generation && _attempt?.id == attemptId) {
        setState(
          () => _actionError =
              error is ApiError && error.code == 'COBERTURA_INSUFICIENTE'
              ? 'Aún faltan respuestas numéricas suficientes. Puedes volver, completar o corregir y finalizar de nuevo.'
              : _errorText(error),
        );
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _openHistory() async {
    if (_busy) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      final page = await ref
          .read(vocationalOrientationRepositoryProvider)
          .history(1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _history
          ..clear()
          ..addAll(page.attempts);
        _historyPage = 1;
        _historyTotal = page.total;
        _showHistory = true;
        _inQuestions = false;
        _showResult = false;
      });
    } on Object catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _actionError = _errorText(error));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _moreHistory() async {
    if (_busy || _history.length >= _historyTotal) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      final page = await ref
          .read(vocationalOrientationRepositoryProvider)
          .history(_historyPage + 1);
      if (!mounted || generation != _generation) return;
      if (page.page != _historyPage + 1) {
        throw const FormatException('Página OV-1 incompatible.');
      }
      setState(() {
        _history.addAll(page.attempts);
        _historyPage = page.page;
        _historyTotal = page.total;
      });
    } on Object catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _actionError = _errorText(error));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _openAttempt(String id) async {
    final questionnaire = _questionnaire;
    if (_busy || questionnaire == null) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      final attempt = await ref
          .read(vocationalOrientationRepositoryProvider)
          .getAttempt(id);
      if (!mounted || generation != _generation) return;
      if (attempt.id != id) {
        throw const FormatException('Intento OV-1 incompatible.');
      }
      setState(() {
        _attempt = attempt;
        _questionIndex = _firstUnansweredIndex(questionnaire, attempt);
        _showHistory = false;
        _showResult = attempt.completed;
        _inQuestions = !attempt.completed;
      });
    } on Object catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _actionError = _errorText(error));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _delete(String id) async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar exploración'),
        content: const Text(
          'Se eliminarán este intento, sus respuestas y su resultado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await ref.read(vocationalOrientationRepositoryProvider).deleteAttempt(id);
      if (!mounted || generation != _generation) return;
      if (_attempt?.id == id) _attempt = null;
      final page = await ref
          .read(vocationalOrientationRepositoryProvider)
          .history(1);
      if (!mounted || generation != _generation) return;
      setState(() {
        _history
          ..clear()
          ..addAll(page.attempts);
        _historyPage = 1;
        _historyTotal = page.total;
      });
    } on Object catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _actionError = _errorText(error));
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _openPrograms() async {
    var opened = false;
    try {
      opened = await ref.read(vocationalOfficialLinkOpenerProvider)(
        VocationalOrientationPage.programsUri,
      );
    } on Object {
      opened = false;
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos abrir la consulta oficial.')),
      );
    }
  }

  static String _errorText(Object error) => error is ApiError
      ? error.message
      : 'No pudimos completar la operación. Intenta nuevamente.';

  static int _firstUnansweredIndex(
    VocationalQuestionnaire questionnaire,
    VocationalAttempt attempt,
  ) {
    final first = questionnaire.questions.indexWhere(
      (question) => !attempt.answers.containsKey(question.id),
    );
    return first < 0 ? questionnaire.questions.length - 1 : first;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      sessionControllerProvider.select((s) => (s.user?.id, s.user?.isDemo)),
      (previous, next) {
        if (previous != next) _resetForAccount();
      },
    );
    final demo = ref.watch(sessionControllerProvider).user?.isDemo == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Explora tus intereses')),
      body: demo
          ? const _Notice(
              key: Key('vocational-demo-unavailable'),
              text:
                  'Esta exploración privada necesita una cuenta de estudiante. La demostración no guarda respuestas ni crea resultados.',
            )
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _Notice(
              text: _loadError!,
              announce: true,
              action: FilledButton(
                onPressed: _load,
                child: const Text('Reintentar'),
              ),
            )
          : _showHistory
          ? _historyContent(context)
          : _showResult && _attempt?.result != null
          ? _resultContent(context, _attempt!.result!)
          : _inQuestions && _attempt != null && _questionnaire != null
          ? _questionContent(context, _questionnaire!, _attempt!)
          : _introContent(context),
    );
  }

  Widget _introContent(BuildContext context) => ListView(
    key: const Key('vocational-intro'),
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Un espacio para reconocer lo que te interesa',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      const Text(
        'Responderás 30 preguntas sobre actividades que te interesan. Toma aproximadamente 5–8 minutos. Puedes guardar y continuar después.',
      ),
      const SizedBox(height: 16),
      const Text(
        'Son intereses declarados: no es un diagnóstico psicológico, no mide aptitud ni garantiza admisión. Tu resultado es privado.',
      ),
      const SizedBox(height: 22),
      FilledButton(
        key: const Key('vocational-start'),
        onPressed: _busy ? null : _start,
        child: Text(_attempt == null ? 'Comenzar' : 'Continuar'),
      ),
      const SizedBox(height: 10),
      TextButton(
        key: const Key('vocational-open-history'),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: _busy ? null : _openHistory,
        child: const Text('Ver mis exploraciones anteriores'),
      ),
      if (_busy) const Center(child: CircularProgressIndicator()),
      if (_actionError != null) _Notice(text: _actionError!, announce: true),
    ],
  );

  Widget _questionContent(
    BuildContext context,
    VocationalQuestionnaire questionnaire,
    VocationalAttempt attempt,
  ) {
    final question = questionnaire.questions[_questionIndex];
    final pending = _pendingQuestionId == question.id;
    final selected = attempt.answers[question.id];
    return ListView(
      key: const Key('vocational-questionnaire'),
      padding: const EdgeInsets.all(20),
      children: [
        Semantics(
          label:
              'Pregunta ${_questionIndex + 1} de ${questionnaire.questions.length}',
          excludeSemantics: true,
          child: Text(
            'Pregunta ${_questionIndex + 1} de ${questionnaire.questions.length}',
            key: const Key('vocational-progress'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: LinearProgressIndicator(
            value: (_questionIndex + 1) / questionnaire.questions.length,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          question.text,
          key: Key('vocational-question-${question.id}'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        for (final answer in VocationalAnswer.values)
          Semantics(
            key: Key('vocational-answer-semantics-${answer.name}'),
            label: answer.label,
            value: selected == answer
                ? 'Respuesta confirmada'
                : 'Sin confirmar',
            button: true,
            selected: selected == answer,
            enabled: !_busy,
            onTap: _busy ? null : () => _save(question.id, answer),
            child: ExcludeSemantics(
              child: Card(
                child: ListTile(
                  key: Key('vocational-answer-${answer.name}'),
                  title: Text(answer.label),
                  leading: Icon(
                    selected == answer
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  selected: selected == answer,
                  onTap: _busy ? null : () => _save(question.id, answer),
                ),
              ),
            ),
          ),
        if (pending && _pendingAnswer != null)
          Semantics(
            key: const Key('vocational-pending-announcement'),
            label: 'Pendiente de guardar: ${_pendingAnswer!.label}',
            liveRegion: true,
            excludeSemantics: true,
            child: Text('Pendiente de guardar: ${_pendingAnswer!.label}'),
          ),
        if (_busy) const Center(child: CircularProgressIndicator()),
        if (pending && _actionError != null)
          FilledButton.tonal(
            key: const Key('vocational-retry-save'),
            onPressed: _busy ? null : () => _save(question.id, _pendingAnswer!),
            child: const Text('Reintentar guardado'),
          ),
        if (_actionError != null) _Notice(text: _actionError!, announce: true),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const Key('vocational-previous'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed:
                  _busy || _pendingQuestionId != null || _questionIndex == 0
                  ? null
                  : () => setState(() => _questionIndex--),
              child: const Text('Anterior'),
            ),
            if (_questionIndex < questionnaire.questions.length - 1)
              FilledButton.tonal(
                key: const Key('vocational-next'),
                onPressed: _busy || _pendingQuestionId != null
                    ? null
                    : () => setState(() => _questionIndex++),
                child: const Text('Siguiente'),
              ),
            FilledButton(
              key: const Key('vocational-finish'),
              onPressed: _busy || _pendingQuestionId != null ? null : _finish,
              child: const Text('Ver resultado'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('vocational-exit'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: _busy ? null : _load,
          child: const Text('Salir y continuar después'),
        ),
      ],
    );
  }

  Widget _resultContent(BuildContext context, VocationalResult result) {
    final byId = {for (final family in result.families) family.id: family};
    return ListView(
      key: const Key('vocational-result'),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Tus intereses declarados',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Respuestas válidas: ${result.validCount} de ${result.totalQuestions}. Estas familias son opciones de exploración, no un diagnóstico ni una garantía.',
        ),
        const SizedBox(height: 14),
        for (final familyId in result.mainFamilies)
          Card(
            key: Key('vocational-family-$familyId'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    key: Key('vocational-family-heading-$familyId'),
                    container: true,
                    header: true,
                    label: vocationalFamilyNames[familyId]!,
                    excludeSemantics: true,
                    child: Text(
                      vocationalFamilyNames[familyId]!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Respondiste ${byId[familyId]!.validCount} de 5 preguntas de esta familia.',
                  ),
                  for (final question
                      in result.questions
                          .where(
                            (q) =>
                                q.family == familyId &&
                                {
                                  VocationalAnswer.quite,
                                  VocationalAnswer.much,
                                }.contains(result.answers[q.id]),
                          )
                          .take(2))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Marcaste interés en: ${question.text}'),
                    ),
                ],
              ),
            ),
          ),
        if (result.families.any(
          (family) => !result.mainFamilies.contains(family.id),
        )) ...[
          const SizedBox(height: 14),
          Text(
            'Otras familias del resultado',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final family in result.families.where(
            (family) => !result.mainFamilies.contains(family.id),
          ))
            ListTile(
              key: Key('vocational-other-family-${family.id}'),
              title: Text(vocationalFamilyNames[family.id]!),
              subtitle: Text(
                'Respondiste ${family.validCount} de ${family.totalQuestions} preguntas de esta familia.',
              ),
            ),
        ],
        const SizedBox(height: 18),
        Text(
          'Explora opciones de formación',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        const Text(
          'Puedes revisar vías técnicas, tecnológicas y universitarias. Aún falta revisar una correspondencia entre estas familias y carreras concretas; este enlace no cambia tu resultado.',
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('vocational-official-programs'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: _openPrograms,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Consultar programas oficiales'),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          key: const Key('vocational-repeat'),
          onPressed: _busy ? null : _start,
          child: const Text('Iniciar otra exploración de intereses'),
        ),
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: _busy ? null : _openHistory,
          child: const Text('Ver mi historial'),
        ),
        if (_actionError != null) _Notice(text: _actionError!, announce: true),
      ],
    );
  }

  Widget _historyContent(BuildContext context) => ListView(
    key: const Key('vocational-history'),
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Mis exploraciones',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text('$_historyTotal intentos guardados solo para tu cuenta.'),
      const SizedBox(height: 10),
      if (_history.isEmpty)
        const Text('Aún no tienes exploraciones guardadas.'),
      for (final attempt in _history)
        Card(
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  key: Key('vocational-history-semantics-${attempt.id}'),
                  label:
                      'Abrir exploración ${attempt.completed ? 'completada' : 'en progreso'} del ${attempt.startedAt.day}/${attempt.startedAt.month}/${attempt.startedAt.year}',
                  button: true,
                  enabled: !_busy,
                  onTap: _busy ? null : () => _openAttempt(attempt.id),
                  child: ExcludeSemantics(
                    child: ListTile(
                      key: Key('vocational-history-${attempt.id}'),
                      title: Text(
                        attempt.completed
                            ? 'Exploración completada'
                            : 'Exploración en progreso',
                      ),
                      subtitle: Text(
                        '${attempt.startedAt.day}/${attempt.startedAt.month}/${attempt.startedAt.year}',
                      ),
                      onTap: _busy ? null : () => _openAttempt(attempt.id),
                    ),
                  ),
                ),
              ),
              Semantics(
                key: Key('vocational-delete-semantics-${attempt.id}'),
                label:
                    'Eliminar exploración ${attempt.completed ? 'completada' : 'en progreso'} del ${attempt.startedAt.day}/${attempt.startedAt.month}/${attempt.startedAt.year}',
                button: true,
                enabled: !_busy,
                onTap: _busy ? null : () => _delete(attempt.id),
                child: ExcludeSemantics(
                  child: IconButton(
                    key: Key('vocational-delete-${attempt.id}'),
                    tooltip: 'Eliminar esta exploración',
                    onPressed: _busy ? null : () => _delete(attempt.id),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ),
            ],
          ),
        ),
      if (_history.length < _historyTotal)
        TextButton(
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: _busy ? null : _moreHistory,
          child: const Text('Ver más exploraciones'),
        ),
      if (_busy) const Center(child: CircularProgressIndicator()),
      if (_actionError != null) _Notice(text: _actionError!, announce: true),
      TextButton(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: _busy ? null : _load,
        child: const Text('Volver a la introducción'),
      ),
    ],
  );
}

class _Notice extends StatelessWidget {
  const _Notice({
    super.key,
    required this.text,
    this.action,
    this.announce = false,
  });
  final String text;
  final Widget? action;
  final bool announce;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (announce)
            Semantics(
              key: const Key('vocational-live-notice'),
              label: text,
              liveRegion: true,
              excludeSemantics: true,
              child: Text(text, textAlign: TextAlign.center),
            )
          else
            Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    ),
  );
}
