import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_error.dart';
import '../../../practice/domain/practice_models.dart';
import '../domain/trivia_rush_models.dart';
import 'trivia_rush_providers.dart';

class TriviaRushPage extends ConsumerStatefulWidget {
  const TriviaRushPage({required this.config, super.key});

  final TriviaRushConfig config;

  @override
  ConsumerState<TriviaRushPage> createState() => _TriviaRushPageState();
}

class _TriviaRushPageState extends ConsumerState<TriviaRushPage> {
  Timer? _timer;
  TriviaRushSession? _session;
  Object? _error;
  TriviaRushScore _score = const TriviaRushScore();
  final List<TriviaRushReviewEntry> _review = [];
  final Set<String> _eliminatedOptions = {};
  final Set<String> _failedOptions = {};
  int _secondsRemaining = 0;
  int _questionIndex = 0;
  int _questionElapsedSeconds = 0;
  bool _submitting = false;
  bool _finished = false;
  bool _assisted = false;
  bool _comboShieldActive = false;
  bool _secondChanceActive = false;
  bool? _lastAnswerCorrect;

  PracticeQuestion? get _question {
    final questions = _session?.questions;
    if (questions == null || _questionIndex >= questions.length) return null;
    return questions[_questionIndex];
  }

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.config.duration.seconds;
    Future<void>.microtask(_start);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final session = await ref
          .read(triviaRushRepositoryProvider)
          .start(widget.config);
      if (!mounted) return;
      if (session.questions.isEmpty) {
        throw const ApiError(
          code: 'empty_trivia_rush',
          message: 'Todavía no hay preguntas disponibles para esta ronda.',
        );
      }
      setState(() => _session = session);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _finished) return;
        if (_secondsRemaining <= 1) {
          setState(() {
            _secondsRemaining = 0;
            _finished = true;
          });
          _timer?.cancel();
          return;
        }
        setState(() {
          _secondsRemaining--;
          _questionElapsedSeconds++;
        });
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  Future<void> _answer(String answerId) async {
    final session = _session;
    final question = _question;
    if (session == null ||
        question == null ||
        _submitting ||
        _finished ||
        _eliminatedOptions.contains(answerId) ||
        _failedOptions.contains(answerId)) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final evaluation = await ref
          .read(triviaRushRepositoryProvider)
          .answer(
            attemptId: session.attemptId,
            questionId: question.id,
            answerId: answerId,
            responseTimeSeconds: _questionElapsedSeconds,
          );
      if (!mounted) return;

      if (!evaluation.isCorrect && _secondChanceActive) {
        setState(() {
          _review.add(
            TriviaRushReviewEntry(
              question: question,
              selectedAnswerId: answerId,
              evaluation: evaluation,
            ),
          );
          _score = _score.registerIncorrect(protectCombo: true);
          _failedOptions.add(answerId);
          _secondChanceActive = false;
          _lastAnswerCorrect = false;
          _submitting = false;
        });
        return;
      }

      final protectCombo = !evaluation.isCorrect && _comboShieldActive;
      setState(() {
        _review.add(
          TriviaRushReviewEntry(
            question: question,
            selectedAnswerId: answerId,
            evaluation: evaluation,
          ),
        );
        _score = evaluation.isCorrect
            ? _score.registerCorrect()
            : _score.registerIncorrect(protectCombo: protectCombo);
        if (protectCombo) _comboShieldActive = false;
        _lastAnswerCorrect = evaluation.isCorrect;
      });
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted || _finished) return;
      _advance();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Future<void> _activateBooster(TriviaRushBooster booster) async {
    final session = _session;
    final question = _question;
    if (session == null || question == null || _submitting || _finished) return;
    if (booster == TriviaRushBooster.fiftyFifty &&
        _eliminatedOptions.isNotEmpty) {
      _showMessage('Ya descartaste dos opciones en esta pregunta.');
      return;
    }
    if (booster == TriviaRushBooster.comboShield && _comboShieldActive) {
      _showMessage('La protección de combo ya está activa.');
      return;
    }
    if (booster == TriviaRushBooster.secondChance && _secondChanceActive) {
      _showMessage('La segunda oportunidad ya está activa.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final activation = await ref
          .read(triviaRushRepositoryProvider)
          .activateBooster(
            attemptId: session.attemptId,
            questionId: question.id,
            booster: booster,
          );
      if (!mounted) return;
      setState(() {
        _assisted = true;
        _submitting = false;
        switch (booster) {
          case TriviaRushBooster.extraTime:
            _secondsRemaining += 10;
            break;
          case TriviaRushBooster.fiftyFifty:
            _eliminatedOptions.addAll(activation.eliminatedAnswerIds);
            break;
          case TriviaRushBooster.comboShield:
            _comboShieldActive = true;
            break;
          case TriviaRushBooster.skip:
            _score = _score.registerSkip();
            break;
          case TriviaRushBooster.secondChance:
            _secondChanceActive = true;
            break;
        }
      });
      if (booster == TriviaRushBooster.skip) _advance();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showMessage(_errorMessage(error));
    }
  }

  void _advance() {
    setState(() {
      _questionIndex++;
      _questionElapsedSeconds = 0;
      _eliminatedOptions.clear();
      _failedOptions.clear();
      _secondChanceActive = false;
      _lastAnswerCorrect = null;
      _submitting = false;
      if (_questionIndex >= (_session?.questions.length ?? 0)) {
        _finished = true;
        _timer?.cancel();
      }
    });
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    if (_error case final error?) {
      return _TriviaErrorView(
        message: _errorMessage(error),
        onRetry: () {
          setState(() => _error = null);
          _start();
        },
      );
    }
    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trivia Rush')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_finished) {
      return _TriviaResultView(
        score: _score,
        review: _review,
        assisted: _assisted,
        onReplay: () => context.go('/student/practice/trivia-rush'),
      );
    }

    final question = _question!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trivia Rush'),
          leading: IconButton(
            onPressed: _confirmExit,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              _RoundHeader(
                seconds: _secondsRemaining,
                score: _score,
                assisted: _assisted,
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: (_secondsRemaining / widget.config.duration.seconds)
                    .clamp(0.0, 1.0),
              ),
              const SizedBox(height: 20),
              Text(
                '${question.area.label} · ${question.subtopicName} · ${_difficultyLabel(question.difficulty)}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              AnimatedScale(
                scale: _lastAnswerCorrect == true ? 1.025 : 1,
                duration: const Duration(milliseconds: 220),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      question.statement,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final option in question.options) ...[
                _AnswerButton(
                  key: Key('trivia-answer-${option.id}'),
                  option: option,
                  disabled:
                      _submitting ||
                      _eliminatedOptions.contains(option.id) ||
                      _failedOptions.contains(option.id),
                  failed: _failedOptions.contains(option.id),
                  onPressed: () => _answer(option.id),
                ),
                const SizedBox(height: 8),
              ],
              if (_lastAnswerCorrect != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _lastAnswerCorrect! ? '¡Correcto!' : 'Intenta otra vez',
                    key: const Key('trivia-answer-feedback'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _lastAnswerCorrect!
                          ? Colors.green.shade700
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                'Potenciadores',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'En demostración son ilimitados. Con AdMob, cada uso gratuito pedirá un video voluntario.',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final booster in TriviaRushBooster.values)
                    ActionChip(
                      key: Key('trivia-booster-${booster.name}'),
                      avatar: Icon(_boosterIcon(booster), size: 18),
                      label: Text(booster.label),
                      tooltip: booster.description,
                      onPressed: _submitting
                          ? null
                          : () => _activateBooster(booster),
                    ),
                ],
              ),
              if (_comboShieldActive || _secondChanceActive) ...[
                const SizedBox(height: 12),
                Text(
                  [
                    if (_comboShieldActive) 'Combo protegido',
                    if (_secondChanceActive) 'Segunda oportunidad activa',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la ronda?'),
        content: const Text('El progreso de esta partida no se conservará.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            key: const Key('confirm-exit-trivia'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }
}

class _RoundHeader extends StatelessWidget {
  const _RoundHeader({
    required this.seconds,
    required this.score,
    required this.assisted,
  });

  final int seconds;
  final TriviaRushScore score;
  final bool assisted;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _Metric(
          icon: Icons.timer_outlined,
          label: '$seconds s',
          warning: seconds <= 10,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _Metric(icon: Icons.stars_rounded, label: '${score.points} pts'),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _Metric(
          icon: Icons.local_fire_department_rounded,
          label: 'x${score.multiplier} · ${score.combo}',
        ),
      ),
      if (assisted) ...[
        const SizedBox(width: 6),
        const Tooltip(
          message: 'Ronda asistida',
          child: Icon(Icons.auto_awesome_rounded, size: 20),
        ),
      ],
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    this.warning = false,
  });

  final IconData icon;
  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: BoxDecoration(
      color: warning
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.option,
    required this.disabled,
    required this.failed,
    required this.onPressed,
    super.key,
  });

  final PracticeOption option;
  final bool disabled;
  final bool failed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: disabled ? null : onPressed,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      alignment: Alignment.centerLeft,
    ),
    child: Row(
      children: [
        Expanded(child: Text(option.text)),
        if (failed) const Icon(Icons.close_rounded),
      ],
    ),
  );
}

