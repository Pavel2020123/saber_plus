import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/environment.dart';
import '../../../core/config/resource_url.dart';
import '../../../core/feedback/answer_streak_feedback.dart';
import '../../../core/network/api_error.dart';
import '../../../core/sync/drift_safe_sync_repository.dart';
import '../../../core/widgets/animated_streak_flame.dart';
import '../../../core/wellbeing/study_break_reminder.dart';
import '../../academic/domain/academic_models.dart';
import '../../auth/presentation/session_controller.dart';
import '../../difficult_questions/data/drift_difficult_question_repository.dart';
import '../../difficult_questions/domain/difficult_question_models.dart';
import '../../difficult_questions/presentation/difficult_question_providers.dart';
import '../../focus/presentation/pomodoro_card.dart';
import '../../historical_simulations/presentation/historical_simulation_providers.dart';
import '../../progress/presentation/progress_providers.dart';
import '../../study/presentation/study_providers.dart';
import '../../study_time/domain/study_time_models.dart';
import '../../study_time/presentation/study_time_providers.dart';
import '../data/practice_draft_store.dart';
import '../domain/correct_answer_streak.dart';
import '../domain/practice_models.dart';
import 'practice_providers.dart';

class PracticeSessionPage extends ConsumerStatefulWidget {
  const PracticeSessionPage({
    super.key,
    required this.area,
    required this.subtopicId,
  }) : randomConfig = null,
       isSimulation = false,
       adaptiveQuestionCount = null,
       officialBlock = null,
       historicalEditionId = null,
       historicalBlock = null,
       timeTrialConfig = null;

  const PracticeSessionPage.random({super.key, required this.randomConfig})
    : area = null,
      subtopicId = null,
      isSimulation = false,
      adaptiveQuestionCount = null,
      officialBlock = null,
      historicalEditionId = null,
      historicalBlock = null,
      timeTrialConfig = null;

  const PracticeSessionPage.simulation({super.key, required this.area})
    : subtopicId = null,
      randomConfig = null,
      isSimulation = true,
      adaptiveQuestionCount = null,
      officialBlock = null,
      historicalEditionId = null,
      historicalBlock = null,
      timeTrialConfig = null;

  const PracticeSessionPage.adaptive({super.key, required int questionCount})
    : area = null,
      subtopicId = null,
      randomConfig = null,
      isSimulation = false,
      adaptiveQuestionCount = questionCount,
      officialBlock = null,
      historicalEditionId = null,
      historicalBlock = null,
      timeTrialConfig = null;

  const PracticeSessionPage.official({super.key, required this.officialBlock})
    : area = null,
      subtopicId = null,
      randomConfig = null,
      isSimulation = false,
      adaptiveQuestionCount = null,
      historicalEditionId = null,
      historicalBlock = null,
      timeTrialConfig = null;

  const PracticeSessionPage.historical({
    super.key,
    required this.historicalEditionId,
    required this.historicalBlock,
  }) : area = null,
       subtopicId = null,
       randomConfig = null,
       isSimulation = false,
       adaptiveQuestionCount = null,
       officialBlock = null,
       timeTrialConfig = null;

  const PracticeSessionPage.timeTrial({
    super.key,
    required this.timeTrialConfig,
  }) : area = null,
       subtopicId = null,
       randomConfig = null,
       isSimulation = false,
       adaptiveQuestionCount = null,
       officialBlock = null,
       historicalEditionId = null,
       historicalBlock = null;

  final AcademicArea? area;
  final String? subtopicId;
  final RandomPracticeConfig? randomConfig;
  final bool isSimulation;
  final int? adaptiveQuestionCount;
  final OfficialSimulationBlock? officialBlock;
  final String? historicalEditionId;
  final OfficialSimulationBlock? historicalBlock;
  final TimeTrialConfig? timeTrialConfig;

  @override
  ConsumerState<PracticeSessionPage> createState() =>
      _PracticeSessionPageState();
}

