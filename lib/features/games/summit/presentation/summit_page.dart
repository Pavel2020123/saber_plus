import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/config/resource_url.dart';
import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';
import '../../../study/presentation/study_providers.dart';
import '../../trivia_rush/data/remote_trivia_rush_repository.dart';
import '../domain/summit_models.dart';
import 'summit_providers.dart';

class SummitPage extends ConsumerWidget {
  const SummitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(summitRepositoryProvider);
    if (repository == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Salto a la cima')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Este juego está disponible para estudiantes con sesión iniciada. No se cargarán datos de prueba en cuentas reales.',
          ),
        ),
      );
    }
    return _SummitGame(key: ObjectKey(repository), repository: repository);
  }
}

class _SummitGame extends ConsumerStatefulWidget {
  const _SummitGame({super.key, required this.repository});
  final SummitRepository repository;
  @override
  ConsumerState<_SummitGame> createState() => _SummitGameState();
}

class _SummitGameState extends ConsumerState<_SummitGame> {
  final _scroll = ScrollController();
  late SummitAttempt? _attempt = widget.repository.current;
  AcademicArea _area = AcademicArea.mathematics;
  String? _selected;
  String? _error;
  bool _busy = false;
  late bool _ready = widget.repository.isDemo;
  String? _themeId;
  String? _subtopicId;
  PracticeDifficulty? _difficulty;
  late bool _feedback = _attempt?.lastCorrect != null;
  ({String question, String answer, String key})? _pending;

  @override
  void initState() {
    super.initState();
    if (!widget.repository.isDemo) _restore();
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.repository.restore();
      if (!mounted) return;
      final pending = widget.repository.pending;
      setState(() {
        _ready = true;
        _attempt = result;
        _pending = pending == null
            ? null
            : (
                question: pending.questionId,
                answer: pending.answerId,
                key: pending.requestKey,
              );
        _selected = pending?.answerId;
        _feedback = pending == null && result?.lastCorrect != null;
      });
      _top();
    } on Object catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _abandon() async {
    if (_busy || _attempt == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Abandonar el ascenso?'),
        content: const Text(
          'La partida quedará cerrada y no podrás continuarla. Puedes salir de esta pantalla sin abandonarla para retomarla después.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar jugando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.repository.abandon(_attempt!.id);
      if (!mounted) return;
      setState(() {
        _attempt = result;
        _pending = null;
        _selected = null;
        _feedback = false;
      });
      _top();
    } on Object catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _top() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
  });

  String _message(Object e) => e is ApiError
      ? e.message
      : 'No se pudo completar la operación. Intenta de nuevo.';

