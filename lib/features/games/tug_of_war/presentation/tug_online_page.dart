import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/config/resource_url.dart';
import '../../../../core/feedback/game_audio_feedback.dart';
import '../domain/tug_online_models.dart';
import '../domain/tug_of_war_models.dart';
import 'animation/tug_animation_cue.dart';
import 'animation/tug_arena.dart';
import 'tug_of_war_providers.dart';

class TugOnlinePage extends ConsumerStatefulWidget {
  const TugOnlinePage({required this.config, super.key});

  final TugOnlineConfig config;

  @override
  ConsumerState<TugOnlinePage> createState() => _TugOnlinePageState();
}

class _TugOnlinePageState extends ConsumerState<TugOnlinePage> {
  Timer? _clock;
  Timer? _feedbackTimer;
  var _showFeedback = false;
  int? _activeEffectVersion;
  int? _playedResultVersion;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = tugOnlineControllerProvider(widget.config.area);
    ref.listen(provider, _handleStateChange);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final snapshot = state.snapshot;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_exit(controller, snapshot));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tira y afloja en línea'),
          leading: IconButton(
            onPressed: () => _exit(controller, snapshot),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: SafeArea(
          child: switch (snapshot?.status) {
            null => _ConnectingView(
              state: state,
              areaLabel: widget.config.area?.label ?? 'Todas las áreas',
              onRetry: controller.retry,
              onLocal: _goToLocal,
            ),
            TugOnlineMatchStatus.searching => _SearchingView(
              areaLabel: snapshot?.area?.label ?? 'Todas las áreas',
              connectionStatus: state.connectionStatus,
              errorMessage: state.errorMessage,
            ),
            TugOnlineMatchStatus.preparing => _PreparingView(
              snapshot: snapshot!,
              state: state,
              onReady: controller.ready,
            ),
            TugOnlineMatchStatus.active => _buildArena(state, controller),
            TugOnlineMatchStatus.finished when state.effect != null =>
              _buildArena(state, controller),
            TugOnlineMatchStatus.finished => _OnlineResultView(
              snapshot: snapshot!,
              onReplay: () => context.go(
                TugOnlineConfig(area: widget.config.area).routeLocation,
              ),
              onLocal: _goToLocal,
            ),
            TugOnlineMatchStatus.cancelled ||
            TugOnlineMatchStatus.expired => _EndedView(
              expired: snapshot?.status == TugOnlineMatchStatus.expired,
              onRetry: () => context.go(
                TugOnlineConfig(area: widget.config.area).routeLocation,
              ),
              onLocal: _goToLocal,
            ),
          },
        ),
      ),
    );
  }

  Widget _buildArena(TugOnlineUiState state, TugOnlineController controller) {
    final snapshot = state.snapshot!;
    final effect = state.effect;
    final question = snapshot.question;
    final startsIn = snapshot.timeUntilRoundStarts;
    final endsIn = snapshot.timeUntilRoundEnds;
    final roundStarted = startsIn <= Duration.zero;
    final timeRemaining = endsIn.isNegative ? Duration.zero : endsIn;
    final seconds = (timeRemaining.inMilliseconds / 1000).ceil().clamp(0, 10);
    final animationCue = effect == null
        ? null
        : TugAnimationCue(
            id: effect.version,
            fromPosition: effect.fromPosition,
            toPosition: effect.toPosition,
            outcome: effect.resolution.outcome,
            bothCorrect: effect.bothCorrect,
            winner: effect.winner,
          );
    return ListView(
      key: const Key('tug-online-arena'),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      children: [
        _ConnectionBanner(state: state),
        const SizedBox(height: 10),
        _OnlineMatchHeader(
          snapshot: snapshot,
          seconds: seconds,
          startsIn: startsIn,
        ),
        const SizedBox(height: 10),
        TugArena(
          roundId: snapshot.round,
          ropePosition: effect?.toPosition ?? snapshot.ropePosition,
          playerAnswered: snapshot.alreadyAnswered,
          cpuAnswered: effect != null,
          animationCue: animationCue,
          paused: state.connectionStatus == TugOnlineConnectionStatus.failed,
          onReady: (_) {},
          onSequenceCompleted: _handleAnimationCompleted,
          onSoundCue: _handleArenaSound,
        ),
        const SizedBox(height: 14),
        if (effect != null)
          _OnlineRoundFeedback(effect: effect, showDetails: _showFeedback)
        else if (question != null) ...[
          if (!roundStarted)
            _CountdownCard(duration: startsIn)
          else ...[
            Text(
              '${question.area.label} · ${question.subtopic}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question.statement,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (question.imageUrl case final imageUrl?) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          resolveResourceUrl(
                            ref.watch(appConfigProvider),
                            imageUrl,
                          ),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Text(
                            'La imagen de esta pregunta no está disponible.',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            for (final option in question.options) ...[
              OutlinedButton(
                key: Key('tug-online-answer-${option.id}'),
                onPressed:
                    !roundStarted ||
                        timeRemaining == Duration.zero ||
                        snapshot.alreadyAnswered ||
                        state.submitting
                    ? null
                    : () => controller.answer(option.id),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: state.selectedAnswerId == option.id
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                child: Text(option.text),
              ),
              const SizedBox(height: 8),
            ],
            if (snapshot.alreadyAnswered || state.submitting)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_top_rounded),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Respuesta guardada. Esperando la resolución del servidor…',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  void _handleStateChange(TugOnlineUiState? previous, TugOnlineUiState next) {
    if (previous?.snapshot?.rival == null && next.snapshot?.rival != null) {
      unawaited(ref.read(gameAudioFeedbackProvider).play(GameSound.matchFound));
    }
    final effect = next.effect;
    if (effect != null && effect.version != _activeEffectVersion) {
      _activeEffectVersion = effect.version;
      _feedbackTimer?.cancel();
      if (mounted) setState(() => _showFeedback = false);
    }
    final winner = next.snapshot?.winner;
    if (winner != null && next.effect == null) {
      final version = next.snapshot!.version;
      if (_playedResultVersion != version) {
        _playedResultVersion = version;
        final sound = winner == TugWinner.player
            ? GameSound.matchVictory
            : winner == TugWinner.cpu
            ? GameSound.matchDefeat
            : GameSound.triviaFinish;
        unawaited(ref.read(gameAudioFeedbackProvider).play(sound));
      }
    }
  }

  void _handleAnimationCompleted(int cueId) {
    if (cueId != _activeEffectVersion || !mounted) return;
    setState(() => _showFeedback = true);
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      ref
          .read(tugOnlineControllerProvider(widget.config.area).notifier)
          .clearEffect();
    });
  }

  void _handleArenaSound(TugArenaSoundCue cue) {
    final sound = cue == TugArenaSoundCue.pull
        ? GameSound.tugPull
        : GameSound.tugRopeStrain;
    unawaited(ref.read(gameAudioFeedbackProvider).play(sound));
  }

  Future<void> _exit(
    TugOnlineController controller,
    TugOnlineSnapshot? snapshot,
  ) async {
    if (snapshot == null ||
        snapshot.status == TugOnlineMatchStatus.finished ||
        snapshot.status == TugOnlineMatchStatus.cancelled ||
        snapshot.status == TugOnlineMatchStatus.expired) {
      if (mounted) context.go('/student/practice/tug-of-war');
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la partida en línea?'),
        content: Text(
          snapshot.rival == null
              ? 'Se cancelará la búsqueda de rival.'
              : 'Abandonar entregará la victoria a tu rival.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            key: const Key('confirm-exit-online-tug'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (leave != true) return;
    await controller.abandon();
    if (mounted) context.go('/student/practice/tug-of-war');
  }

  void _goToLocal() => context.go('/student/practice/tug-of-war');
}

class _ConnectingView extends StatelessWidget {
  const _ConnectingView({
    required this.state,
    required this.areaLabel,
    required this.onRetry,
    required this.onLocal,
  });

  final TugOnlineUiState state;
  final String areaLabel;
  final VoidCallback onRetry;
  final VoidCallback onLocal;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.public_rounded, size: 58),
          const SizedBox(height: 16),
          Text(
            state.connectionStatus == TugOnlineConnectionStatus.failed
                ? 'No pudimos entrar al modo en línea'
                : 'Conectando con SaberPlus…',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text('$areaLabel · Partida sin anuncios'),
          if (state.errorMessage case final message?) ...[
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ] else ...[
            const SizedBox(height: 18),
            const CircularProgressIndicator(),
          ],
          const SizedBox(height: 18),
          if (state.connectionStatus == TugOnlineConnectionStatus.failed)
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          TextButton(onPressed: onLocal, child: const Text('Jugar contra CPU')),
        ],
      ),
    ),
  );
}