class _PracticeSessionPageState extends ConsumerState<PracticeSessionPage>
    with WidgetsBindingObserver {
  PracticeSession? _session;
  PracticeResult? _result;
  Object? _loadError;
  final _selections = <String, String>{};
  final _responseSeconds = <String, int>{};
  var _currentIndex = 0;
  var _loading = true;
  var _submitting = false;
  var _submissionUncertain = false;
  DateTime? _questionEnteredAt;
  DateTime? _sessionStartedAt;
  DateTime? _expiresAt;
  Timer? _clock;
  var _focusLossCount = 0;
  var _outsideApp = false;
  var _timeTrialExpired = false;
  var _handlingTimeTrialExpiry = false;

  bool get _isRandom => widget.randomConfig != null;
  bool get _isSimulation => widget.isSimulation;
  bool get _isAdaptive => widget.adaptiveQuestionCount != null;
  bool get _isOfficial => widget.officialBlock != null;
  bool get _isHistorical => widget.historicalEditionId != null;
  bool get _isTimeTrial => widget.timeTrialConfig != null;
  bool get _tracksIntegrity => _isOfficial || _isHistorical;
  bool get _usesRandomEndpoint => _isRandom || _isOfficial || _isTimeTrial;
  bool get _isSubtopic =>
      !_isRandom &&
      !_isSimulation &&
      !_isAdaptive &&
      !_isOfficial &&
      !_isHistorical &&
      !_isTimeTrial;
  String get _draftId => _isAdaptive
      ? 'adaptive:${widget.adaptiveQuestionCount}'
      : _isTimeTrial
      ? 'time-trial'
      : _isHistorical
      ? 'historical:${widget.historicalEditionId}:${widget.historicalBlock!.slug}'
      : _isOfficial
      ? 'official:${widget.officialBlock!.slug}'
      : _isRandom
      ? 'random'
      : _isSimulation
      ? 'simulation:${widget.area!.backendValue}'
      : 'subtopic:${widget.subtopicId!}';
  String? get _userId => ref.read(sessionControllerProvider).user?.id;
  DateTime get _now => ref.read(practiceNowProvider)();
  Duration get _remainingTime {
    final expiresAt = _expiresAt;
    if (expiresAt == null) return Duration.zero;
    final remaining = expiresAt.difference(_now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPractice();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_tracksIntegrity || _session == null || _result != null) return;
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        !_outsideApp) {
      _outsideApp = true;
      _recordCurrentTime();
      setState(() => _focusLossCount = (_focusLossCount + 1).clamp(0, 999));
      unawaited(_persistDraft());
      return;
    }
    if (state == AppLifecycleState.resumed && _outsideApp) {
      _outsideApp = false;
      _questionEnteredAt = _now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Regresaste al simulacro. La salida de la app quedó registrada.',
          ),
        ),
      );
    }
  }

  Future<void> _loadPractice() async {
    _clock?.cancel();
    setState(() {
      _loading = true;
      _loadError = null;
      _result = null;
      _submissionUncertain = false;
      _selections.clear();
      _responseSeconds.clear();
      _currentIndex = 0;
      _session = null;
      _focusLossCount = 0;
      _outsideApp = false;
      _timeTrialExpired = false;
      _handlingTimeTrialExpiry = false;
    });
    try {
      final userId = _userId;
      final store = ref.read(practiceDraftStoreProvider);
      if (userId != null) {
        final draft = await store.read(userId, _draftId);
        if (draft != null && _canRestore(draft)) {
          if (!mounted) return;
          _restoreDraft(draft);
          _startClock();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Intento reanudado.')));
          });
          return;
        }
        if (draft != null) await store.clear(userId, _draftId);
      }

      final session = _isAdaptive
          ? (await ref
                    .read(progressRepositoryProvider)
                    .startAdaptiveSession(widget.adaptiveQuestionCount!))
                .session
          : await _startRegularPractice();
      if (!mounted) return;
      final now = _now;
      setState(() {
        _session = session;
        _loading = false;
        _sessionStartedAt = now;
        _questionEnteredAt = now;
        // Los intentos comunes reservan cinco minutos frente al límite de API.
        // El contrarreloj conserva su límite estricto aunque la app se cierre.
        _expiresAt = now.add(
          Duration(
            minutes: _isTimeTrial ? widget.timeTrialConfig!.minutes : 115,
          ),
        );
      });
      await _persistDraft();
      _startClock();
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  Future<PracticeSession> _startRegularPractice() {
    if (_isHistorical) {
      return ref
          .read(historicalSimulationRepositoryProvider)
          .startEdition(
            editionId: widget.historicalEditionId!,
            block: widget.historicalBlock!,
          );
    }
    final repository = ref.read(practiceRepositoryProvider);
    if (_isTimeTrial) {
      return repository
          .startRandomPractice(widget.timeTrialConfig!.practiceConfig)
          .then(
            (session) => session.asTimeTrial(widget.timeTrialConfig!.minutes),
          );
    }
    if (_isOfficial) {
      return repository
          .startRandomPractice(widget.officialBlock!.practiceConfig)
          .then((session) {
            if (widget.officialBlock!.accepts(session)) return session;
            throw const ApiError(
              code: 'official_simulation_incomplete',
              message:
                  'El banco todavía no puede entregar esta jornada completa de 75 preguntas en las cinco áreas.',
            );
          });
    }
    if (_isRandom) {
      return repository.startRandomPractice(widget.randomConfig!);
    }
    if (_isSimulation) {
      return repository.startAreaSimulation(widget.area!);
    }
    return repository.startSubtopicPractice(
      area: widget.area!,
      subtopicId: widget.subtopicId!,
    );
  }

  bool _canRestore(PracticeDraft draft) {
    if (draft.isExpiredAt(_now) || draft.session.questions.isEmpty) {
      return false;
    }
    if (_usesRandomEndpoint != draft.session.isRandom ||
        _isSimulation != draft.session.isSimulation ||
        _isAdaptive != draft.session.isAdaptive ||
        _isHistorical != draft.session.isHistorical ||
        _isTimeTrial != draft.session.isTimeTrial) {
      return false;
    }
    if (_isAdaptive) return true;
    if (_isTimeTrial) {
      final expected = widget.timeTrialConfig!.areas.toSet();
      final stored = draft.session.areas.toSet();
      return draft.session.timeTrialMinutes ==
              widget.timeTrialConfig!.minutes &&
          expected.length == stored.length &&
          expected.containsAll(stored);
    }
    if (_isHistorical) {
      return draft.session.historicalEditionId == widget.historicalEditionId &&
          draft.session.historicalBlock == widget.historicalBlock &&
          draft.session.questions.length ==
              OfficialSimulationBlock.questionCount &&
          draft.session.areas.toSet().containsAll(AcademicArea.values);
    }
    if (_isOfficial) return widget.officialBlock!.accepts(draft.session);
    if (_isSimulation) return draft.session.area == widget.area;
    if (_isSubtopic) return draft.session.subtopicId == widget.subtopicId;
    final expected = widget.randomConfig!.areas.toSet();
    final stored = draft.session.areas.toSet();
    return expected.length == stored.length && expected.containsAll(stored);
  }

  void _restoreDraft(PracticeDraft draft) {
    final lastIndex = draft.session.questions.length - 1;
    final validSelections = <String, String>{};
    final validTimes = <String, int>{};
    for (final question in draft.session.questions) {
      final answerId = draft.selectedAnswers[question.id];
      if (answerId != null &&
          question.options.any((option) => option.id == answerId)) {
        validSelections[question.id] = answerId;
      }
      final seconds = draft.responseTimesSeconds[question.id];
      if (seconds != null) validTimes[question.id] = seconds.clamp(0, 7200);
    }
    setState(() {
      _session = draft.session;
      _selections
        ..clear()
        ..addAll(validSelections);
      _responseSeconds
        ..clear()
        ..addAll(validTimes);
      _currentIndex = draft.currentIndex.clamp(0, lastIndex);
      _sessionStartedAt = draft.startedAt;
      _expiresAt = draft.expiresAt;
      _questionEnteredAt = _now;
      _loading = false;
      _focusLossCount = draft.focusLossCount;
    });
  }

  void _startClock() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _result != null) return;
      final now = _now;
      if (!(_expiresAt?.isAfter(now) ?? true)) {
        _clock?.cancel();
        if (_isTimeTrial) {
          unawaited(_finishExpiredTimeTrial());
          return;
        }
        unawaited(_clearDraft());
        setState(() {
          _session = null;
          _loadError = const ApiError(
            code: 'practice_expired',
            message: 'Este intento venció. Inicia una práctica nueva.',
          );
        });
        return;
      }
      if (now.second % 10 == 0) {
        _recordCurrentTime();
        unawaited(_persistDraft());
      }
      setState(() {});
    });
  }

  Future<void> _finishExpiredTimeTrial() async {
    if (_handlingTimeTrialExpiry ||
        _submitting ||
        _result != null ||
        !mounted) {
      return;
    }
    _handlingTimeTrialExpiry = true;
    _recordCurrentTime();
    final session = _session;
    if (session != null && _selections.length == session.questions.length) {
      await _clearDraft();
      if (mounted) await _submit();
      return;
    }
    await _clearDraft();
    if (!mounted) return;
    setState(() => _timeTrialExpired = true);
  }

  Future<void> _persistDraft() async {
    final userId = _userId;
    final session = _session;
    final startedAt = _sessionStartedAt;
    final expiresAt = _expiresAt;
    if (userId == null ||
        session == null ||
        startedAt == null ||
        expiresAt == null ||
        _result != null ||
        _submissionUncertain) {
      return;
    }
    await ref
        .read(practiceDraftStoreProvider)
        .save(
          userId,
          _draftId,
          PracticeDraft(
            session: session,
            selectedAnswers: Map.unmodifiable(_selections),
            responseTimesSeconds: Map.unmodifiable(_responseSeconds),
            currentIndex: _currentIndex,
            startedAt: startedAt,
            expiresAt: expiresAt,
            focusLossCount: _focusLossCount,
          ),
        );
  }

  Future<void> _clearDraft() async {
    final userId = _userId;
    if (userId == null) return;
    await ref.read(practiceDraftStoreProvider).clear(userId, _draftId);
  }

  Future<void> _discardAndRestart() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar intento'),
        content: const Text(
          'Se eliminarán las respuestas guardadas y se abrirá un intento nuevo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('confirm-discard-practice-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    await _clearDraft();
    if (mounted) await _loadPractice();
  }

  void _recordCurrentTime() {
    final session = _session;
    final enteredAt = _questionEnteredAt;
    if (session == null || enteredAt == null || session.questions.isEmpty) {
      return;
    }
    final questionId = session.questions[_currentIndex].id;
    final elapsed = _now.difference(enteredAt).inSeconds;
    _responseSeconds[questionId] =
        ((_responseSeconds[questionId] ?? 0) + elapsed).clamp(0, 7200);
    _questionEnteredAt = _now;
  }

  void _goTo(int index) {
    final session = _session;
    if (session == null || index < 0 || index >= session.questions.length) {
      return;
    }
    _recordCurrentTime();
    setState(() => _currentIndex = index);
    unawaited(_persistDraft());
  }

  void _selectAnswer(String questionId, String answerId) {
    _recordCurrentTime();
    setState(() => _selections[questionId] = answerId);
    unawaited(_persistDraft());
  }

  Future<void> _requestSubmit() async {
    final session = _session;
    if (session == null || _submitting || _submissionUncertain) return;
    if (_selections.length != session.questions.length) {
      final missing = session.questions.length - _selections.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Faltan $missing preguntas por responder.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _isTimeTrial
              ? 'Finalizar contrarreloj'
              : _isSimulation || _isOfficial || _isHistorical
              ? 'Finalizar simulacro'
              : _isAdaptive
              ? 'Finalizar repaso'
              : 'Finalizar práctica',
        ),
        content: const Text(
          'Después de enviar, este intento quedará cerrado y podrás revisar las respuestas correctas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir revisando'),
          ),
          FilledButton(
            key: const Key('confirm-submit-practice-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _submit();
  }

  Future<void> _submit() async {
    final session = _session!;
    _recordCurrentTime();
    setState(() => _submitting = true);
    final answers = session.questions
        .map(
          (question) => PracticeAnswer(
            questionId: question.id,
            answerId: _selections[question.id]!,
            responseTimeSeconds: _responseSeconds[question.id] ?? 0,
          ),
        )
        .toList(growable: false);
    try {
      final result = _isAdaptive
          ? (await ref
                    .read(progressRepositoryProvider)
                    .gradeAdaptiveSession(
                      attemptId: session.attemptId,
                      answers: answers,
                    ))
                .result
          : await _gradeRegularPractice(session, answers);
      if (!mounted) return;
      _clock?.cancel();
      unawaited(_recordStudyTime(session, answers));
      await _clearDraft();
      if (!mounted) return;
      setState(() {
        _result = result;
        _submitting = false;
      });
      final answerStreak = CorrectAnswerStreak.fromReview(result.review);
      if (answerStreak.earnsFeedback) {
        unawaited(ref.read(answerStreakFeedbackProvider).play());
      }
      unawaited(
        ref
            .read(sessionControllerProvider.notifier)
            .registerEarnedXp(result.summary.earnedXp),
      );
      if (_isSubtopic) {
        unawaited(_syncProgress(result.summary.percentage.round()));
      }
      if (_isAdaptive) ref.invalidate(adaptiveProfileProvider);
    } on Object catch (error) {
      if (!mounted) return;
      final uncertain =
          error is ApiError &&
          const {
            'network_timeout',
            'network_unavailable',
            'unexpected_error',
          }.contains(error.code);
      setState(() {
        _submitting = false;
        _submissionUncertain = uncertain;
      });
      if (uncertain) {
        await _clearDraft();
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Envío por confirmar'),
            content: const Text(
              'Se perdió la conexión mientras se calificaba. Para evitar un envío duplicado, la app no repetirá este intento automáticamente. Regresa e inicia una sesión nueva cuando tengas conexión.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_messageFor(error))));
      }
    }
  }

  Future<PracticeResult> _gradeRegularPractice(
    PracticeSession session,
    List<PracticeAnswer> answers,
  ) {
    if (_isHistorical) {
      return ref
          .read(historicalSimulationRepositoryProvider)
          .gradeEdition(
            editionId: widget.historicalEditionId!,
            block: widget.historicalBlock!,
            attemptId: session.attemptId,
            answers: answers,
          );
    }
    final repository = ref.read(practiceRepositoryProvider);
    if (_usesRandomEndpoint) {
      return repository.gradeRandomPractice(
        attemptId: session.attemptId,
        answers: answers,
      );
    }
    if (_isSimulation) {
      return repository.gradeAreaSimulation(
        attemptId: session.attemptId,
        area: session.area,
        answers: answers,
      );
    }
    return repository.gradePractice(
      attemptId: session.attemptId,
      area: session.area,
      answers: answers,
    );
  }

  Future<void> _syncProgress(int percentage) async {
    final user = ref.read(sessionControllerProvider).user;
    if (user == null || user.isDemo) return;
    try {
      final result = await ref
          .read(safeSyncRepositoryProvider)
          .saveStudyProgress(
            userId: user.id,
            subtopicId: widget.subtopicId!,
            percentage: percentage,
          );
      if (result.isSynced) ref.invalidate(studyProgressProvider);
    } on Object {
      // La calificación ya es válida aunque falle esta actualización secundaria.
    }
  }

  Future<void> _recordStudyTime(
    PracticeSession session,
    List<PracticeAnswer> answers,
  ) async {
    final userId = ref.read(sessionControllerProvider).user?.id;
    final seconds = answers.fold<int>(
      0,
      (total, answer) => total + answer.responseTimeSeconds,
    );
    if (userId == null || seconds <= 0) return;
    try {
      await ref
          .read(studyTimeRepositoryProvider)
          .record(
            StudyTimeRecord(
              userId: userId,
              eventId: 'practice:${session.attemptId}',
              source: StudyTimeSource.practice,
              durationSeconds: seconds,
              recordedAt: DateTime.now(),
            ),
          );
    } on Object {
      // La calificación confirmada no depende de la métrica local de tiempo.
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          result == null
              ? _isTimeTrial
                    ? 'Prueba contrarreloj'
                    : _isHistorical
                    ? 'Edición histórica · ${widget.historicalBlock!.label}'
                    : _isOfficial
                    ? 'Simulacro 150 · ${widget.officialBlock!.label}'
                    : _isRandom
                    ? 'Preguntas aleatorias'
                    : _isAdaptive
                    ? 'Repaso inteligente'
                    : _isSimulation
                    ? 'Simulacro por área'
                    : 'Práctica'
              : _isTimeTrial
              ? 'Resultado contrarreloj'
              : _isHistorical
              ? 'Resultado histórico · ${widget.historicalBlock!.label}'
              : _isOfficial
              ? 'Resultado · ${widget.officialBlock!.label}'
              : _isSimulation
              ? 'Resultado del simulacro'
              : _isAdaptive
              ? 'Resultado del repaso'
              : 'Resultado de práctica',
        ),
        actions: [
          if (result == null && _session != null)
            IconButton(
              key: const Key('discard-practice-button'),
              tooltip: 'Descartar intento',
              onPressed: _submitting ? null : _discardAndRestart,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
        ],
      ),
      body: StudyBreakReminder(
        enabled:
            result == null &&
            _session != null &&
            !_isSimulation &&
            !_isTimeTrial &&
            !_tracksIntegrity,
        onPromptOpening: _recordCurrentTime,
        onPromptClosed: () => _questionEnteredAt = _now,
        child: switch ((_loading, _loadError, result, _session)) {
          (true, _, _, _) => const Center(child: CircularProgressIndicator()),
          (false, final error?, _, _) => _LoadError(
            message: _messageFor(error),
            onRetry: _loadPractice,
          ),
          (false, _, final value?, final session?) => _PracticeResultView(
            result: value,
            session: session,
            focusLossCount: _tracksIntegrity ? _focusLossCount : 0,
            onRetry: _loadPractice,
            onExit: () => context.pop(),
            exitLabel: _isHistorical
                ? 'Volver a la edición'
                : _isOfficial
                ? 'Volver a las jornadas'
                : _isTimeTrial
                ? 'Volver a contrarreloj'
                : _isRandom
                ? 'Volver a configurar'
                : _isAdaptive
                ? 'Volver a mi perfil'
                : _isSimulation
                ? 'Volver a simulacros'
                : 'Volver a la lección',
          ),
          (false, _, _, final session?) when _timeTrialExpired =>
            _TimeTrialExpiredView(
              answered: _selections.length,
              total: session.questions.length,
              onRetry: _loadPractice,
              onExit: () => context.pop(),
            ),
          (false, _, _, final session?) => _buildSession(session),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildSession(PracticeSession session) {
    final question = session.questions[_currentIndex];
    final selected = _selections[question.id];
    final elapsed = _sessionStartedAt == null
        ? Duration.zero
        : _now.difference(_sessionStartedAt!);
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentIndex + 1) / session.questions.length,
        ),
        if (!_isSimulation && !_tracksIntegrity && !_isTimeTrial)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: PomodoroCard(compact: true),
          ),
        if (_tracksIntegrity)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _IntegrityStatusCard(focusLossCount: _focusLossCount),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pregunta ${_currentIndex + 1} de ${session.questions.length}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _DifficultQuestionButton(
                    question: question,
                    fallbackSubtopicId: session.subtopicId,
                  ),
                  Icon(
                    _isTimeTrial
                        ? Icons.hourglass_bottom_rounded
                        : Icons.timer_outlined,
                    size: 18,
                    color: _isTimeTrial
                        ? _timeTrialColor(context, _remainingTime)
                        : null,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDuration(_isTimeTrial ? _remainingTime : elapsed),
                    key: _isTimeTrial
                        ? const Key('time-trial-countdown')
                        : null,
                    style: _isTimeTrial
                        ? TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _timeTrialColor(context, _remainingTime),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${question.themeName} · ${question.subtopicName}'),
              if (question.caseContent case final caseContent?) ...[
                const SizedBox(height: 16),
                _CaseCard(content: caseContent),
              ],
              const SizedBox(height: 20),
              Text(
                question.statement,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (question.imageUrl case final imageUrl?) ...[
                const SizedBox(height: 14),
                _NetworkResourceImage(value: imageUrl),
              ],
              const SizedBox(height: 18),
              for (var index = 0; index < question.options.length; index++) ...[
                _AnswerOption(
                  key: Key('practice-answer-${question.options[index].id}'),
                  letter: String.fromCharCode(65 + index),
                  option: question.options[index],
                  selected: selected == question.options[index].id,
                  enabled: !_submitting && !_submissionUncertain,
                  onTap: () =>
                      _selectAnswer(question.id, question.options[index].id),
                ),
                const SizedBox(height: 9),
              ],
              if (_submissionUncertain) ...[
                const SizedBox(height: 12),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Este envío quedó por confirmar. No se volverá a enviar para proteger el intento.',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Pregunta anterior',
                  onPressed: _currentIndex > 0
                      ? () => _goTo(_currentIndex - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _currentIndex < session.questions.length - 1
                      ? FilledButton(
                          key: const Key('next-practice-question-button'),
                          onPressed: selected == null || _submissionUncertain
                              ? null
                              : () => _goTo(_currentIndex + 1),
                          child: const Text('Siguiente'),
                        )
                      : FilledButton.icon(
                          key: const Key('submit-practice-button'),
                          onPressed:
                              selected == null ||
                                  _submitting ||
                                  _submissionUncertain
                              ? null
                              : _requestSubmit,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.task_alt_rounded),
                          label: Text(
                            _submitting ? 'Calificando...' : 'Finalizar',
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IntegrityStatusCard extends StatelessWidget {
  const _IntegrityStatusCard({required this.focusLossCount});

  final int focusLossCount;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('simulation-integrity-status'),
    child: ListTile(
      dense: true,
      leading: Icon(
        focusLossCount == 0
            ? Icons.verified_user_outlined
            : Icons.phonelink_erase_outlined,
      ),
      title: Text(
        focusLossCount == 0
            ? 'Integridad activa'
            : '$focusLossCount ${focusLossCount == 1 ? 'salida registrada' : 'salidas registradas'}',
      ),
      subtitle: const Text(
        'Salir de la app no detiene el temporizador del simulacro.',
      ),
    ),
  );
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    super.key,
    required this.letter,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String letter;
  final PracticeOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        width: selected ? 2 : 1,
      ),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            CircleAvatar(radius: 18, child: Text(letter)),
            const SizedBox(width: 13),
            Expanded(child: Text(option.text)),
            if (selected) const Icon(Icons.check_circle_rounded),
          ],
        ),
      ),
    ),
  );
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.content});

  final PracticeCase content;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content.title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(content.context),
          if (content.imageUrl case final imageUrl?) ...[
            const SizedBox(height: 12),
            _NetworkResourceImage(value: imageUrl),
          ],
        ],
      ),
    ),
  );
}

