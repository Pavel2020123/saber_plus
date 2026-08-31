import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feedback/game_audio_feedback.dart';
import '../../../../core/network/api_error.dart';
import '../../../practice/domain/practice_models.dart';
import '../../trivia_rush/domain/trivia_rush_models.dart';
import '../../trivia_rush/presentation/trivia_rush_providers.dart';
import '../domain/tug_of_war_models.dart';
import 'tug_of_war_providers.dart';

class TugOfWarPage extends ConsumerStatefulWidget {
  const TugOfWarPage({required this.config, super.key});

  final TugOfWarConfig config;

  @override
  ConsumerState<TugOfWarPage> createState() => _TugOfWarPageState();
}

class _TugOfWarPageState extends ConsumerState<TugOfWarPage> {
  static const _questionSeconds = 10;

  Timer? _countdownTimer;
  Timer? _cpuTimer;
  Stopwatch? _questionStopwatch;
  TriviaRushSession? _session;
  Object? _error;
  TugMatchProgress _progress = const TugMatchProgress();
  TugCpuTurn? _cpuTurn;
  TugRoundResolution? _roundResolution;
  TugWinner? _pendingWinner;
  TugWinner? _winner;
  String? _selectedAnswerId;
  bool? _playerCorrect;
  int? _playerResponseMilliseconds;
  bool _playerFinished = false;
  bool _cpuAnswered = false;
  bool _submitting = false;
  bool _finished = false;
  int _questionIndex = 0;
  int _secondsRemaining = _questionSeconds;

