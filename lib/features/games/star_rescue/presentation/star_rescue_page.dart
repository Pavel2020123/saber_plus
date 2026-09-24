import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/config/resource_url.dart';
import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';
import '../../../study/presentation/study_providers.dart';
import '../../trivia_rush/data/remote_trivia_rush_repository.dart';
import '../domain/star_rescue_models.dart';
import 'star_rescue_providers.dart';

class StarRescuePage extends ConsumerWidget {
  const StarRescuePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(starRescueRepositoryProvider);
    if (repository == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rescate de estrellas')),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Este juego requiere una sesión de estudiante. Las cuentas reales nunca usarán preguntas demo como respaldo.',
            ),
          ),
        ),
      );
    }
    return _RescueGame(key: ObjectKey(repository), repository: repository);
  }
}

class _RescueGame extends ConsumerStatefulWidget {
  const _RescueGame({super.key, required this.repository});
  final StarRescueRepository repository;
  @override
  ConsumerState<_RescueGame> createState() => _RescueGameState();
}

class _RescueGameState extends ConsumerState<_RescueGame> {
  final _scroll = ScrollController();
  late StarRescueAttempt? _attempt = widget.repository.current;
  late bool _feedback = _attempt?.lastCorrect != null;
  AcademicArea _area = AcademicArea.mathematics;
  String? _selected;
  String? _error;
  bool _busy = false;
  late bool _ready = widget.repository.isDemo;
  String? _themeId;
  String? _subtopicId;
  PracticeDifficulty? _difficulty;
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
      if (mounted) {
        setState(
          () => _error = e is ApiError
              ? e.message
              : 'No se pudo recuperar el rescate. Reintenta la sincronización.',
        );
      }
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
  Future<void> _perform(
    Future<StarRescueAttempt> Function() action, {
    bool feedback = false,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final attempt = await action();
      if (!mounted) return;
      setState(() {
        _attempt = attempt;
        _feedback = feedback;
        _selected = null;
        _pending = null;
      });
      _top();
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => _error = e is ApiError
              ? e.message
              : 'No se pudo completar la operación. Reintenta; no perderás estrellas por este fallo.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _answer() {
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
    _perform(
      () => widget.repository.answer(
        attemptId: attempt.id,
        questionId: pending.question,
        answerId: pending.answer,
        requestKey: pending.key,
      ),
      feedback: true,
    );
  }

  Future<void> _abandon() async {
    if (_busy || _attempt == null || _attempt!.finished) return;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Abandonar el rescate?'),
        content: Text(
          widget.repository.isDemo
              ? 'El rescate quedará cerrado. Si solo sales de esta pantalla, puedes retomarlo mientras no cierres la app ni cambies de cuenta.'
              : 'El rescate quedará cerrado. Puedes salir sin abandonarlo y retomarlo durante 24 horas desde su inicio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir jugando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abandonar'),
          ),
        ],
      ),
    );
    if (mounted && yes == true) {
      await _perform(() => widget.repository.abandon(_attempt!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescate de estrellas'),
        actions: [
          if (attempt != null && !attempt.finished)
            IconButton(
              tooltip: 'Abandonar rescate',
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
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.repository.isDemo
                  ? 'Ejemplos que pueden repetirse. El rescate queda en memoria al salir de esta pantalla; se pierde al cerrar la app o cambiar de cuenta. Arte y animaciones pendientes.'
                  : 'El servidor confirma tu avance. Necesitas conexión y 10 preguntas publicadas para los filtros elegidos. Puedes retomar el rescate durante 24 horas desde su inicio.',
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (!widget.repository.isDemo)
              TextButton.icon(
                key: const Key('rescue-sync'),
                onPressed: _busy ? null : _restore,
                icon: const Icon(Icons.sync),
                label: const Text('Recuperar / sincronizar partida'),
              ),
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
                'Primero comprobaremos tu partida guardada. Si falla la conexión, pulsa recuperar; no se iniciará una demo.',
              )
            else if (attempt == null)
              ..._setup()
            else ...[
              Text(
                attempt.area.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _Constellations(progress: attempt.progress),
              const SizedBox(height: 12),
              Text(
                'Respondidas: ${attempt.progress.answered}/${StarRescueProgress.questionLimit} · Errores: ${attempt.progress.mistakes}',
              ),
              const SizedBox(height: 16),
              if (attempt.finished)
                ..._result(attempt)
              else if (_feedback) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    attempt.lastCorrect == true
                        ? '¡Liberaste una estrella!${attempt.progress.stars % StarRescueProgress.groupSize == 0 ? ' Completaste una constelación.' : ''}'
                        : 'La burbuja sigue esperando. Conservas tus estrellas; vamos con otra pregunta.',
                    key: const Key('rescue-feedback'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('rescue-next'),
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
      'Ayuda a Sabi a liberar las estrellas',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 12),
    const Text(
      'Reglas de prueba: cada acierto libera una estrella. Forma 2 constelaciones de 3 estrellas en hasta 10 preguntas. Un error consume la pregunta, pero no quita estrellas. Sin cronómetro.',
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
      key: const Key('rescue-start'),
      onPressed: _busy || !_ready
          ? null
          : () => _perform(
              () => widget.repository.start(
                _area,
                themeId: _themeId,
                subtopicId: _subtopicId,
                difficulty: _difficulty,
              ),
            ),
      child: Text(_busy ? 'Preparando…' : 'Comenzar rescate'),
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

  List<Widget> _question(StarRescueAttempt attempt) {
    final q = attempt.question!;
    return [
      Text(
        'Pregunta ${attempt.progress.answered + 1} · ${q.themeName} · ${q.subtopicName}',
      ),
      const SizedBox(height: 12),
      if (q.caseContent case final content?) ...[
        Text(content.title),
        Text(content.context),
        if (content.imageUrl case final url?) _image(url, 'Imagen del caso'),
        const SizedBox(height: 12),
      ],
      Text(q.statement, style: Theme.of(context).textTheme.titleLarge),
      if (q.imageUrl case final url?) _image(url, 'Imagen de la pregunta'),
      const SizedBox(height: 16),
      for (final option in q.options)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Semantics(
            selected: _selected == option.id,
            child: OutlinedButton(
              key: ValueKey('rescue-option-${option.id}'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(16),
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
        key: const Key('rescue-answer'),
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

  Widget _image(String url, String label) => _StarRescueImage(
    key: ValueKey('$label-$url'),
    url: resolveResourceUrl(ref.read(appConfigProvider), url),
    label: label,
    allowHttp: ref.read(appConfigProvider).environment == AppEnvironment.dev,
  );

  List<Widget> _result(StarRescueAttempt attempt) => [
    Semantics(
      liveRegion: true,
      child: Text(
        attempt.status == 'EXPIRADO'
            ? 'El rescate venció'
            : attempt.abandoned
            ? 'Rescate abandonado'
            : attempt.progress.won
            ? '¡Reconstruiste las dos constelaciones!'
            : 'Terminó el rescate',
        key: const Key('rescue-result'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ),
    const SizedBox(height: 12),
    Text(
      'Liberaste ${attempt.progress.stars} de 6 estrellas y completaste ${attempt.progress.constellations} de 2 constelaciones.',
    ),
    const Text(
      'Este resultado corresponde solo a esta partida; no determina tus falencias académicas.',
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('rescue-restart'),
      onPressed: _busy
          ? null
          : () => setState(() {
              _area = attempt.area;
              _themeId = null;
              _subtopicId = null;
              _attempt = null;
              _feedback = false;
              _selected = null;
              _pending = null;
              _error = null;
            }),
      child: const Text('Preparar otro rescate'),
    ),
  ];
}

class _StarRescueImage extends StatefulWidget {
  const _StarRescueImage({
    super.key,
    required this.url,
    required this.label,
    required this.allowHttp,
  });
  final String url;
  final String label;
  final bool allowHttp;
  @override
  State<_StarRescueImage> createState() => _StarRescueImageState();
}

class _StarRescueImageState extends State<_StarRescueImage> {
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

/// Static and labeled placeholders. No asset generation or new animations.
class _Constellations extends StatelessWidget {
  const _Constellations({required this.progress});
  final StarRescueProgress progress;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Estrellas liberadas: ${progress.stars}/6',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      for (var group = 0; group < 2; group++)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Constelación ${group + 1} · ${progress.constellations > group ? 'Completa' : 'En rescate'}',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (var index = group * 3; index < (group + 1) * 3; index++)
                    Semantics(
                      label:
                          'Estrella ${index + 1}: ${index < progress.stars ? 'liberada' : 'en burbuja'}',
                      child: ExcludeSemantics(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            color: index < progress.stars
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                          ),
                          child: Icon(
                            index < progress.stars
                                ? Icons.star
                                : Icons.star_outline,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
    ],
  );
}
