import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
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
            'Disponible por ahora en la cuenta de demostración. La versión para cuentas reales necesita su validación en el backend. No se cargarán datos de prueba en tu cuenta.',
          ),
        ),
      );
    }
    return _SummitGame(key: ObjectKey(repository), repository: repository);
  }
}

class _SummitGame extends StatefulWidget {
  const _SummitGame({super.key, required this.repository});
  final SummitRepository repository;
  @override
  State<_SummitGame> createState() => _SummitGameState();
}

class _SummitGameState extends State<_SummitGame> {
  final _scroll = ScrollController();
  late SummitAttempt? _attempt = widget.repository.current;
  AcademicArea _area = AcademicArea.mathematics;
  String? _selected;
  String? _error;
  bool _busy = false;
  late bool _feedback = _attempt?.lastCorrect != null;
  ({String question, String answer, String key})? _pending;

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
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final attempt = await widget.repository.start(_area);
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
        attempt.progress.finished ||
        _selected == null) {
      return;
    }
    _pending ??= (
      question: attempt.question!.id,
      answer: _selected!,
      key: '${attempt.id}:${attempt.question!.id}',
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
      appBar: AppBar(title: const Text('Salto a la cima')),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'DEMOSTRACIÓN · Sin XP ni cambios en tu diagnóstico',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Preguntas de ejemplo que pueden repetirse. La partida se conserva al volver a esta pantalla, pero se pierde al cerrar la app o cambiar de cuenta.',
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
          if (attempt == null)
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
            if (attempt.progress.finished)
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
      onChanged: _busy ? null : (value) => setState(() => _area = value!),
    ),
    const SizedBox(height: 20),
    FilledButton(
      key: const Key('summit-start'),
      onPressed: _busy ? null : _start,
      child: Text(_busy ? 'Preparando…' : 'Comenzar ascenso'),
    ),
  ];

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
        const SizedBox(height: 12),
      ],
      Text(question.statement, style: Theme.of(context).textTheme.titleLarge),
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

  List<Widget> _result(SummitAttempt attempt) => [
    Semantics(
      liveRegion: true,
      child: Text(
        attempt.progress.won ? '¡Llegaste a la cima!' : 'Terminó el recorrido',
        key: const Key('summit-result'),
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    ),
    const SizedBox(height: 8),
    Text(
      'Escalón final: ${attempt.progress.step}. Tu punto más alto: ${attempt.progress.peak}.',
    ),
    const Text(
      'Este resultado describe solo esta partida de ejemplo; no determina tus falencias académicas.',
    ),
    const SizedBox(height: 16),
    FilledButton(
      key: const Key('summit-restart'),
      onPressed: () => setState(() {
        _area = attempt.area;
        _attempt = null;
        _feedback = false;
        _error = null;
      }),
      child: const Text('Preparar otra partida'),
    ),
  ];
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