  PracticeQuestion? get _question {
    final questions = _session?.questions;
    if (questions == null || _questionIndex >= questions.length) return null;
    return questions[_questionIndex];
  }

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadMatch);
  }

  @override
  void dispose() {
    _cancelRoundTimers();
    super.dispose();
  }

  Future<void> _loadMatch() async {
    _cancelRoundTimers();
    try {
      final session = await ref
          .read(triviaRushRepositoryProvider)
          .start(
            TriviaRushConfig(
              areas: widget.config.areas,
              duration: TriviaRushDuration.quick,
            ),
          );
      if (!mounted) return;
      if (session.questions.isEmpty) {
        throw const ApiError(
          code: 'empty_tug_match',
          message: 'Todavía no hay preguntas disponibles para esta partida.',
        );
      }
      setState(() {
        _session = session;
        _error = null;
      });
      unawaited(ref.read(gameAudioFeedbackProvider).play(GameSound.matchFound));
      _beginRound();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  void _beginRound() {
    _cancelRoundTimers();
    if (_question == null) {
      _finishFromQuestionLimit();
      return;
    }
    final cpuTurn = ref.read(tugCpuPlannerProvider)(
      widget.config.cpuDifficulty,
    );
    setState(() {
      _cpuTurn = cpuTurn;
      _roundResolution = null;
      _pendingWinner = null;
      _selectedAnswerId = null;
      _playerCorrect = null;
      _playerResponseMilliseconds = null;
      _playerFinished = false;
      _cpuAnswered = false;
      _submitting = false;
      _secondsRemaining = _questionSeconds;
    });
    _questionStopwatch = Stopwatch()..start();
    if (cpuTurn.isCorrect != null) {
      _cpuTimer = Timer(
        Duration(milliseconds: cpuTurn.responseMilliseconds),
        _markCpuAnswered,
      );
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _roundResolution != null || _finished) return;
      if (_secondsRemaining <= 1) {
        setState(() => _secondsRemaining = 0);
        _finishDeadline();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _markCpuAnswered() {
    if (!mounted || _cpuAnswered || _roundResolution != null || _finished) {
      return;
    }
    setState(() => _cpuAnswered = true);
    _tryResolveRound();
  }

  Future<void> _answer(String answerId) async {
    final session = _session;
    final question = _question;
    if (session == null ||
        question == null ||
        _submitting ||
        _playerFinished ||
        _roundResolution != null ||
        _finished) {
      return;
    }
    final roundIndex = _questionIndex;
    final elapsedMilliseconds = (_questionStopwatch?.elapsedMilliseconds ?? 0)
        .clamp(1, _questionSeconds * 1000);
    setState(() {
      _submitting = true;
      _selectedAnswerId = answerId;
    });
    try {
      final evaluation = await ref
          .read(triviaRushRepositoryProvider)
          .answer(
            attemptId: session.attemptId,
            questionId: question.id,
            answerId: answerId,
            responseTimeSeconds: (elapsedMilliseconds / 1000).ceil(),
          );
      if (!mounted || _playerFinished || roundIndex != _questionIndex) return;
      setState(() {
        _playerCorrect = evaluation.isCorrect;
        _playerResponseMilliseconds = elapsedMilliseconds;
        _playerFinished = true;
        _submitting = false;
      });
      _tryResolveRound();
    } on Object catch (error) {
      if (!mounted || _playerFinished || roundIndex != _questionIndex) return;
      setState(() {
        _selectedAnswerId = null;
        _submitting = false;
      });
      _showMessage(_errorMessage(error));
    }
  }

  void _finishDeadline() {
    if (_roundResolution != null || _finished) return;
    _cpuTimer?.cancel();
    setState(() {
      if (!_playerFinished) {
        _playerFinished = true;
        _playerCorrect = null;
        _playerResponseMilliseconds = null;
      }
      _cpuAnswered = true;
    });
    _tryResolveRound();
  }

  void _tryResolveRound() {
    if (!_playerFinished || !_cpuAnswered || _roundResolution != null) return;
    _cancelRoundTimers();
    final cpuTurn = _cpuTurn!;
    final resolution = TugRoundResolution.resolve(
      playerCorrect: _playerCorrect,
      playerResponseMilliseconds: _playerResponseMilliseconds,
      cpuCorrect: cpuTurn.isCorrect,
      cpuResponseMilliseconds: cpuTurn.isCorrect == null
          ? null
          : cpuTurn.responseMilliseconds,
    );
    final updated = _progress.apply(
      resolution: resolution,
      playerCorrect: _playerCorrect,
      cpuCorrect: cpuTurn.isCorrect,
    );
    setState(() {
      _progress = updated;
      _roundResolution = resolution;
      _pendingWinner = updated.winner;
    });
    if (resolution.ropeDelta != 0) {
      unawaited(ref.read(gameAudioFeedbackProvider).play(GameSound.tugPull));
    }
  }

  void _continueAfterRound() {
    final pendingWinner = _pendingWinner;
    if (pendingWinner != null) {
      _finishMatch(pendingWinner);
      return;
    }
    setState(() => _questionIndex++);
    _beginRound();
  }

  void _finishFromQuestionLimit() {
    _finishMatch(_progress.winnerWhenQuestionsEnd());
  }

  void _finishMatch(TugWinner winner) {
    _cancelRoundTimers();
    setState(() {
      _winner = winner;
      _finished = true;
    });
    final sound = switch (winner) {
      TugWinner.player => GameSound.matchVictory,
      TugWinner.cpu => GameSound.matchDefeat,
      TugWinner.draw => GameSound.triviaFinish,
    };
    unawaited(ref.read(gameAudioFeedbackProvider).play(sound));
  }

  void _cancelRoundTimers() {
    _countdownTimer?.cancel();
    _cpuTimer?.cancel();
    _questionStopwatch?.stop();
  }

  void _showMessage(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    if (_error case final error?) {
      return _TugErrorView(
        message: _errorMessage(error),
        onRetry: () {
          setState(() => _error = null);
          _loadMatch();
        },
      );
    }
    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tira y afloja')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_finished) {
      return _TugResultView(
        winner: _winner!,
        progress: _progress,
        onReplay: () => context.go('/student/practice/tug-of-war'),
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
          title: const Text('Tira y afloja'),
          leading: IconButton(
            onPressed: _confirmExit,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
            children: [
              const _PrototypeBanner(),
              const SizedBox(height: 10),
              _MatchHeader(
                questionNumber: _questionIndex + 1,
                secondsRemaining: _secondsRemaining,
                progress: _progress,
              ),
              const SizedBox(height: 10),
              TugArenaMockup(
                ropePosition: _progress.ropePosition,
                playerAnswered: _playerFinished,
                cpuAnswered: _cpuAnswered,
              ),
              const SizedBox(height: 16),
              if (_roundResolution case final resolution?)
                _RoundFeedback(
                  resolution: resolution,
                  playerCorrect: _playerCorrect,
                  playerResponseMilliseconds: _playerResponseMilliseconds,
                  cpuTurn: _cpuTurn!,
                  isMatchPoint: _pendingWinner != null,
                  onContinue: _continueAfterRound,
                )
              else ...[
                Text(
                  '${question.area.label} · ${question.subtopicName}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      question.statement,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                for (final option in question.options) ...[
                  OutlinedButton(
                    key: Key('tug-answer-${option.id}'),
                    onPressed: _playerFinished || _submitting
                        ? null
                        : () => _answer(option.id),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: _selectedAnswerId == option.id
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                    child: Text(option.text),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_playerFinished && !_cpuAnswered)
                  Semantics(
                    liveRegion: true,
                    child: const Card(
                      child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(Icons.hourglass_top_rounded),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Respuesta guardada. El rival sigue pensando…',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
        title: const Text('¿Salir de la partida?'),
        content: const Text('El duelo local actual no se conservará.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            key: const Key('confirm-exit-tug'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) context.pop();
  }
}

class _PrototypeBanner extends StatelessWidget {
  const _PrototypeBanner();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('tug-prototype-banner'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      children: [
        Icon(Icons.construction_rounded, size: 18),
        SizedBox(width: 8),
        Expanded(
          child: Text('Maqueta funcional · animaciones finales pendientes'),
        ),
      ],
    ),
  );
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({
    required this.questionNumber,
    required this.secondsRemaining,
    required this.progress,
  });

  final int questionNumber;
  final int secondsRemaining;
  final TugMatchProgress progress;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _TugMetric(
          icon: Icons.help_outline_rounded,
          label: 'Ronda $questionNumber',
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _TugMetric(
          icon: Icons.timer_outlined,
          label: '$secondsRemaining s',
          warning: secondsRemaining <= 3,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _TugMetric(
          icon: Icons.compare_arrows_rounded,
          label:
              '${progress.ropePosition > 0 ? '+' : ''}${progress.ropePosition}',
        ),
      ),
    ],
  );
}

class _TugMetric extends StatelessWidget {
  const _TugMetric({
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
        Icon(icon, size: 17),
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

class TugArenaMockup extends StatelessWidget {
  const TugArenaMockup({
    required this.ropePosition,
    required this.playerAnswered,
    required this.cpuAnswered,
    super.key,
  });

  final int ropePosition;
  final bool playerAnswered;
  final bool cpuAnswered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final knotAlignment =
        -(ropePosition / TugMatchProgress.winningPosition) * 0.46;
    final ropeDescription = switch (ropePosition) {
      > 0 => '$ropePosition marcas a favor del jugador',
      < 0 => '${ropePosition.abs()} marcas a favor de la CPU',
      _ => 'en el centro',
    };
    return Semantics(
      label: 'Arena provisional. Cuerda $ropeDescription.',
      child: Container(
        key: const Key('tug-arena-mockup'),
        height: 190,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: scheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Container(width: 2, color: scheme.outlineVariant),
              ),
            ),
            Positioned(
              left: 50,
              right: 50,
              top: 91,
              child: Container(height: 5, color: scheme.tertiary),
            ),
            Positioned(
              left: 50,
              right: 50,
              top: 108,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var index = 0; index < 9; index++)
                    Container(
                      width: index == 4 ? 3 : 1,
                      height: index == 4 ? 13 : 8,
                      color: index == 4 ? scheme.primary : scheme.outline,
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment(knotAlignment, 0.01),
              child: Container(
                key: const Key('tug-rope-knot'),
                width: 18,
                height: 24,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  border: Border.all(color: scheme.tertiary, width: 3),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
            Positioned(
              left: 12,
              top: 34,
              child: _PlaceholderFighter(
                label: 'Tú',
                answered: playerAnswered,
                color: scheme.primaryContainer,
              ),
            ),
            Positioned(
              right: 12,
              top: 34,
              child: _PlaceholderFighter(
                label: 'CPU',
                answered: cpuAnswered,
                color: scheme.errorContainer,
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 8,
              child: Text(
                'Personajes provisionales',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderFighter extends StatelessWidget {
  const _PlaceholderFighter({
    required this.label,
    required this.answered,
    required this.color,
  });

  final String label;
  final bool answered;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 27,
        backgroundColor: color,
        child: const Icon(Icons.person_rounded, size: 34),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      Text(
        answered ? 'Respondió' : 'Pensando',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ],
  );
}

class _RoundFeedback extends StatelessWidget {
  const _RoundFeedback({
    required this.resolution,
    required this.playerCorrect,
    required this.playerResponseMilliseconds,
    required this.cpuTurn,
    required this.isMatchPoint,
    required this.onContinue,
  });

  final TugRoundResolution resolution;
  final bool? playerCorrect;
  final int? playerResponseMilliseconds;
  final TugCpuTurn cpuTurn;
  final bool isMatchPoint;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('tug-round-feedback'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(resolution.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(resolution.explanation),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _AnswerStatus(
                  label: 'Tú',
                  isCorrect: playerCorrect,
                  milliseconds: playerResponseMilliseconds,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AnswerStatus(
                  label: 'CPU',
                  isCorrect: cpuTurn.isCorrect,
                  milliseconds: cpuTurn.isCorrect == null
                      ? null
                      : cpuTurn.responseMilliseconds,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('continue-tug-round'),
            onPressed: onContinue,
            icon: Icon(
              isMatchPoint
                  ? Icons.emoji_events_outlined
                  : Icons.navigate_next_rounded,
            ),
            label: Text(isMatchPoint ? 'Ver resultado' : 'Siguiente pregunta'),
          ),
        ],
      ),
    ),
  );
}

class _AnswerStatus extends StatelessWidget {
  const _AnswerStatus({
    required this.label,
    required this.isCorrect,
    required this.milliseconds,
  });

  final String label;
  final bool? isCorrect;
  final int? milliseconds;

  @override
  Widget build(BuildContext context) {
    final (icon, status) = switch (isCorrect) {
      true => (Icons.check_circle_outline_rounded, 'Correcta'),
      false => (Icons.cancel_outlined, 'Incorrecta'),
      null => (Icons.timer_off_outlined, 'Sin respuesta'),
    };
    final time = milliseconds == null
        ? 'Tiempo agotado'
        : '${(milliseconds! / 1000).toStringAsFixed(1)} s';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(status),
          Text(time, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _TugResultView extends StatelessWidget {
  const _TugResultView({
    required this.winner,
    required this.progress,
    required this.onReplay,
  });

  final TugWinner winner;
  final TugMatchProgress progress;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final (icon, title, message) = switch (winner) {
      TugWinner.player => (
        Icons.emoji_events_rounded,
        '¡Ganaste el duelo!',
        'Llevaste la cuerda hasta tu lado.',
      ),
      TugWinner.cpu => (
        Icons.sports_score_rounded,
        'Esta vez ganó la CPU',
        'Practica la precisión y vuelve a intentarlo.',
      ),
      TugWinner.draw => (
        Icons.handshake_outlined,
        'Partida empatada',
        'La cuerda terminó exactamente en el centro.',
      ),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Resultado del duelo')),
      body: ListView(
        key: const Key('tug-result-view'),
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
        children: [
          Icon(icon, size: 72),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _ResultRow(
                    label: 'Rondas',
                    value: '${progress.roundsPlayed}',
                  ),
                  const Divider(),
                  _ResultRow(
                    label: 'Tus aciertos',
                    value: '${progress.playerCorrectAnswers}',
                  ),
                  const Divider(),
                  _ResultRow(
                    label: 'Aciertos CPU',
                    value: '${progress.cpuCorrectAnswers}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Esta partida es una maqueta local: no afecta XP, rachas, estadísticas ni rankings.',
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('replay-tug-of-war'),
            onPressed: onReplay,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Jugar otra partida'),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
    ],
  );
}

class _TugErrorView extends StatelessWidget {
  const _TugErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Tira y afloja')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_kabaddi_outlined, size: 52),
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

String _errorMessage(Object error) {
  if (error is ApiError) return error.message;
  if (error is StateError) return error.message.toString();
  return 'No pudimos preparar la partida. Intenta nuevamente.';
}
