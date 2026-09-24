import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/config/resource_url.dart';
import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
import '../../../practice/domain/practice_models.dart';
import '../../../study/presentation/study_providers.dart';
import '../../trivia_rush/data/remote_trivia_rush_repository.dart';
import '../domain/knowledge_shield_models.dart';
import 'knowledge_shield_providers.dart';

class KnowledgeShieldPage extends ConsumerWidget {
  const KnowledgeShieldPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(knowledgeShieldRepositoryProvider);
    if (repository == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Escudo del conocimiento')),
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
    return _ShieldGame(key: ObjectKey(repository), repository: repository);
  }
}

class _ShieldGame extends ConsumerStatefulWidget {
  const _ShieldGame({super.key, required this.repository});
  final KnowledgeShieldRepository repository;
  @override
  ConsumerState<_ShieldGame> createState() => _ShieldGameState();
}

class _ShieldGameState extends ConsumerState<_ShieldGame> {
  final _scroll = ScrollController();
  late KnowledgeShieldAttempt? _attempt = widget.repository.current;
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
              : 'No se pudo recuperar la defensa. Reintenta la sincronización.',
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
    Future<KnowledgeShieldAttempt> Function() action, {
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
              : 'No se pudo completar la operación. Reintenta; el fallo no cuenta como respuesta incorrecta.',
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
    if (_busy || _attempt == null || _attempt!.finished || _pending != null) {
      return;
    }
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Abandonar la defensa?'),
        content: Text(
          widget.repository.isDemo
              ? 'La defensa quedará cerrada. Si solo sales de esta pantalla, puedes retomarla mientras no cierres la app ni cambies de cuenta.'
              : 'La defensa quedará cerrada. Puedes salir sin abandonarla y retomarla durante 24 horas desde su inicio.',
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
        title: const Text('Escudo del conocimiento'),
        actions: [
          if (attempt != null && !attempt.finished)
            IconButton(
              tooltip: 'Abandonar defensa',
              onPressed: _busy || _pending != null ? null : _abandon,
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
                  ? 'Ejemplos que pueden repetirse. La defensa queda en memoria al salir de esta pantalla; se pierde al cerrar la app o cambiar de cuenta. Arte y animaciones pendientes.'
                  : 'El servidor confirma tu avance. Necesitas conexión y 12 preguntas publicadas para los filtros elegidos. Puedes retomar la defensa durante 24 horas desde su inicio.',
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (!widget.repository.isDemo)
              TextButton.icon(
                key: const Key('shield-sync'),
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
              _ShieldStatus(progress: attempt.progress),
              const SizedBox(height: 12),
              Text(
                'Respondidas: ${attempt.progress.answered}/${KnowledgeShieldProgress.questionLimit} · Errores: ${attempt.progress.mistakes}',
              ),
              const SizedBox(height: 16),
              if (attempt.finished)
                ..._result(attempt)
              else if (_feedback) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    (attempt.lastCorrect == true
                            ? '¡Respuesta correcta! Escudo reparado hasta un máximo de 3.'
                            : 'La tinta dañó el escudo: −1 punto.') +
                        (attempt.progress.roundEnded
                            ? ' Ronda superada: resististe el ataque de tinta (−1) y recuperaste una página.'
                            : ''),
                    key: const Key('shield-feedback'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('shield-next'),
                  onPressed: () {
                    setState(() => _feedback = false);
                    _top();
                  },
                  child: Text(
                    attempt.progress.roundEnded
                        ? 'Comenzar siguiente ronda'
                        : 'Siguiente pregunta',
                  ),
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
      'Protege la biblioteca con Sabi',
      style: Theme.of(context).textTheme.headlineSmall,
    ),
    const SizedBox(height: 12),
    const Text(
      'Reglas de prueba: 3 rondas de 4 preguntas. Escudo inicial y máximo: 3. Un acierto repara 1; un error quita 1. Al cerrar cada ronda, el ataque de tinta quita otro punto. Si resistes, recuperas una página. Llegar a 0 termina la defensa. Supera las tres rondas para ganar. Sin cronómetro.',
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
      key: const Key('shield-start'),
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
      child: Text(_busy ? 'Preparando…' : 'Proteger biblioteca'),
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

  List<Widget> _question(KnowledgeShieldAttempt attempt) {
    final q = attempt.question!;
    return [
      Text(
        'Ronda ${attempt.progress.round}/3 · Pregunta ${attempt.progress.answered % KnowledgeShieldProgress.questionsPerRound + 1}/4',
      ),
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
              key: ValueKey('shield-option-${option.id}'),
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
        key: const Key('shield-answer'),
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

  Widget _image(String url, String label) => _KnowledgeShieldImage(
    key: ValueKey('$label-$url'),
    url: resolveResourceUrl(ref.read(appConfigProvider), url),
    label: label,
    allowHttp: ref.read(appConfigProvider).environment == AppEnvironment.dev,
  );

  List<Widget> _result(KnowledgeShieldAttempt attempt) => [
    Semantics(
      liveRegion: true,
      child: Text(
        attempt.status == 'EXPIRADO'
            ? 'La defensa venció'
            : attempt.abandoned
            ? 'Defensa abandonada'
            : attempt.progress.won
            ? '¡Protegiste la biblioteca!'
            : 'El escudo se agotó',
        key: const Key('shield-result'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ),
    const SizedBox(height: 12),
    Text(
      'Recuperaste ${attempt.progress.pages} de 3 páginas. No se otorgan XP, insignias ni certificados.',
    ),
    const Text(
      'Este resultado corresponde solo a esta partida; no determina tus falencias académicas.',
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('shield-restart'),
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
      child: const Text('Nueva defensa'),
    ),
  ];
}

class _KnowledgeShieldImage extends StatefulWidget {
  const _KnowledgeShieldImage({
    super.key,
    required this.url,
    required this.label,
    required this.allowHttp,
  });
  final String url;
  final String label;
  final bool allowHttp;
  @override
  State<_KnowledgeShieldImage> createState() => _KnowledgeShieldImageState();
}

class _KnowledgeShieldImageState extends State<_KnowledgeShieldImage> {
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

/// Static status until the final animation stage.
class _ShieldStatus extends StatelessWidget {
  const _ShieldStatus({required this.progress});
  final KnowledgeShieldProgress progress;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        liveRegion: true,
        child: Text(
          'Escudo: ${progress.shield}/3 · Páginas recuperadas: ${progress.pages}/3',
          key: const Key('shield-progress'),
        ),
      ),
      LinearProgressIndicator(
        value: progress.shield / KnowledgeShieldProgress.maximumShield,
        semanticsLabel:
            'Resistencia del escudo: ${progress.shield} de 3 puntos',
      ),
    ],
  );
}
