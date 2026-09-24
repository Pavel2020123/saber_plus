import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
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
              'Disponible por ahora solo en la sesión de demostración de estudiante. La conexión para cuentas reales está pendiente; no se simularán resultados reales.',
            ),
          ),
        ),
      );
    }
    return _ShieldGame(key: ObjectKey(repository), repository: repository);
  }
}

class _ShieldGame extends StatefulWidget {
  const _ShieldGame({super.key, required this.repository});
  final KnowledgeShieldRepository repository;
  @override
  State<_ShieldGame> createState() => _ShieldGameState();
}

class _ShieldGameState extends State<_ShieldGame> {
  final _scroll = ScrollController();
  late KnowledgeShieldAttempt? _attempt = widget.repository.current;
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
    Future<KnowledgeShieldAttempt> Function() action, {
    bool feedback = false,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await action();
      if (!mounted) return;
      setState(() {
        _attempt = result;
        _feedback = feedback;
        _pending = null;
        _selected = null;
      });
      _top();
    } on Object catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiError
              ? error.message
              : 'No se pudo confirmar. Reintenta el mismo envío.',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Abandonar la defensa?'),
        content: const Text(
          'La partida quedará cerrada. Si solo sales de la pantalla, podrás retomarla mientras no cierres la app ni cambies de cuenta.',
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
    if (mounted && confirmed == true) {
      await _perform(() => widget.repository.abandon(_attempt!.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt;
    final progress = attempt?.progress;
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
            const Text(
              'DEMOSTRACIÓN · Sin XP ni cambios en tu diagnóstico',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Preguntas de ejemplo que pueden repetirse. Avance solo en memoria: se pierde al cerrar la app o cambiar de cuenta. Arte, animaciones y audios pendientes.',
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (attempt == null) ...[
              Text(
                'Protege la biblioteca con Sabi',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Reglas de prueba: 3 rondas de 4 preguntas. Empiezas con 3 puntos de escudo. Un acierto repara 1 (máximo 3); un error quita 1. Al terminar cada ronda, un ataque de tinta quita otro punto. Si resistes con escudo, recuperas una página. Llegar a 0 termina la defensa. Supera las 3 rondas para ganar. Sin cronómetro.',
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
                    : (value) => setState(() => _area = value!),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const Key('shield-start'),
                onPressed: _busy
                    ? null
                    : () => _perform(() => widget.repository.start(_area)),
                child: const Text('Proteger biblioteca'),
              ),
            ] else ...[
              Text(
                attempt.area.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  'Escudo: ${progress!.shield}/3 · Páginas recuperadas: ${progress.pages}/3',
                  key: const Key('shield-progress'),
                ),
              ),
              LinearProgressIndicator(
                value: progress.shield / KnowledgeShieldProgress.maximumShield,
                semanticsLabel:
                    'Resistencia del escudo: ${progress.shield} de 3 puntos',
              ),
              const SizedBox(height: 12),
              Text(
                'Respondidas: ${progress.answered}/12 · Aciertos: ${progress.correct} · Errores: ${progress.mistakes}',
              ),
              const SizedBox(height: 16),
              if (attempt.finished) ...[
                Text(
                  attempt.abandoned
                      ? 'Defensa abandonada'
                      : progress.won
                      ? '¡Protegiste la biblioteca!'
                      : 'El escudo se agotó',
                  key: const Key('shield-result'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'Recuperaste ${progress.pages} de 3 páginas en esta demostración. No se otorgan XP, insignias ni certificados.',
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('shield-restart'),
                  onPressed: _busy
                      ? null
                      : () {
                          setState(() {
                            _attempt = null;
                            _feedback = false;
                            _selected = null;
                            _pending = null;
                            _error = null;
                          });
                          _top();
                        },
                  child: const Text('Nueva defensa'),
                ),
              ] else if (_feedback) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    attempt.lastCorrect == true
                        ? '¡Respuesta correcta! Escudo reparado hasta un máximo de 3.'
                        : 'La tinta dañó el escudo: −1 punto.',
                    key: const Key('shield-feedback'),
                  ),
                ),
                if (progress.roundEnded)
                  Text(
                    'Ronda ${progress.answered ~/ KnowledgeShieldProgress.questionsPerRound} superada. Resististe el ataque de tinta (−1) y recuperaste una página.',
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('shield-next'),
                  onPressed: () {
                    setState(() => _feedback = false);
                    _top();
                  },
                  child: Text(
                    progress.roundEnded
                        ? 'Comenzar siguiente ronda'
                        : 'Siguiente pregunta',
                  ),
                ),
              ] else ...[
                Text(
                  'Ronda ${progress.round}/3 · Pregunta ${progress.answered % KnowledgeShieldProgress.questionsPerRound + 1}/4',
                ),
                const SizedBox(height: 12),
                Text(
                  attempt.question!.statement,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                for (final option in attempt.question!.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Semantics(
                      selected: _selected == option.id,
                      child: OutlinedButton(
                        key: ValueKey('shield-option-${option.id}'),
                        onPressed: _busy || _pending != null
                            ? null
                            : () => setState(() => _selected = option.id),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
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
              ],
            ],
          ],
        ),
      ),
    );
  }
}
