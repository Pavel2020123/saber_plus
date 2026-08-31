import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/network/access_token_store.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../../../academic/domain/academic_models.dart';
import '../data/tug_realtime_client.dart';
import '../domain/tug_online_models.dart';
import '../domain/tug_of_war_models.dart';

typedef TugCpuPlanner = TugCpuTurn Function(TugCpuDifficulty difficulty);

final tugCpuPlannerProvider = Provider<TugCpuPlanner>((ref) {
  final random = Random();
  return (difficulty) => TugCpuTurn.random(difficulty, random);
});

typedef TugRealtimeClientFactory = TugRealtimeClient Function();

final tugRealtimeClientFactoryProvider = Provider<TugRealtimeClientFactory>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  final tokenStore = ref.watch(accessTokenStoreProvider);
  final dio = ref.watch(dioProvider);
  return () => SocketTugRealtimeClient(
    dio,
    apiBaseUrl: config.apiBaseUrl,
    accessToken: tokenStore.accessToken ?? '',
  );
});

enum TugOnlineConnectionStatus { connecting, connected, reconnecting, failed }

class TugOnlineRoundEffect {
  const TugOnlineRoundEffect({
    required this.version,
    required this.fromPosition,
    required this.toPosition,
    required this.resolution,
    required this.winner,
    required this.bothCorrect,
    this.answerExplanation,
  });

  final int version;
  final int fromPosition;
  final int toPosition;
  final TugRoundResolution resolution;
  final TugWinner? winner;
  final bool bothCorrect;
  final String? answerExplanation;
}

class TugOnlineUiState {
  const TugOnlineUiState({
    this.connectionStatus = TugOnlineConnectionStatus.connecting,
    this.snapshot,
    this.effect,
    this.errorMessage,
    this.selectedAnswerId,
    this.submitting = false,
    this.rivalConnected = true,
  });

  final TugOnlineConnectionStatus connectionStatus;
  final TugOnlineSnapshot? snapshot;
  final TugOnlineRoundEffect? effect;
  final String? errorMessage;
  final String? selectedAnswerId;
  final bool submitting;
  final bool rivalConnected;

  TugOnlineUiState copyWith({
    TugOnlineConnectionStatus? connectionStatus,
    TugOnlineSnapshot? snapshot,
    TugOnlineRoundEffect? effect,
    bool clearEffect = false,
    String? errorMessage,
    bool clearError = false,
    String? selectedAnswerId,
    bool clearSelectedAnswer = false,
    bool? submitting,
    bool? rivalConnected,
  }) => TugOnlineUiState(
    connectionStatus: connectionStatus ?? this.connectionStatus,
    snapshot: snapshot ?? this.snapshot,
    effect: clearEffect ? null : effect ?? this.effect,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    selectedAnswerId: clearSelectedAnswer
        ? null
        : selectedAnswerId ?? this.selectedAnswerId,
    submitting: submitting ?? this.submitting,
    rivalConnected: rivalConnected ?? this.rivalConnected,
  );
}

class TugOnlineController extends StateNotifier<TugOnlineUiState> {
  TugOnlineController(this._client, {this.area})
    : super(const TugOnlineUiState()) {
    _subscription = _client.events.listen(_handleEvent);
    _client.connect();
  }

  final TugRealtimeClient _client;
  final AcademicArea? area;
  StreamSubscription<TugRealtimeEvent>? _subscription;
  Timer? _fallbackTimer;
  var _matchmakingRequested = false;
  var _syncing = false;
  var _lastVersion = -1;

  Future<void> ready() => _run(() async {
    final match = state.snapshot;
    if (match != null) await _client.ready(match.id);
  });

  Future<void> answer(String answerId) => _run(() async {
    final match = state.snapshot;
    final question = match?.question;
    if (match == null || question == null || match.alreadyAnswered) return;
    state = state.copyWith(selectedAnswerId: answerId, submitting: true);
    await _client.answer(
      matchId: match.id,
      round: match.round,
      questionId: question.id,
      answerId: answerId,
      idempotencyKey: createTugIdempotencyKey(),
    );
  });

  Future<void> abandon() async {
    final match = state.snapshot;
    if (match == null) return;
    await _run(() => _client.abandon(match.id));
  }

  void clearEffect() => state = state.copyWith(clearEffect: true);

