import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/config/resource_url.dart';
import '../../../../core/feedback/game_audio_feedback.dart';
import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
import '../../../auth/presentation/session_controller.dart';
import '../../../practice/domain/practice_models.dart';
import '../../../study/presentation/study_providers.dart';
import '../../trivia_rush/data/remote_trivia_rush_repository.dart';
import '../data/guardian_repository.dart';
import '../domain/guardian_models.dart';
import 'guardian_scene.dart';

class GuardianPage extends ConsumerWidget {
  const GuardianPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(guardianRepositoryProvider);
    // Cambiar de cuenta descarta el estado visual y cualquier envío pendiente.
    return _GuardianGame(key: ObjectKey(repository), repository: repository);
  }
}

class _GuardianGame extends ConsumerStatefulWidget {
  const _GuardianGame({super.key, required this.repository});
  final GuardianRepository repository;
  @override
  ConsumerState<_GuardianGame> createState() => _GuardianGameState();
}

class _GuardianGameState extends ConsumerState<_GuardianGame> {
  final _scroll = ScrollController();
  GuardianAttempt? _attempt;
  GuardianReview? _feedback;
  AcademicArea _area = AcademicArea.mathematics;
  PracticeDifficulty _difficulty = PracticeDifficulty.medium;
  String? _subtopic;
  String? _selected;
  String? _error;
  bool _loading = true;
  bool _busy = false;
  // Se conserva en errores de red: un reintento nunca crea otra respuesta.
  ({String question, String answer, String key})? _pending;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _top() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final attempt = await widget.repository.active();
      if (!mounted) return;
      setState(() {
        _attempt = attempt;
        _loading = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = _message(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final attempt = await widget.repository.start(
        GuardianConfig(
          area: _area,
          difficulty: _difficulty,
          subtopicId: _subtopic,
        ),
      );
      if (!mounted) return;
      setState(() {
        _attempt = attempt;
        _selected = null;
        _feedback = null;
      });
      _top();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = _message(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _answer() async {
    final attempt = _attempt;
    if (_busy || attempt == null || !attempt.isActive || _selected == null) {
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
      final result = await widget.repository.answer(
        id: attempt.id,
        questionId: pending.question,
        answerId: pending.answer,
        idempotencyKey: pending.key,
      );
      if (mounted) _accept(result, submittedQuestion: pending.question);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error =
              '${_message(error)} Tu envío se conserva. Reintenta o sincroniza antes de continuar.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _accept(GuardianAttempt result, {String? submittedQuestion}) {
    final matching = result.review.where(
      (r) => r.question.id == submittedQuestion,
    );
    final feedback = matching.isEmpty ? null : matching.first;
    setState(() {
      _attempt = result;
      _feedback = feedback;
      _pending = null;
      _selected = null;
      _error = null;
    });
    _top();
    if (feedback != null) {
      unawaited(
        ref.read(gameAudioFeedbackProvider).play(switch (result.status) {
          GuardianStatus.victory => GameSound.matchVictory,
          GuardianStatus.defeat => GameSound.matchDefeat,
          _ =>
            feedback.isCorrect
                ? GameSound.triviaCorrect
                : GameSound.triviaWrong,
        }),
      );
    }
  }

  Future<void> _synchronize() async {
    if (_busy || _attempt == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.repository.get(_attempt!.id);
      if (!mounted) return;
      final pending = _pending;
      if (pending != null &&
          result.isActive &&
          result.question?.id == pending.question) {
        // No se confirmó todavía. Mantener la clave y la selección originales.
        setState(() {
          _attempt = result;
          _error =
              'La respuesta aún no está confirmada. Pulsa Reintentar envío.';
        });
      } else {
        _accept(result, submittedQuestion: pending?.question);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = _message(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _abandon() async {
    if (_busy || _attempt == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar este desafío?'),
        content: const Text(
          'Se conservarán las respuestas confirmadas, pero no podrás continuar esta partida. Para retomarla después, simplemente vuelve atrás sin abandonarla.',
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
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.repository.abandon(_attempt!.id);
      if (mounted) _accept(result);
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = _message(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt;
    final demo = ref.watch(sessionControllerProvider).user?.isDemo ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desafío del guardián'),
        actions: [
          if (attempt?.isActive == true)
            IconButton(
              tooltip: 'Abandonar desafío',
              onPressed: _busy ? null : _abandon,
              icon: const Icon(Icons.flag_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(20),
                children: [
                  if (_error != null) ...[
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (attempt == null)
                      TextButton(
                        onPressed: _busy ? null : _load,
                        child: const Text('Buscar partida guardada'),
                      ),
                    if (attempt != null)
                      TextButton(
                        onPressed: _busy ? null : _synchronize,
                        child: const Text('Sincronizar partida'),
                      ),
                    const SizedBox(height: 12),
                  ],
                  if (demo)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Modo demo · ejemplos repetidos, sin progreso real. La dificultad y el subtema se aplican al banco real.',
                      ),
                    ),
                  GuardianScene(
                    energy: attempt?.energy ?? 6,
                    shield: attempt?.shield ?? 3,
                    turn: attempt?.review.length ?? 0,
                    lastCorrect: attempt?.review.lastOrNull?.isCorrect,
                    victory: attempt?.status == GuardianStatus.victory,
                  ),
                  const SizedBox(height: 20),
                  if (attempt == null)
                    ..._setup()
                  else ...[
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(Icons.auto_awesome, size: 18),
                          label: Text('${attempt.correct}/6 aciertos'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.shield_outlined, size: 18),
                          label: Text('${attempt.shield}/3 de escudo'),
                        ),
                        Chip(label: Text(attempt.config.area.label)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_feedback case final feedback?) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          feedback.isCorrect
                              ? '¡Acierto! El guardián pierde energía.'
                              : 'Tu escudo recibió un impacto. Vamos a entenderlo.',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(feedback.question.statement),
                      const SizedBox(height: 12),
                      Text('Respuesta correcta: ${feedback.correctText}'),
                      const SizedBox(height: 8),
                      Text(
                        feedback.explanation ??
                            'Revisa la lección de este subtema para ampliar la explicación.',
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const Key('guardian-next'),
                        onPressed: () {
                          setState(() {
                            _feedback = null;
                          });
                          _top();
                        },
                        child: Text(
                          attempt.isActive
                              ? 'Siguiente pregunta'
                              : 'Ver resultado',
                        ),
                      ),
                    ] else if (attempt.isActive && attempt.question != null)
                      ..._question(attempt)
                    else
                      ..._result(attempt),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  List<Widget> _setup() {
    final catalog = ref.watch(studyCatalogProvider(_area));
    return [
      Text(
        'Piensa con calma. Protege tu escudo.',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Consigue 6 aciertos antes de cometer 3 errores. Hasta 8 preguntas, sin presión de tiempo ni potenciadores. Los resultados son de esta partida: no modifican tu diagnóstico ni tu XP.',
      ),
      const SizedBox(height: 8),
      const Text(
        'En línea puedes salir y retomar durante 24 horas. Se necesitan 8 preguntas publicadas para la selección.',
      ),
      const SizedBox(height: 20),
      DropdownButtonFormField<AcademicArea>(
        key: const Key('guardian-area'),
        initialValue: _area,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Área'),
        items: [
          for (final area in AcademicArea.values)
            DropdownMenuItem(value: area, child: Text(area.label)),
        ],
        onChanged: _busy
            ? null
            : (area) {
                if (area != null) {
                  setState(() {
                    _area = area;
                    _subtopic = null;
                  });
                }
              },
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<PracticeDifficulty>(
        initialValue: _difficulty,
        decoration: const InputDecoration(labelText: 'Dificultad'),
        items: [
          for (final difficulty in PracticeDifficulty.values)
            DropdownMenuItem(value: difficulty, child: Text(difficulty.label)),
        ],
        onChanged: _busy
            ? null
            : (difficulty) {
                if (difficulty != null) {
                  setState(() {
                    _difficulty = difficulty;
                  });
                }
              },
      ),
      const SizedBox(height: 16),
      catalog.when(
        loading: () => const LinearProgressIndicator(),
        error: (error, stack) => TextButton(
          onPressed: () => ref.invalidate(studyCatalogProvider(_area)),
          child: const Text('Reintentar catálogo de subtemas'),
        ),
        data: (catalog) => DropdownButtonFormField<String>(
          key: ValueKey('guardian-subtopic-${_area.name}'),
          initialValue: _subtopic ?? '',
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Tema / subtema (opcional)',
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('Toda el área')),
            for (final theme in catalog.themes)
              for (final subtopic in theme.subtopics)
                DropdownMenuItem(
                  value: subtopic.id,
                  child: Text(
                    '${theme.name} · ${subtopic.name}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          ],
          onChanged: _busy
              ? null
              : (value) => setState(() {
                  _subtopic = value == '' ? null : value;
                }),
        ),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        key: const Key('guardian-start'),
        onPressed: _busy ? null : _start,
        icon: const Icon(Icons.shield_outlined),
        label: Text(_busy ? 'Preparando…' : 'Desafiar al guardián'),
      ),
    ];
  }

  List<Widget> _question(GuardianAttempt attempt) {
    final q = attempt.question!;
    return [
      Text(
        'Pregunta ${attempt.review.length + 1} · ${q.subtopicName}',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 12),
      if (q.caseContent case final caseContent?) ...[
        if (caseContent.title.isNotEmpty)
          Text(
            caseContent.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        Text(caseContent.context),
        if (caseContent.imageUrl case final url?)
          _image(url, 'Imagen del contexto'),
        const Divider(height: 24),
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
              key: ValueKey('guardian-option-${option.id}'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(16),
                backgroundColor: _selected == option.id
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
              onPressed: _busy || _pending != null
                  ? null
                  : () => setState(() {
                      _selected = option.id;
                    }),
              child: Row(
                children: [
                  Icon(
                    _selected == option.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(option.text)),
                ],
              ),
            ),
          ),
        ),
      FilledButton(
        key: const Key('guardian-answer'),
        onPressed: _busy || _selected == null ? null : _answer,
        child: Text(
          _busy
              ? 'Confirmando…'
              : _pending == null
              ? 'Confirmar respuesta'
              : 'Reintentar envío',
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'No pierdes escudo por demorarte. Solo cuenta la respuesta confirmada.',
      ),
    ];
  }

  Widget _image(String url, String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Image.network(
      resolveResourceUrl(ref.read(appConfigProvider), url),
      semanticLabel: label,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) => Text(
        'No se pudo cargar la imagen. Revisa la conexión antes de responder. Puedes salir y retomar el desafío.',
      ),
    ),
  );

  List<Widget> _result(GuardianAttempt attempt) {
    final title = switch (attempt.status) {
      GuardianStatus.victory => '¡Superaste al guardián!',
      GuardianStatus.defeat => 'Tu escudo necesita recargarse',
      GuardianStatus.expired => 'Este desafío venció',
      GuardianStatus.abandoned => 'Desafío cerrado',
      _ => 'Estado de la partida no disponible',
    };
    final topics = attempt.toReinforce
        .map((r) => '${r.question.themeName} · ${r.question.subtopicName}')
        .toSet();
    return [
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      Text(
        '${attempt.correct} aciertos y ${attempt.mistakes} errores en ${attempt.review.length} respuestas.',
      ),
      const SizedBox(height: 16),
      if (topics.isEmpty)
        const Text('No hay errores confirmados para repasar en esta partida.')
      else ...[
        Text(
          'Para repasar después',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        for (final topic in topics)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('• $topic'),
          ),
        const Text(
          'Son pistas de esta partida, no un diagnóstico definitivo de tus conocimientos.',
        ),
      ],
      const SizedBox(height: 16),
      for (final review in attempt.review)
        Card(
          child: ExpansionTile(
            leading: Icon(
              review.isCorrect
                  ? Icons.check_circle_outline
                  : Icons.lightbulb_outline,
            ),
            title: Text(review.question.statement),
            subtitle: Text(review.question.subtopicName),
            childrenPadding: const EdgeInsets.all(16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Respuesta correcta: ${review.correctText}'),
              const SizedBox(height: 8),
              Text(
                review.explanation ?? 'Consulta la lección de este subtema.',
              ),
            ],
          ),
        ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () => setState(() {
          _attempt = null;
          _feedback = null;
          _error = null;
          _pending = null;
          _selected = null;
        }),
        child: const Text('Nuevo desafío'),
      ),
      TextButton(
        onPressed: () =>
            context.push('/student/study/${attempt.config.area.slug}'),
        child: const Text('Ir a las lecciones del área'),
      ),
    ];
  }

  String _message(Object error) => error is ApiError
      ? error.message
      : 'No pudimos cargar el desafío. Revisa tu conexión e inténtalo de nuevo.';
}