class _SearchingView extends StatelessWidget {
  const _SearchingView({
    required this.areaLabel,
    required this.connectionStatus,
    required this.errorMessage,
  });

  final String areaLabel;
  final TugOnlineConnectionStatus connectionStatus;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Buscando un rival…',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(areaLabel),
          const SizedBox(height: 12),
          const Text(
            'Puedes cancelar con la X. La búsqueda vence automáticamente si no encuentra rival.',
            textAlign: TextAlign.center,
          ),
          if (connectionStatus == TugOnlineConnectionStatus.reconnecting) ...[
            const SizedBox(height: 12),
            const Text('Reconectando…'),
          ],
          if (errorMessage case final message?) ...[
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
          ],
        ],
      ),
    ),
  );
}

class _PreparingView extends StatelessWidget {
  const _PreparingView({
    required this.snapshot,
    required this.state,
    required this.onReady,
  });

  final TugOnlineSnapshot snapshot;
  final TugOnlineUiState state;
  final Future<void> Function() onReady;

  @override
  Widget build(BuildContext context) => ListView(
    key: const Key('tug-online-preparing'),
    padding: const EdgeInsets.all(24),
    children: [
      const Icon(Icons.sports_kabaddi_rounded, size: 62),
      const SizedBox(height: 18),
      Text(
        '¡Rival encontrado!',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 20),
      _PlayerTile(
        name: snapshot.me.name,
        label: snapshot.iAmReady ? 'Listo' : 'Esperando tu confirmación',
        ready: snapshot.iAmReady,
      ),
      const SizedBox(height: 10),
      _PlayerTile(
        name: snapshot.rival?.name ?? 'Rival',
        label: snapshot.side == 'A'
            ? snapshot.readyB
                  ? 'Listo'
                  : 'Preparándose'
            : snapshot.readyA
            ? 'Listo'
            : 'Preparándose',
        ready: snapshot.side == 'A' ? snapshot.readyB : snapshot.readyA,
      ),
      const SizedBox(height: 22),
      FilledButton.icon(
        key: const Key('ready-online-tug'),
        onPressed: snapshot.iAmReady || state.submitting ? null : onReady,
        icon: const Icon(Icons.check_rounded),
        label: Text(snapshot.iAmReady ? 'Esperando al rival' : 'Estoy listo'),
      ),
      if (state.errorMessage case final message?) ...[
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center),
      ],
    ],
  );
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.name,
    required this.label,
    required this.ready,
  });

  final String name;
  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(child: Text(name.characters.first.toUpperCase())),
      title: Text(name),
      subtitle: Text(label),
      trailing: Icon(
        ready ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
      ),
    ),
  );
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.state});

  final TugOnlineUiState state;

  @override
  Widget build(BuildContext context) {
    final reconnecting =
        state.connectionStatus == TugOnlineConnectionStatus.reconnecting;
    final text = reconnecting
        ? 'Reconectando con el servidor…'
        : !state.rivalConnected
        ? 'Tu rival perdió conexión; puede regresar a la partida.'
        : 'Duelo en línea · Servidor autoritativo · Sin anuncios';
    return Container(
      key: const Key('tug-online-connection-banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            reconnecting || !state.rivalConnected
                ? Icons.cloud_off_outlined
                : Icons.cloud_done_outlined,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _OnlineMatchHeader extends StatelessWidget {
  const _OnlineMatchHeader({
    required this.snapshot,
    required this.seconds,
    required this.startsIn,
  });

  final TugOnlineSnapshot snapshot;
  final int seconds;
  final Duration startsIn;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          'Ronda ${snapshot.round}/${snapshot.totalQuestions}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      Text(snapshot.rival?.name ?? 'Rival'),
      const SizedBox(width: 10),
      Chip(
        avatar: const Icon(Icons.timer_outlined, size: 18),
        label: Text(
          startsIn > Duration.zero
              ? '${(startsIn.inMilliseconds / 1000).ceil()}…'
              : '$seconds s',
        ),
      ),
    ],
  );
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Text(
        'La siguiente pregunta comienza en ${(duration.inMilliseconds / 1000).ceil().clamp(1, 3)}…',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    ),
  );
}