class _TriviaResultView extends StatelessWidget {
  const _TriviaResultView({
    required this.score,
    required this.review,
    required this.assisted,
    required this.onReplay,
  });

  final TriviaRushScore score;
  final List<TriviaRushReviewEntry> review;
  final bool assisted;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final weaknesses = triviaRushWeaknesses(review);
    return Scaffold(
      key: const Key('trivia-result-view'),
      appBar: AppBar(title: const Text('Resultado de Trivia Rush')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Icon(
            Icons.emoji_events_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            '${score.points} puntos',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text('Mejor combo: ${score.bestCombo}', textAlign: TextAlign.center),
          if (assisted)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Ronda asistida · no participará en rankings futuros',
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _ResultMetric('Correctas', score.correctAnswers)),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultMetric('Incorrectas', score.incorrectAnswers),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ResultMetric('Saltadas', score.skippedQuestions),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Qué conviene reforzar',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (weaknesses.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No detectamos errores en las respuestas enviadas.',
                ),
              ),
            )
          else
            for (final weakness in weaknesses)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.track_changes_rounded),
                  ),
                  title: Text(weakness.subtopic),
                  subtitle: Text(
                    '${weakness.area.label} · ${weakness.theme}\n${weakness.errors} error(es)',
                  ),
                  isThreeLine: true,
                  trailing: weakness.studyRoute == null
                      ? null
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: weakness.studyRoute == null
                      ? null
                      : () => context.push(weakness.studyRoute!),
                ),
              ),
          if (review.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Revisión de respuestas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final entry in review)
              Card(
                child: ExpansionTile(
                  leading: Icon(
                    entry.evaluation.isCorrect
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: entry.evaluation.isCorrect
                        ? Colors.green.shade700
                        : Theme.of(context).colorScheme.error,
                  ),
                  title: Text(entry.question.statement),
                  subtitle: Text(entry.question.subtopicName),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        entry.evaluation.explanation ??
                            'La explicación estará disponible con la calificación del servidor.',
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('replay-trivia-rush'),
            onPressed: onReplay,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Jugar otra ronda'),
          ),
          TextButton(
            onPressed: () => context.go('/student/practice'),
            child: const Text('Volver a practicar'),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      child: Column(
        children: [
          Text('$value', style: Theme.of(context).textTheme.titleLarge),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _TriviaErrorView extends StatelessWidget {
  const _TriviaErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Trivia Rush')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 52),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    ),
  );
}

IconData _boosterIcon(TriviaRushBooster booster) => switch (booster) {
  TriviaRushBooster.extraTime => Icons.more_time_rounded,
  TriviaRushBooster.fiftyFifty => Icons.filter_2_rounded,
  TriviaRushBooster.comboShield => Icons.shield_rounded,
  TriviaRushBooster.skip => Icons.skip_next_rounded,
  TriviaRushBooster.secondChance => Icons.replay_circle_filled_rounded,
};

String _errorMessage(Object error) => switch (error) {
  ApiError value => value.message,
  _ => 'No pudimos continuar la ronda. Intenta nuevamente.',
};

String _difficultyLabel(String value) => switch (value.toUpperCase()) {
  'BASICA' || 'BÁSICA' || 'BASICO' || 'BÁSICO' => 'Básica',
  'AVANZADA' || 'AVANZADO' => 'Avanzada',
  _ => 'Media',
};