  Future<void> _start() async {
    if (_busy || !_ready) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final attempt = await widget.repository.start(
        _area,
        themeId: _themeId,
        subtopicId: _subtopicId,
        difficulty: _difficulty,
      );
      if (!mounted) return;
      setState(() {
        _attempt = attempt;
        _feedback = false;
        _selected = null;
        _pending = null;
      });
      _top();
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _answer() async {
    final attempt = _attempt;
    if (_busy ||
        _feedback ||
        attempt == null ||
        attempt.finished ||
        _selected == null) {
      return;
    }
    _pending ??= (
      question: attempt.question!.id,
      answer: _selected!,
      key: createTriviaIdempotencyKey(),
    );
    final pending = _pending!;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await widget.repository.answer(
        attemptId: attempt.id,
        questionId: pending.question,
        answerId: pending.answer,
        requestKey: pending.key,
      );
      if (!mounted) return;
      setState(() {
        _attempt = updated;
        _feedback = true;
        _pending = null;
        _selected = null;
      });
      _top();
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error =
              '${_message(error)} Reintenta el mismo envío; no se descontará otro escalón por el error de envío.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salto a la cima'),
        actions: [
          if (_attempt != null && !_attempt!.finished)
            IconButton(
              tooltip: 'Abandonar ascenso',
              onPressed: _busy ? null : _abandon,
              icon: const Icon(Icons.flag_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.repository.isDemo
                  ? 'DEMOSTRACIÓN · Sin XP ni cambios en tu diagnóstico'
                  : 'PARTIDA EN LÍNEA · Sin XP ni cambios en tu diagnóstico',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.repository.isDemo
                  ? 'Preguntas de ejemplo que pueden repetirse. La partida se conserva al volver a esta pantalla, pero se pierde al cerrar la app o cambiar de cuenta.'
                  : 'Tu avance se confirma en el servidor. Puedes retomarlo durante 24 horas desde el inicio. Necesitas conexión y 12 preguntas publicadas para los filtros elegidos.',
            ),
            if (_busy) const LinearProgressIndicator(),
            if (!widget.repository.isDemo)
              TextButton.icon(
                key: const Key('summit-sync'),
                onPressed: _busy ? null : _restore,
                icon: const Icon(Icons.sync),
                label: const Text('Recuperar / sincronizar partida'),
              ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (!_ready)
              const Text(
                'Primero debemos comprobar si tienes una partida guardada. Si falla la conexión, pulsa recuperar; no se iniciará una partida demo.',
              )
            else if (attempt == null)
              ..._setup()
            else ...[
              Text(
                attempt.area.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _SummitSteps(progress: attempt.progress),
              const SizedBox(height: 12),
              Text(
                'Respondidas: ${attempt.progress.answered}/${SummitProgress.questionLimit} · Aciertos: ${attempt.progress.correct} · Errores: ${attempt.progress.mistakes}',
              ),
              const SizedBox(height: 16),
              if (attempt.finished)
                ..._result(attempt)
              else if (_feedback) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    attempt.lastCorrect == true
                        ? '¡Acierto! Subes un escalón.'
                        : attempt.lastMovement == 0
                        ? 'Respuesta incorrecta. Sigues en la base.'
                        : 'Respuesta incorrecta. Bajas un escalón.',
                    key: const Key('summit-feedback'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('summit-next'),
                  onPressed: () {
                    setState(() => _feedback = false);
                    _top();
                  },
                  child: const Text('Siguiente pregunta'),
                ),
              ] else
                ..._question(attempt),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _setup() => [
    Text(
      'Llega al escalón ${SummitProgress.target}',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 8),
    const Text(
      'Acierto: subes 1. Error: bajas 1, sin bajar de cero. Tienes hasta 12 preguntas, sin cronómetro. Si alcanzas el escalón 5, ganas. No hay explicaciones interrumpiendo la partida.',
    ),
    const SizedBox(height: 20),
    DropdownButtonFormField<AcademicArea>(
      initialValue: _area,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Área'),
      items: [
        for (final area in AcademicArea.values)
          DropdownMenuItem(value: area, child: Text(area.label)),
      ],
      onChanged: _busy
          ? null
          : (value) => setState(() {
              _area = value!;
              _themeId = null;
              _subtopicId = null;
            }),
    ),
    if (!widget.repository.isDemo) ..._filters(),
    const SizedBox(height: 20),
    FilledButton(
      key: const Key('summit-start'),
      onPressed: _busy ? null : _start,
      child: Text(_busy ? 'Preparando…' : 'Comenzar ascenso'),
    ),
  ];

  List<Widget> _filters() {
    final catalog = ref.watch(studyCatalogProvider(_area));
    return [
      const SizedBox(height: 16),
      DropdownButtonFormField<PracticeDifficulty>(
        initialValue: _difficulty,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Dificultad'),
        items: [
          const DropdownMenuItem(value: null, child: Text('Todas')),
          for (final value in PracticeDifficulty.values)
            DropdownMenuItem(value: value, child: Text(value.label)),
        ],
        onChanged: _busy
            ? null
            : (value) => setState(() => _difficulty = value),
      ),
      catalog.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(12),
          child: Text('Cargando temas… Puedes jugar con el área completa.'),
        ),
        error: (error, stack) => TextButton(
          onPressed: () => ref.invalidate(studyCatalogProvider(_area)),
          child: const Text('No se cargaron los temas. Reintentar catálogo'),
        ),
        data: (data) {
          final theme = data.findTheme(_themeId ?? '');
          return Column(
            children: [
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(
                  'theme-${_area.name}-${data.themes.map((t) => t.id).join()}',
                ),
                initialValue: theme?.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tema'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos los temas'),
                  ),
                  for (final item in data.themes)
                    DropdownMenuItem(value: item.id, child: Text(item.name)),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _themeId = value;
                        _subtopicId = null;
                      }),
              ),
              if (theme != null) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('subtopic-${theme.id}'),
                  initialValue: theme.subtopics.any((s) => s.id == _subtopicId)
                      ? _subtopicId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Subtema'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos los subtemas'),
                    ),
                    for (final item in theme.subtopics)
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) => setState(() => _subtopicId = value),
                ),
              ],
            ],
          );
        },
      ),
    ];
  }

  List<Widget> _question(SummitAttempt attempt) {
    final question = attempt.question!;
    return [
      Text(
        'Pregunta ${attempt.progress.answered + 1} · ${question.themeName} · ${question.subtopicName}',
      ),
      const SizedBox(height: 12),
      if (question.caseContent case final content?) ...[
        Text(content.title, style: Theme.of(context).textTheme.titleMedium),
        Text(content.context),
        if (content.imageUrl case final url?) _image(url, 'Imagen del caso'),
        const SizedBox(height: 12),
      ],
      Text(question.statement, style: Theme.of(context).textTheme.titleLarge),
      if (question.imageUrl case final url?)
        _image(url, 'Imagen de la pregunta'),
      const SizedBox(height: 16),
      for (final option in question.options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Semantics(
            selected: _selected == option.id,
            child: OutlinedButton(
              key: ValueKey('summit-option-${option.id}'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(16),
                backgroundColor: _selected == option.id
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
              onPressed: _busy || _pending != null
                  ? null
                  : () => setState(() => _selected = option.id),
              child: Row(
                children: [
                  Icon(
                    _selected == option.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(option.text)),
                ],
              ),
            ),
          ),
        ),
      FilledButton(
        key: const Key('summit-answer'),
        onPressed: _busy || _selected == null ? null : _answer,
        child: Text(
          _busy
              ? 'Confirmando…'
              : _pending != null
              ? 'Reintentar envío'
              : 'Confirmar respuesta',
        ),
      ),
    ];
  }

  Widget _image(String url, String label) => _SummitImage(
    key: ValueKey('$label-$url'),
    url: resolveResourceUrl(ref.read(appConfigProvider), url),
    label: label,
    allowHttp: ref.read(appConfigProvider).environment == AppEnvironment.dev,
  );

  List<Widget> _result(SummitAttempt attempt) => [
    Semantics(
      liveRegion: true,
      child: Text(
        attempt.status == 'EXPIRADO'
            ? 'La partida venció'
            : attempt.status == 'ABANDONADO'
            ? 'Ascenso abandonado'
            : attempt.progress.won
            ? '¡Llegaste a la cima!'
            : 'Terminó el recorrido',
        key: const Key('summit-result'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ),
    const SizedBox(height: 8),
    Text(
      'Escalón final: ${attempt.progress.step}. Tu punto más alto: ${attempt.progress.peak}.',
    ),
    const Text(
      'Este resultado describe solo esta partida; no determina tus falencias académicas.',
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('summit-restart'),
      onPressed: () => setState(() {
        _area = attempt.area;
        _attempt = null;
        _feedback = false;
        _error = null;
        _pending = null;
        _selected = null;
        _themeId = null;
        _subtopicId = null;
      }),
      child: const Text('Preparar otra partida'),
    ),
  ];
}

class _SummitImage extends StatefulWidget {
  const _SummitImage({
    super.key,
    required this.url,
    required this.label,
    required this.allowHttp,
  });
  final String url;
  final String label;
  final bool allowHttp;
  @override
  State<_SummitImage> createState() => _SummitImageState();
}

class _SummitImageState extends State<_SummitImage> {
  int _retry = 0;
  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(widget.url);
    if (uri == null ||
        !(uri.scheme == 'https' ||
            (widget.allowHttp && uri.scheme == 'http')) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return const Text(
        'La imagen no tiene una dirección válida. No respondas sin su contexto.',
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Image.network(
        widget.url,
        key: ValueKey(_retry),
        fit: BoxFit.contain,
        semanticLabel: widget.label,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : const Text('Cargando imagen…'),
        errorBuilder: (context, error, stack) => Column(
          children: [
            Text(
              '${widget.label}: no se pudo cargar. Reintenta antes de responder; puedes salir y retomar la partida.',
            ),
            TextButton(
              onPressed: () async {
                await NetworkImage(widget.url).evict();
                if (mounted) setState(() => _retry++);
              },
              child: const Text('Reintentar imagen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummitSteps extends StatelessWidget {
  const _SummitSteps({required this.progress});
  final SummitProgress progress;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Escalón ${progress.step} de ${SummitProgress.target}',
    child: ExcludeSemantics(
      child: Column(
        children: [
          for (var step = SummitProgress.target; step >= 0; step--)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: step == progress.step
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    step == progress.step
                        ? Icons.person
                        : step == SummitProgress.target
                        ? Icons.flag
                        : Icons.remove,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${step == 0 ? 'Base' : 'Escalón $step'}${step == progress.step ? ' · Estás aquí' : ''}',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