class _OnlineRoundFeedback extends StatelessWidget {
  const _OnlineRoundFeedback({required this.effect, required this.showDetails});

  final TugOnlineRoundEffect effect;
  final bool showDetails;

  @override
  Widget build(BuildContext context) => Card(
    key: const Key('tug-online-round-feedback'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(
            showDetails ? effect.resolution.title : 'Resolviendo ronda…',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            showDetails
                ? effect.resolution.explanation
                : 'El servidor está moviendo la cuerda.',
            textAlign: TextAlign.center,
          ),
          if (showDetails)
            if (effect.answerExplanation case final text?) ...[
              const SizedBox(height: 10),
              Text(text, textAlign: TextAlign.center),
            ],
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}

class _OnlineResultView extends StatelessWidget {
  const _OnlineResultView({
    required this.snapshot,
    required this.onReplay,
    required this.onLocal,
  });

  final TugOnlineSnapshot snapshot;
  final VoidCallback onReplay;
  final VoidCallback onLocal;

  @override
  Widget build(BuildContext context) {
    final winner = snapshot.winner ?? TugWinner.draw;
    final (icon, title, message) = switch (winner) {
      TugWinner.player => (
        Icons.emoji_events_rounded,
        '¡Ganaste el duelo!',
        'La cuerda llegó a tu lado.',
      ),
      TugWinner.cpu => (
        Icons.sports_score_rounded,
        'Ganó ${snapshot.rival?.name ?? 'tu rival'}',
        'Repasa las preguntas y vuelve a intentarlo.',
      ),
      TugWinner.draw => (
        Icons.handshake_outlined,
        'Partida empatada',
        'La cuerda terminó exactamente en el centro.',
      ),
    };
    return ListView(
      key: const Key('tug-online-result'),
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 40),
      children: [
        Icon(icon, size: 72),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onReplay,
          icon: const Icon(Icons.public_rounded),
          label: const Text('Buscar otro rival'),
        ),
        TextButton(onPressed: onLocal, child: const Text('Jugar contra CPU')),
      ],
    );
  }
}

class _EndedView extends StatelessWidget {
  const _EndedView({
    required this.expired,
    required this.onRetry,
    required this.onLocal,
  });

  final bool expired;
  final VoidCallback onRetry;
  final VoidCallback onLocal;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_off_outlined, size: 56),
          const SizedBox(height: 14),
          Text(
            expired ? 'La partida venció' : 'La partida fue cancelada',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          FilledButton(onPressed: onRetry, child: const Text('Buscar rival')),
          TextButton(onPressed: onLocal, child: const Text('Jugar contra CPU')),
        ],
      ),
    ),
  );
}