class _NetworkResourceImage extends ConsumerWidget {
  const _NetworkResourceImage({required this.value});

  final String value;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Image.network(
      resolveResourceUrl(ref.watch(appConfigProvider), value),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined),
            SizedBox(width: 8),
            Text('Imagen no disponible'),
          ],
        ),
      ),
    ),
  );
}

class _PracticeResultView extends StatelessWidget {
  const _PracticeResultView({
    required this.result,
    required this.session,
    required this.onRetry,
    required this.onExit,
    required this.exitLabel,
    this.focusLossCount = 0,
  });

  final PracticeResult result;
  final PracticeSession session;
  final VoidCallback onRetry;
  final VoidCallback onExit;
  final String exitLabel;
  final int focusLossCount;

  @override
  Widget build(BuildContext context) {
    final summary = result.summary;
    final answerStreak = CorrectAnswerStreak.fromReview(result.review);
    final sourceQuestions = {
      for (final question in session.questions) question.id: question,
    };
    return ListView(
      key: const Key('practice-result-view'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const Icon(Icons.workspace_premium_rounded, size: 48),
                const SizedBox(height: 10),
                Text(
                  '${summary.percentage.round()}%',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(
                  '${summary.correctAnswers} correctas de ${summary.totalQuestions}',
                ),
                const SizedBox(height: 8),
                Text('+${summary.earnedXp} XP'),
              ],
            ),
          ),
        ),
        if (focusLossCount > 0) ...[
          const SizedBox(height: 12),
          _IntegrityStatusCard(focusLossCount: focusLossCount),
        ],
        if (answerStreak.earnsFeedback) ...[
          const SizedBox(height: 12),
          Card(
            key: const Key('correct-answer-streak-feedback'),
            child: ListTile(
              leading: AnimatedStreakFlame(
                key: const Key('answer-streak-flame'),
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
              title: Text('¡Racha de ${answerStreak.longestRun} aciertos!'),
              subtitle: const Text(
                'Mantuviste tres o más respuestas correctas consecutivas.',
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Revisión', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        for (var index = 0; index < result.review.length; index++) ...[
          _ReviewCard(
            index: index,
            question: result.review[index],
            sourceQuestion: sourceQuestions[result.review[index].id],
            fallbackSubtopicId: session.subtopicId,
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Practicar de nuevo'),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onExit, child: Text(exitLabel)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.index,
    required this.question,
    required this.sourceQuestion,
    required this.fallbackSubtopicId,
  });

  final int index;
  final PracticeReviewQuestion question;
  final PracticeQuestion? sourceQuestion;
  final String fallbackSubtopicId;

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      initiallyExpanded: !question.isCorrect,
      leading: Icon(
        question.isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
        color: question.isCorrect ? Colors.green.shade700 : Colors.red.shade700,
      ),
      title: Text('Pregunta ${index + 1}'),
      subtitle: Text(question.isCorrect ? 'Correcta' : 'Por reforzar'),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question.statement),
        if (sourceQuestion case final source?) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _DifficultQuestionButton(
              question: source,
              fallbackSubtopicId: fallbackSubtopicId,
              showLabel: true,
            ),
          ),
        ],
        const SizedBox(height: 14),
        for (final option in question.options) ...[
          _ReviewOption(question: question, option: option),
          const SizedBox(height: 8),
        ],
        if (question.explanation case final explanation?) ...[
          const SizedBox(height: 8),
          Text(
            'Cómo se resuelve',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 5),
          Text(explanation),
        ],
      ],
    ),
  );
}

