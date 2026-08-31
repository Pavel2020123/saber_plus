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
import 'animation/tug_animation_cue.dart';
import 'animation/tug_arena.dart';
import 'tug_of_war_providers.dart';

class TugOfWarPage extends ConsumerStatefulWidget {
  const TugOfWarPage({required this.config, super.key});

  final TugOfWarConfig config;

  @override
  ConsumerState<TugOfWarPage> createState() => _TugOfWarPageState();
}

class _TugOfWarPageState extends ConsumerState<TugOfWarPage>
    with WidgetsBindingObserver {
  static const _questionSeconds = 10;
  static const _clockRefreshInterval = Duration(milliseconds: 100);

  Timer? _countdownTimer;
  Timer? _cpuTimer;
  Stopwatch? _questionStopwatch;
  DateTime? _roundDeadline;
  DateTime? _cpuDeadline;
  DateTime? _pauseBeganAt;
  TriviaRushSession? _session;
  Object? _error;
  TugMatchProgress _progress = const TugMatchProgress();
  TugCpuTurn? _cpuTurn;
  TugRoundResolution? _roundResolution;
  TugAnimationCue? _animationCue;
  TugWinner? _pendingWinner;
  TugWinner? _winner;
  String? _selectedAnswerId;
  bool? _playerCorrect;
  int? _playerResponseMilliseconds;
  bool _playerFinished = false;
  bool _cpuAnswered = false;
  bool _submitting = false;
  bool _finished = false;
  bool _roundReady = false;
  bool _animationInProgress = false;
  bool _showRoundFeedback = false;
  bool _appPaused = false;
  bool _dialogOpen = false;
  bool _competitionPaused = false;
  int _animationCueId = 0;
  int _questionIndex = 0;
  int _secondsRemaining = _questionSeconds;

  bool get _shouldPauseCompetition => _appPaused || _dialogOpen;

  PracticeQuestion? get _question {
    final questions = _session?.questions;
    if (questions == null || _questionIndex >= questions.length) return null;
    return questions[_questionIndex];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future<void>.microtask(_loadMatch);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelRoundTimers();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final paused = state != AppLifecycleState.resumed;
    if (_appPaused == paused || !mounted) return;
    setState(() => _appPaused = paused);
    _syncCompetitionPause();
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
      _animationCue = null;
      _pendingWinner = null;
      _selectedAnswerId = null;
      _playerCorrect = null;
      _playerResponseMilliseconds = null;
      _playerFinished = false;
      _cpuAnswered = false;
      _submitting = false;
      _roundReady = false;
      _animationInProgress = false;
      _showRoundFeedback = false;
      _secondsRemaining = _questionSeconds;
    });
  }

  void _handleArenaReady(int roundId) {
    if (!mounted ||
        roundId != _questionIndex ||
        _roundReady ||
        _roundResolution != null ||
        _finished) {
      return;
    }
    final now = DateTime.now();
    setState(() => _roundReady = true);
    _questionStopwatch = Stopwatch();
    _roundDeadline = now.add(const Duration(seconds: _questionSeconds));
    final cpuTurn = _cpuTurn;
    _cpuDeadline = cpuTurn?.isCorrect == null
        ? null
        : now.add(Duration(milliseconds: cpuTurn!.responseMilliseconds));
    if (_shouldPauseCompetition) {
      _competitionPaused = true;
      _pauseBeganAt ??= now;
      return;
    }
    _questionStopwatch!.start();
    _scheduleRoundTimers();
  }

  void _scheduleRoundTimers() {
    _cancelTimerHandles();
    if (!mounted ||
        !_roundReady ||
        _competitionPaused ||
        _roundResolution != null ||
        _finished) {
      return;
    }
    _refreshCountdown();
    if (_roundResolution != null || _finished) return;
    final cpuDeadline = _cpuDeadline;
    if (!_cpuAnswered && cpuDeadline != null) {
      final delay = cpuDeadline.difference(DateTime.now());
      _cpuTimer = Timer(
        delay.isNegative ? Duration.zero : delay,
        _markCpuAnswered,
      );
    }
    _countdownTimer = Timer.periodic(
      _clockRefreshInterval,
      (_) => _refreshCountdown(),
    );
  }

  void _refreshCountdown() {
    final deadline = _roundDeadline;
    if (!mounted ||
        deadline == null ||
        _competitionPaused ||
        _roundResolution != null ||
        _finished) {
      return;
    }
    final remainingMilliseconds = deadline
        .difference(DateTime.now())
        .inMilliseconds;
    final seconds = remainingMilliseconds <= 0
        ? 0
        : ((remainingMilliseconds + 999) ~/ 1000).clamp(0, _questionSeconds);
    if (seconds != _secondsRemaining) {
      setState(() => _secondsRemaining = seconds);
    }
    if (remainingMilliseconds <= 0) _finishDeadline();
  }

  void _markCpuAnswered() {
    if (!mounted ||
        !_roundReady ||
        _competitionPaused ||
        _cpuAnswered ||
        _roundResolution != null ||
        _finished) {
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
        !_roundReady ||
        _competitionPaused ||
        _animationInProgress ||
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
    final previousPosition = _progress.ropePosition;
    final updated = _progress.apply(
      resolution: resolution,
      playerCorrect: _playerCorrect,
      cpuCorrect: cpuTurn.isCorrect,
    );
    final cue = TugAnimationCue(
      id: ++_animationCueId,
      fromPosition: previousPosition,
      toPosition: updated.ropePosition,
      outcome: resolution.outcome,
      bothCorrect: _playerCorrect == true && cpuTurn.isCorrect == true,
      winner: updated.winner,
    );
    setState(() {
      _progress = updated;
      _roundResolution = resolution;
      _pendingWinner = updated.winner;
      _animationCue = cue;
      _animationInProgress = true;
      _showRoundFeedback = false;
    });
  }

  void _handleAnimationCompleted(int cueId) {
    if (!mounted || _animationCue?.id != cueId || !_animationInProgress) {
      return;
    }
    setState(() {
      _animationInProgress = false;
      _showRoundFeedback = true;
    });
  }

  void _handleArenaSound(TugArenaSoundCue cue) {
    final sound = switch (cue) {
      TugArenaSoundCue.ropeStrain => GameSound.tugRopeStrain,
      TugArenaSoundCue.pull => GameSound.tugPull,
    };
    unawaited(ref.read(gameAudioFeedbackProvider).play(sound));
  }

  void _continueAfterRound() {
    if (_animationInProgress || !_showRoundFeedback) return;
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
    _cancelTimerHandles();
    _questionStopwatch?.stop();
    _roundDeadline = null;
    _cpuDeadline = null;
    _pauseBeganAt = null;
  }

  void _cancelTimerHandles() {
    _countdownTimer?.cancel();
    _cpuTimer?.cancel();
    _countdownTimer = null;
    _cpuTimer = null;
  }

  void _syncCompetitionPause() {
    final shouldPause = _shouldPauseCompetition;
    if (shouldPause == _competitionPaused) return;
    final now = DateTime.now();
    if (shouldPause) {
      _competitionPaused = true;
      _pauseBeganAt = now;
      _cancelTimerHandles();
      _questionStopwatch?.stop();
      return;
    }
    final pausedFor = _pauseBeganAt == null
        ? Duration.zero
        : now.difference(_pauseBeganAt!);
    _competitionPaused = false;
    _pauseBeganAt = null;
    if (!_roundReady || _roundResolution != null || _finished) return;
    if (_roundDeadline case final deadline?) {
      _roundDeadline = deadline.add(pausedFor);
    }
    if (_cpuDeadline case final deadline?) {
      _cpuDeadline = deadline.add(pausedFor);
    }
    _questionStopwatch?.start();
    _scheduleRoundTimers();
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
    final displayedRopePosition = _animationInProgress
        ? _animationCue?.fromPosition ?? _progress.ropePosition
        : _progress.ropePosition;
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
              const _LocalMatchBanner(),
              const SizedBox(height: 10),
              _MatchHeader(
                questionNumber: _questionIndex + 1,
                secondsRemaining: _secondsRemaining,
                ropePosition: displayedRopePosition,
              ),
              const SizedBox(height: 10),
              TugArena(
                roundId: _questionIndex,
                ropePosition: _progress.ropePosition,
                playerAnswered: _playerFinished,
                cpuAnswered: _cpuAnswered,
                animationCue: _animationCue,
                paused: _shouldPauseCompetition,
                onReady: _handleArenaReady,
                onSequenceCompleted: _handleAnimationCompleted,
                onSoundCue: _handleArenaSound,
              ),
              const SizedBox(height: 16),
              if (_animationInProgress)
                _ResolvingRoundCard(resolution: _roundResolution!)
              else if (_showRoundFeedback)
                _RoundFeedback(
                  resolution: _roundResolution!,
                  playerCorrect: _playerCorrect,
                  playerResponseMilliseconds: _playerResponseMilliseconds,
                  cpuTurn: _cpuTurn!,
                  isMatchPoint: _pendingWinner != null,
                  onContinue: _continueAfterRound,
                )
              else ...[
                if (!_roundReady) ...[
                  const _ArenaPreparationCard(),
                  const SizedBox(height: 10),
                ],
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
                    onPressed:
                        !_roundReady ||
                            _competitionPaused ||
                            _playerFinished ||
                            _submitting
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
    if (_dialogOpen) return;
    setState(() => _dialogOpen = true);
    _syncCompetitionPause();
    bool? leave;
    try {
      leave = await showDialog<bool>(
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
    } finally {
      if (mounted) {
        setState(() => _dialogOpen = false);
        _syncCompetitionPause();
      }
    }
    if (leave == true && mounted) context.pop();
  }
}

class _LocalMatchBanner extends StatelessWidget {
  const _LocalMatchBanner();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('tug-local-match-banner'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      children: [
        Icon(Icons.smart_toy_outlined, size: 18),
        SizedBox(width: 8),
        Expanded(child: Text('Duelo de práctica contra CPU · Sin anuncios')),
      ],
    ),
  );
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({
    required this.questionNumber,
    required this.secondsRemaining,
    required this.ropePosition,
  });

  final int questionNumber;
  final int secondsRemaining;
  final int ropePosition;

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
          label: '${ropePosition > 0 ? '+' : ''}$ropePosition',
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

class _ArenaPreparationCard extends StatelessWidget {
  const _ArenaPreparationCard();

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: const Card(
      key: Key('tug-arena-preparing'),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Los competidores están entrando. El tiempo aún no corre.',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ResolvingRoundCard extends StatelessWidget {
  const _ResolvingRoundCard({required this.resolution});

  final TugRoundResolution resolution;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: '${resolution.title}. La cuerda está en movimiento.',
    child: Card(
      key: const Key('tug-round-resolving'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resolution.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('La cuerda está en movimiento…'),
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
          ],
        ),
      ),
    ),
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
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: '${resolution.title}. ${resolution.explanation}',
    child: Card(
      key: const Key('tug-round-feedback'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              resolution.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
              label: Text(
                isMatchPoint ? 'Ver resultado' : 'Siguiente pregunta',
              ),
            ),
          ],
        ),
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
                'Esta partida de práctica local no afecta XP, rachas, estadísticas ni rankings.',
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