  void retry() {
    state = state.copyWith(
      connectionStatus: TugOnlineConnectionStatus.connecting,
      clearError: true,
    );
    _client.connect();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      state = state.copyWith(clearError: true);
      await action();
    } on Object catch (error) {
      state = state.copyWith(errorMessage: _message(error), submitting: false);
    }
  }

  void _handleEvent(TugRealtimeEvent event) {
    switch (event) {
      case TugRealtimeConnected():
        _fallbackTimer?.cancel();
        state = state.copyWith(
          connectionStatus: TugOnlineConnectionStatus.connected,
          clearError: true,
        );
        if (event.partidaId == null && !_matchmakingRequested) {
          _matchmakingRequested = true;
          unawaited(_run(() => _client.matchmake(area)));
        }
      case TugRealtimeDisconnected():
        state = state.copyWith(
          connectionStatus: TugOnlineConnectionStatus.reconnecting,
        );
        _startFallbackSync();
      case TugRealtimeUpdated():
        final snapshot = state.snapshot;
        if (snapshot == null || snapshot.id != event.partidaId || _syncing) {
          return;
        }
        _syncing = true;
        unawaited(
          _run(
            () => _client
                .synchronize(snapshot.id, sinceVersion: _lastVersion)
                .whenComplete(() => _syncing = false),
          ),
        );
      case TugRealtimePresence():
        if (event.userId == state.snapshot?.rival?.id) {
          state = state.copyWith(rivalConnected: event.connected);
        }
      case TugRealtimeState():
        _applySnapshot(event.snapshot);
      case TugRealtimeFailure():
        if (state.snapshot == null) _matchmakingRequested = false;
        state = state.copyWith(
          connectionStatus: state.snapshot == null
              ? TugOnlineConnectionStatus.failed
              : state.connectionStatus,
          errorMessage: event.message,
          submitting: false,
        );
    }
  }

  void _applySnapshot(TugOnlineSnapshot snapshot) {
    final firstState = state.snapshot == null;
    TugOnlineRoundEffect? effect;
    if (!firstState) {
      final resolved = snapshot.events
          .where(
            (event) =>
                event.version > _lastVersion && event.type == 'RONDA_RESUELTA',
          )
          .lastOrNull;
      if (resolved != null) effect = _effectFrom(snapshot, resolved);
    }
    _lastVersion = snapshot.version;
    state = state.copyWith(
      connectionStatus:
          state.connectionStatus == TugOnlineConnectionStatus.reconnecting
          ? TugOnlineConnectionStatus.reconnecting
          : TugOnlineConnectionStatus.connected,
      snapshot: snapshot,
      effect: effect,
      clearEffect: effect == null,
      clearError: true,
      clearSelectedAnswer: !snapshot.alreadyAnswered,
      submitting: false,
      rivalConnected: snapshot.rival == null ? true : state.rivalConnected,
    );
  }

  TugOnlineRoundEffect _effectFrom(
    TugOnlineSnapshot snapshot,
    TugOnlineEvent event,
  ) {
    final canonicalMovement = event.data['movimiento'] as int? ?? 0;
    final movement = snapshot.side == 'A'
        ? canonicalMovement
        : -canonicalMovement;
    final toPosition = event.data['posicionCuerda'] as int? ?? 0;
    final positionFromMySide = snapshot.side == 'A' ? toPosition : -toPosition;
    final outcome = switch (movement) {
      >= 2 => TugRoundOutcome.strongPlayer,
      1 => TugRoundOutcome.quickPlayer,
      <= -2 => TugRoundOutcome.strongCpu,
      -1 => TugRoundOutcome.quickCpu,
      _ => TugRoundOutcome.neutral,
    };
    final (title, explanation) = switch (movement) {
      >= 2 => ('¡Tirón fuerte para ti!', 'Acertaste y tu rival no.'),
      1 => ('Fuiste más rápido', 'Ambos acertaron, pero respondiste primero.'),
      <= -2 => ('El rival dio un tirón fuerte', 'Tu rival acertó y tú no.'),
      -1 => (
        'El rival fue más rápido',
        'Ambos acertaron y el rival respondió primero.',
      ),
      _ => ('La cuerda no se mueve', 'La ronda terminó sin ventaja.'),
    };
    final academicExplanation = event.data['explicacion'];
    final reason = event.data['motivo'];
    return TugOnlineRoundEffect(
      version: event.version,
      fromPosition: (positionFromMySide - movement).clamp(-4, 4),
      toPosition: positionFromMySide.clamp(-4, 4),
      resolution: TugRoundResolution(
        outcome: outcome,
        ropeDelta: movement,
        title: title,
        explanation: explanation,
      ),
      winner: snapshot.winner,
      bothCorrect:
          reason == 'A_MAS_RAPIDO' ||
          reason == 'B_MAS_RAPIDO' ||
          reason == 'EMPATE_RAPIDEZ',
      answerExplanation: academicExplanation is String
          ? academicExplanation
          : null,
    );
  }

  void _startFallbackSync() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final snapshot = state.snapshot;
      if (snapshot == null || _syncing) return;
      _syncing = true;
      unawaited(
        _run(
          () => _client
              .synchronize(snapshot.id, sinceVersion: _lastVersion)
              .whenComplete(() => _syncing = false),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    unawaited(_subscription?.cancel());
    _client.dispose();
    super.dispose();
  }
}

final tugOnlineControllerProvider = StateNotifierProvider.autoDispose
    .family<TugOnlineController, TugOnlineUiState, AcademicArea?>((ref, area) {
      final controller = TugOnlineController(
        ref.watch(tugRealtimeClientFactoryProvider)(),
        area: area,
      );
      return controller;
    });

String _message(Object error) {
  if (error is ApiError) return error.message;
  if (error case final Exception exception) return exception.toString();
  return 'No fue posible completar la acción.';
}
