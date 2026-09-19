import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
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
              'Por ahora está disponible para estudiantes de demostración. Las cuentas reales necesitan el backend de este juego; no se cargarán preguntas demo en tu cuenta.',
            ),
          ),
        ),
      );
    }
    return _RescueGame(key: ObjectKey(repository), repository: repository);
  }
}

class _RescueGame extends StatefulWidget {
  const _RescueGame({super.key, required this.repository});
  final StarRescueRepository repository;
  @override
  State<_RescueGame> createState() => _RescueGameState();
}

class _RescueGameState extends State<_RescueGame> {
  final _scroll = ScrollController();
  late StarRescueAttempt? _attempt = widget.repository.current;
  late bool _feedback = _attempt?.lastCorrect != null;
  AcademicArea _area = AcademicArea.mathematics;
  String? _selected;
  String? _error;
  bool _busy = false;
  ({String question, String answer, String key})? _pending;
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
      key: '${attempt.id}:${attempt.question!.id}',
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
        content: const Text(
          'El rescate quedará cerrado. Si solo sales de esta pantalla, puedes retomarlo mientras no cierres la app ni cambies de cuenta.',
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
            const Text(
              'DEMOSTRACIÓN · Sin XP ni cambios en tu diagnóstico',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ejemplos que pueden repetirse. El rescate queda en memoria al salir de esta pantalla; se pierde al cerrar la app o cambiar de cuenta. Arte y animaciones pendientes.',
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
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
            if (attempt == null)
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
      onChanged: _busy ? null : (value) => setState(() => _area = value!),
    ),
    const SizedBox(height: 20),
    FilledButton(
      key: const Key('rescue-start'),
      onPressed: _busy
          ? null
          : () => _perform(() => widget.repository.start(_area)),
      child: Text(_busy ? 'Preparando…' : 'Comenzar rescate'),
    ),
  ];

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
        const SizedBox(height: 12),
      ],
      Text(q.statement, style: Theme.of(context).textTheme.titleLarge),
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

  List<Widget> _result(StarRescueAttempt attempt) => [
    Semantics(
      liveRegion: true,
      child: Text(
        attempt.abandoned
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
      'Este resultado corresponde solo a esta partida demo; no determina tus falencias académicas.',
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('rescue-restart'),
      onPressed: _busy
          ? null
          : () => setState(() {
              _area = attempt.area;
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