class _DifficultQuestionButton extends ConsumerStatefulWidget {
  const _DifficultQuestionButton({
    required this.question,
    required this.fallbackSubtopicId,
    this.showLabel = false,
  });

  final PracticeQuestion question;
  final String fallbackSubtopicId;
  final bool showLabel;

  @override
  ConsumerState<_DifficultQuestionButton> createState() =>
      _DifficultQuestionButtonState();
}

class _DifficultQuestionButtonState
    extends ConsumerState<_DifficultQuestionButton> {
  var _saving = false;

  Future<void> _toggle() async {
    final userId = ref.read(sessionControllerProvider).user?.id;
    if (userId == null || _saving) return;
    setState(() => _saving = true);
    try {
      final fallback = widget.fallbackSubtopicId.trim();
      final marked = await ref
          .read(difficultQuestionRepositoryProvider)
          .toggle(
            DifficultQuestionMark(
              userId: userId,
              questionId: widget.question.id,
              area: widget.question.area,
              subtopicId:
                  widget.question.subtopicId ??
                  (fallback.isEmpty ? null : fallback),
              subtopicName: widget.question.subtopicName,
              themeName: widget.question.themeName,
              difficulty: widget.question.difficulty,
              markedAt: DateTime.now(),
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            marked
                ? 'Pregunta marcada como difícil.'
                : 'Se quitó de preguntas difíciles.',
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos actualizar la marca.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(
      sessionControllerProvider.select((session) => session.user?.id),
    );
    final marked = ref
        .watch(difficultQuestionStatusProvider(widget.question.id))
        .valueOrNull;
    final isMarked = marked ?? false;
    final onPressed = userId == null || _saving || marked == null
        ? null
        : _toggle;
    final icon = _saving
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(isMarked ? Icons.flag_rounded : Icons.outlined_flag_rounded);
    final label = isMarked ? 'Marcada como difícil' : 'Marcar como difícil';

    if (widget.showLabel) {
      return TextButton.icon(
        key: Key('toggle-difficult-question-${widget.question.id}-review'),
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
      );
    }
    return IconButton(
      key: Key('toggle-difficult-question-${widget.question.id}'),
      tooltip: label,
      onPressed: onPressed,
      icon: icon,
    );
  }
}

class _ReviewOption extends StatelessWidget {
  const _ReviewOption({required this.question, required this.option});

  final PracticeReviewQuestion question;
  final PracticeReviewOption option;

  @override
  Widget build(BuildContext context) {
    final selected = option.id == question.selectedAnswerId;
    final correct = option.isCorrect || option.id == question.correctAnswerId;
    final icon = correct
        ? Icons.check_circle_outline_rounded
        : selected
        ? Icons.cancel_outlined
        : Icons.circle_outlined;
    final color = correct
        ? Colors.green.shade700
        : selected
        ? Colors.red.shade700
        : Theme.of(context).colorScheme.outline;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 9),
              Expanded(child: Text(option.text)),
            ],
          ),
          if (selected || correct) ...[
            const SizedBox(height: 6),
            Text(
              [
                if (selected) 'Tu respuesta',
                if (correct) 'Correcta',
              ].join(' · '),
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
          if (option.explanation case final explanation?) ...[
            const SizedBox(height: 6),
            Text(explanation),
          ],
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.quiz_outlined, size: 52),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

class _TimeTrialExpiredView extends StatelessWidget {
  const _TimeTrialExpiredView({
    required this.answered,
    required this.total,
    required this.onRetry,
    required this.onExit,
  });

  final int answered;
  final int total;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Tiempo agotado',
            key: const Key('time-trial-expired'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Respondiste $answered de $total preguntas.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Este intento no se calificó porque la API actual exige una respuesta para cada pregunta. La app no completará respuestas en tu nombre.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            key: const Key('retry-time-trial-button'),
            onPressed: onRetry,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Intentar de nuevo'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onExit, child: const Text('Volver')),
        ],
      ),
    ),
  );
}

Color _timeTrialColor(BuildContext context, Duration remaining) {
  if (remaining <= const Duration(minutes: 1)) {
    return Theme.of(context).colorScheme.error;
  }
  if (remaining <= const Duration(minutes: 3)) {
    return Colors.orange.shade800;
  }
  return Theme.of(context).colorScheme.primary;
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = duration.inHours;
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

String _messageFor(Object error) => error is ApiError
    ? error.message
    : 'No pudimos cargar esta práctica. Intenta nuevamente.';
