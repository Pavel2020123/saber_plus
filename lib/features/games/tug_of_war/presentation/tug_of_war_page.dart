import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/feedback/game_audio_feedback.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/widgets/academic_option_content.dart';
import '../../../practice/domain/practice_models.dart';
import '../../trivia_rush/domain/trivia_rush_models.dart';
import '../../trivia_rush/domain/trivia_rush_repository.dart';
import '../domain/tug_local_repository.dart';
import '../domain/tug_of_war_models.dart';
import 'animation/tug_animation_cue.dart';
import 'animation/tug_arena.dart';
import 'tug_of_war_providers.dart';
import 'tug_local_providers.dart';

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
  TugLocalRound? _localRound;
  bool _serverSyncing = false;
  bool _deadlineReached = false;
  int _elapsedAtClockSync = 0;
  int? _pendingResponseMilliseconds;
  ({int version, bool paused})? _pendingPause;
  Future<void> Function()? _retryRoundAction;
  String? _roundActionError;

  TriviaRushRepository get _repository => ref.read(tugLocalRepositoryProvider);

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
          .read(tugLocalRepositoryProvider)
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
      _localRound = null;
      _serverSyncing = false;
      _deadlineReached = false;
      _elapsedAtClockSync = 0;
      _pendingResponseMilliseconds = null;
      _pendingPause = null;
      _retryRoundAction = null;
      _roundActionError = null;
    });
  }

  Future<void> _handleArenaReady(int roundId) async {
    if (!mounted ||
        roundId != _questionIndex ||
        _roundReady ||
        _serverSyncing ||
        _roundResolution != null ||
        _finished) {
      return;
    }
    final repository = _repository;
    if (repository is TugLocalRepository) {
      setState(() {
        _serverSyncing = true;
        _retryRoundAction = null;
        _roundActionError = null;
      });
      try {
        final round = await repository.beginRound(
          _session!.attemptId,
          _question!.id,
        );
        if (!mounted || roundId != _questionIndex) return;
        if (round.session.serverState!.isTerminal) {
          throw const ApiError(
            code: 'tug_local_expired',
            message: 'El duelo local caducó. Inicia otra partida.',
          );
        }
        setState(() {
          _localRound = round;
          _roundReady = true;
          _serverSyncing = false;
        });
        _applyServerClock(round);
        await _syncRemotePause();
      } on Object catch (error) {
        if (!mounted || roundId != _questionIndex) return;
        _failRoundAction(error, () => _handleArenaReady(roundId));
      }
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

  void _applyServerClock(TugLocalRound round) {
    final now = DateTime.now();
    final remaining = round.remainingAt(now);
    _questionStopwatch?.stop();
    _questionStopwatch = Stopwatch();
    _elapsedAtClockSync = _questionSeconds * 1000 - remaining;
    _roundDeadline = now.add(Duration(milliseconds: remaining));
    _cpuDeadline = _cpuTurn?.isCorrect == null
        ? null
        : now.add(
            Duration(
              milliseconds:
                  _cpuTurn!.responseMilliseconds - _elapsedAtClockSync,
            ),
          );
    setState(() => _secondsRemaining = (remaining / 1000).ceil());
    if (!_competitionPaused && !_shouldPauseCompetition) {
      _questionStopwatch!.start();
    }
  }

  void _failRoundAction(Object error, Future<void> Function() retry) {
    setState(() {
      _serverSyncing = false;
      _submitting = false;
      _retryRoundAction = retry;
      _roundActionError = _errorMessage(error);
    });
  }

  void _queueServerState(TriviaRushServerState? server) {
    if (server == null) return;
    final session = _session!;
    final next = server.isTerminal ? null : server.currentQuestion;
    _session = TriviaRushSession(
      attemptId: session.attemptId,
      questions: [
        ...session.questions,
        if (next != null &&
            !session.questions.any((item) => item.id == next.id))
          next,
      ],
      serverState: server,
    );
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

  Future<void> _answer(String answerId, {bool retry = false}) async {
    final session = _session;
    final question = _question;
    if (session == null ||
        question == null ||
        _submitting ||
        _serverSyncing ||
        (!retry && _retryRoundAction != null) ||
        !_roundReady ||
        _competitionPaused ||
        _animationInProgress ||
        _playerFinished ||
        _roundResolution != null ||
        _finished) {
      return;
    }
    final roundIndex = _questionIndex;
    final elapsedMilliseconds =
        _pendingResponseMilliseconds ??
        (_elapsedAtClockSync + (_questionStopwatch?.elapsedMilliseconds ?? 0))
            .clamp(1, _questionSeconds * 1000);
    setState(() {
      _submitting = true;
      _selectedAnswerId = answerId;
      _pendingResponseMilliseconds = elapsedMilliseconds;
      _retryRoundAction = null;
      _roundActionError = null;
    });
    try {
      final evaluation = await ref
          .read(tugLocalRepositoryProvider)
          .answer(
            attemptId: session.attemptId,
            questionId: question.id,
            answerId: answerId,
            responseTimeSeconds: (elapsedMilliseconds / 1000).ceil(),
          );
      if (!mounted || _playerFinished || roundIndex != _questionIndex) return;
      setState(() {
        _queueServerState(evaluation.serverState);
        _playerCorrect = evaluation.isCorrect;
        _playerResponseMilliseconds = elapsedMilliseconds;
        _playerFinished = true;
        _submitting = false;
      });
      _tryResolveRound();
    } on Object catch (error) {
      if (!mounted || _playerFinished || roundIndex != _questionIndex) return;
      if (_repository is TugLocalRepository) {
        if (error is ApiError && error.code == 'TUG_LOCAL_ROUND_EXPIRED') {
          setState(() {
            _submitting = false;
            _selectedAnswerId = null;
          });
          _finishDeadline();
        } else {
          // A lost ACK must retry the same answer/key, even after the deadline.
          _failRoundAction(error, () => _answer(answerId, retry: true));
        }
        return;
      }
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
    _countdownTimer?.cancel();
    _deadlineReached = true;
    if (_repository is TugLocalRepository && !_playerFinished) {
      setState(() => _cpuAnswered = true);
      if (!_submitting && !_serverSyncing && _retryRoundAction == null) {
        unawaited(_recordTimeout());
      }
      return;
    }
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

  Future<void> _recordTimeout() async {
    final repository = _repository;
    if (repository is! TugLocalRepository || _submitting || _playerFinished) {
      return;
    }
    final roundIndex = _questionIndex;
    setState(() {
      _submitting = true;
      _retryRoundAction = null;
      _roundActionError = null;
    });
    try {
      final state = await repository.expireRound(
        _session!.attemptId,
        _question!.id,
      );
      if (!mounted || roundIndex != _questionIndex) return;
      setState(() {
        _queueServerState(state.serverState);
        _playerCorrect = null;
        _playerResponseMilliseconds = null;
        _playerFinished = true;
        _cpuAnswered = true;
        _submitting = false;
      });
      _tryResolveRound();
    } on Object catch (error) {
      if (!mounted || roundIndex != _questionIndex) return;
      _failRoundAction(error, _recordTimeout);
    }
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

  Future<void> _finishMatch(TugWinner winner) async {
    final repository = _repository;
    if (repository is TugLocalRepository &&
        _session?.serverState?.isTerminal == false) {
      if (_submitting) return;
      setState(() {
        _submitting = true;
        _retryRoundAction = null;
        _roundActionError = null;
      });
      try {
        await repository.abandon(_session!.attemptId);
      } on Object catch (error) {
        if (mounted) _failRoundAction(error, () => _finishMatch(winner));
        return;
      }
      if (!mounted) return;
    }
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
    if (_repository is TugLocalRepository &&
        _roundReady &&
        _roundResolution == null &&
        !_finished &&
        !_playerFinished &&
        _pendingResponseMilliseconds == null) {
      if (_shouldPauseCompetition) {
        _competitionPaused = true;
        _pauseBeganAt ??= DateTime.now();
        _questionStopwatch?.stop();
        _cancelTimerHandles();
      }
      unawaited(_syncRemotePause());
      return;
    }
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

  Future<void> _syncRemotePause() async {
    final repository = _repository;
    if (repository is! TugLocalRepository ||
        _localRound == null ||
        _serverSyncing ||
        _submitting ||
        _playerFinished ||
        _finished) {
      return;
    }
    final roundIndex = _questionIndex;
    setState(() => _serverSyncing = true);
    try {
      while (_pendingPause != null ||
          _localRound!.paused != _shouldPauseCompetition) {
        final operation = _pendingPause ??= (
          version: _localRound!.version,
          paused: _shouldPauseCompetition,
        );
        final round = await repository.setPaused(
          attemptId: _session!.attemptId,
          questionId: _question!.id,
          version: operation.version,
          paused: operation.paused,
        );
        if (!mounted || roundIndex != _questionIndex) return;
        _pendingPause = null;
        _localRound = round;
        if (round.session.serverState!.isTerminal) {
          throw const ApiError(
            code: 'tug_local_expired',
            message: 'El duelo local caducó. Inicia otra partida.',
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _serverSyncing = false;
        _competitionPaused = _shouldPauseCompetition;
        _retryRoundAction = null;
        _roundActionError = null;
      });
      _applyServerClock(_localRound!);
      if (!_competitionPaused) {
        if (_deadlineReached) {
          _finishDeadline();
        } else {
          _scheduleRoundTimers();
        }
      }
    } on Object catch (error) {
      if (!mounted || roundIndex != _questionIndex) return;
      if (error is ApiError && error.code == 'TUG_LOCAL_ROUND_EXPIRED') {
        _pendingPause = null;
        setState(() {
          _serverSyncing = false;
          _competitionPaused = _shouldPauseCompetition;
          _deadlineReached = true;
        });
        if (!_competitionPaused) _finishDeadline();
      } else {
        _failRoundAction(error, _syncRemotePause);
      }
    }
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
            tooltip: 'Abandonar partida',
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
              if (_roundActionError != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _roundActionError!,
                          key: const Key('tug-round-error'),
                        ),
                        TextButton(
                          key: const Key('tug-retry-round'),
                          onPressed: _submitting || _serverSyncing
                              ? null
                              : _retryRoundAction,
                          child: const Text('Reintentar guardado'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_serverSyncing || _submitting)
                const LinearProgressIndicator(key: Key('tug-round-saving')),
              if (_animationInProgress)
                _ResolvingRoundCard(resolution: _roundResolution!)
              else if (_showRoundFeedback)
                _RoundFeedback(
                  resolution: _roundResolution!,
                  playerCorrect: _playerCorrect,
                  playerResponseMilliseconds: _playerResponseMilliseconds,
                  cpuTurn: _cpuTurn!,
                  isMatchPoint: _pendingWinner != null,
                  onContinue: _submitting || _retryRoundAction != null
                      ? null
                      : _continueAfterRound,
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
                            _submitting ||
                            _serverSyncing ||
                            _retryRoundAction != null ||
                            _deadlineReached
                        ? null
                        : () => _answer(option.id),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      minimumSize: const Size.fromHeight(52),
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: _selectedAnswerId == option.id
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                    ),
                    child: AcademicOptionContent(
                      text: option.text,
                      imageUrl: option.imageUrl,
                    ),
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
        if (leave != true) _syncCompetitionPause();
      }
    }
    if (leave == true && mounted) {
      try {
        final repository = _repository;
        if (repository is TugLocalRepository) {
          await repository.abandon(_session!.attemptId);
        }
        if (mounted) context.pop();
      } on Object catch (error) {
        if (mounted) {
          _showMessage(_errorMessage(error));
          _syncCompetitionPause();
        }
      }
    }
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
  final VoidCallback? onContinue;

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
