import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/tug_of_war_models.dart';
import 'tug_animation_cue.dart';
import 'tug_arena_painters.dart';

class TugArena extends StatefulWidget {
  const TugArena({
    required this.roundId,
    required this.ropePosition,
    required this.playerAnswered,
    required this.cpuAnswered,
    required this.animationCue,
    required this.paused,
    required this.onReady,
    required this.onSequenceCompleted,
    required this.onSoundCue,
    super.key,
  });

  final int roundId;
  final int ropePosition;
  final bool playerAnswered;
  final bool cpuAnswered;
  final TugAnimationCue? animationCue;
  final bool paused;
  final ValueChanged<int> onReady;
  final ValueChanged<int> onSequenceCompleted;
  final ValueChanged<TugArenaSoundCue> onSoundCue;

  @override
  State<TugArena> createState() => _TugArenaState();
}

enum _AnswerSide { player, cpu }

class _TugArenaState extends State<TugArena>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _backgroundAsset =
      'assets/images/games/tug_of_war/arena_background.png';
  static const _playerAsset =
      'assets/images/games/tug_of_war/player_fighter.png';
  static const _cpuAsset = 'assets/images/games/tug_of_war/cpu_fighter.png';

  late final AnimationController _entranceController;
  late final AnimationController _ambientController;
  late final AnimationController _actionController;
  late final AnimationController _answerController;
  bool _assetsPrepared = false;
  bool _entranceStarted = false;
  bool _reduceMotion = false;
  bool _strainSoundSent = false;
  bool _pullSoundSent = false;
  bool _lifecyclePaused = false;
  int? _activeCueId;
  int? _completedCueId;
  int? _readyRoundId;
  _AnswerSide? _answerSide;

  bool get _isPaused => widget.paused || _lifecyclePaused;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..addStatusListener(_handleEntranceStatus);
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _actionController = AnimationController(vsync: this)
      ..addListener(_handleActionTick)
      ..addStatusListener(_handleActionStatus);
    _answerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      if (_reduceMotion) {
        _pauseAnimations();
        _entranceController.value = 1;
        _scheduleRoundReady();
        _completeActiveCueImmediately();
      } else {
        _resumeAnimations();
      }
    }
    if (!_assetsPrepared) unawaited(_prepareAssets());
  }

  @override
  void didUpdateWidget(covariant TugArena oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.roundId != oldWidget.roundId) {
      _answerController.reset();
      _answerSide = null;
      _scheduleRoundReady();
    }
    if (widget.paused != oldWidget.paused) {
      if (widget.paused) {
        _pauseAnimations();
      } else {
        _resumeAnimations();
      }
    }
    if (widget.playerAnswered && !oldWidget.playerAnswered) {
      _playAnswerReaction(_AnswerSide.player);
    } else if (widget.cpuAnswered && !oldWidget.cpuAnswered) {
      _playAnswerReaction(_AnswerSide.cpu);
    }
    final cue = widget.animationCue;
    if (cue != null && cue.id != oldWidget.animationCue?.id) {
      _startAction(cue);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lifecyclePaused = false;
      _resumeAnimations();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _lifecyclePaused = true;
      _pauseAnimations();
    }
  }

  void _pauseAnimations() {
    _entranceController.stop();
    _ambientController.stop();
    _actionController.stop();
    _answerController.stop();
  }

  void _resumeAnimations() {
    if (!mounted || _isPaused) return;
    _scheduleRoundReady();
    if (_reduceMotion) {
      if (!_entranceController.isCompleted) {
        _entranceController.value = 1;
        _scheduleRoundReady();
      }
      _completeActiveCueImmediately();
      return;
    }
    if (!_entranceController.isCompleted) {
      if (_entranceStarted) _entranceController.forward();
      return;
    }
    if (_activeCueId != _completedCueId && !_actionController.isCompleted) {
      _actionController.forward();
      return;
    }
    if (_answerController.value > 0 && !_answerController.isCompleted) {
      _answerController.forward();
      return;
    }
    _startAmbient();
  }

  Future<void> _prepareAssets() async {
    _assetsPrepared = true;
    final pendingImages = [
      precacheImage(const AssetImage(_backgroundAsset), context),
      precacheImage(const AssetImage(_playerAsset), context),
      precacheImage(const AssetImage(_cpuAsset), context),
    ];
    _startEntrance();
    try {
      await Future.wait(pendingImages);
    } on Object {
      // Cada Image.asset conserva un fallback visual si un recurso falla.
    }
  }

  void _startEntrance() {
    if (!mounted || _entranceStarted) return;
    _entranceStarted = true;
    if (_reduceMotion) {
      _entranceController.value = 1;
      _scheduleRoundReady();
    } else if (!_isPaused) {
      _entranceController.forward(from: 0);
    }
  }

  void _handleEntranceStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _startAmbient();
    _scheduleRoundReady();
  }

  void _scheduleRoundReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _isPaused ||
          !_entranceController.isCompleted ||
          _readyRoundId == widget.roundId) {
        return;
      }
      _readyRoundId = widget.roundId;
      widget.onReady(widget.roundId);
    });
  }

  void _startAmbient() {
    if (_reduceMotion ||
        !_entranceController.isCompleted ||
        _actionController.isAnimating ||
        _isPaused ||
        !mounted) {
      return;
    }
    if (!_ambientController.isAnimating) {
      _ambientController.repeat(reverse: true);
    }
  }

  void _playAnswerReaction(_AnswerSide side) {
    if (_reduceMotion || _actionController.isAnimating || _isPaused) return;
    _answerSide = side;
    _answerController.forward(from: 0);
  }

  void _startAction(TugAnimationCue cue) {
    _activeCueId = cue.id;
    _completedCueId = null;
    _strainSoundSent = false;
    _pullSoundSent = false;
    _ambientController.stop();
    _answerController.stop();
    _actionController
      ..stop()
      ..value = 0;
    _actionController.duration = cue.duration;
    if (_reduceMotion) {
      _emitReducedMotionSounds(cue);
      _actionController.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifySequenceCompleted(cue.id);
      });
    } else if (!_isPaused) {
      _actionController.forward(from: 0);
    }
  }

  void _handleActionTick() {
    final cue = widget.animationCue;
    if (cue == null || cue.id != _activeCueId || _reduceMotion) return;
    final actionSpan =
        cue.actionDuration.inMicroseconds / cue.duration.inMicroseconds;
    final actionTime = (_actionController.value / actionSpan).clamp(0.0, 1.0);
    final strainThreshold = cue.isStrongPull ? 0.22 : 0.08;
    if (!_strainSoundSent &&
        (cue.isStrongPull || cue.isSpeedTie) &&
        actionTime >= strainThreshold) {
      _strainSoundSent = true;
      widget.onSoundCue(TugArenaSoundCue.ropeStrain);
    }
    final pullThreshold = cue.isStrongPull ? 0.34 : 0.21;
    if (!_pullSoundSent && !cue.isNeutral && actionTime >= pullThreshold) {
      _pullSoundSent = true;
      widget.onSoundCue(TugArenaSoundCue.pull);
    }
  }

  void _handleActionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _reduceMotion) return;
    final cueId = _activeCueId;
    if (cueId != null) _notifySequenceCompleted(cueId);
    _startAmbient();
  }

  void _emitReducedMotionSounds(TugAnimationCue cue) {
    if (!_strainSoundSent && (cue.isStrongPull || cue.isSpeedTie)) {
      _strainSoundSent = true;
      widget.onSoundCue(TugArenaSoundCue.ropeStrain);
    }
    if (!_pullSoundSent && !cue.isNeutral) {
      _pullSoundSent = true;
      widget.onSoundCue(TugArenaSoundCue.pull);
    }
  }

  void _completeActiveCueImmediately() {
    final cue = widget.animationCue;
    if (cue == null || cue.id == _completedCueId) return;
    _actionController.value = 1;
    _emitReducedMotionSounds(cue);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifySequenceCompleted(cue.id);
    });
  }

  void _notifySequenceCompleted(int cueId) {
    if (!mounted ||
        _completedCueId == cueId ||
        widget.animationCue?.id != cueId) {
      return;
    }
    _completedCueId = cueId;
    widget.onSequenceCompleted(cueId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entranceController
      ..removeStatusListener(_handleEntranceStatus)
      ..dispose();
    _ambientController.dispose();
    _actionController
      ..removeListener(_handleActionTick)
      ..removeStatusListener(_handleActionStatus)
      ..dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const Key('tug-arena'),
    child: AnimatedBuilder(
      animation: Listenable.merge([
        _entranceController,
        _ambientController,
        _actionController,
        _answerController,
      ]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = (width * 0.61).clamp(196.0, 254.0);
          return SizedBox(
            height: height,
            child: _buildArena(context, Size(width, height)),
          );
        },
      ),
    ),
  );

  Widget _buildArena(BuildContext context, Size size) {
    final scheme = Theme.of(context).colorScheme;
    final entrance = _reduceMotion
        ? 1.0
        : Curves.easeOutCubic.transform(_entranceController.value);
    final ambient = _reduceMotion
        ? 0.0
        : math.sin(_ambientController.value * math.pi);
    final cue = widget.animationCue;
    final totalTime = _reduceMotion ? 1.0 : _actionController.value;
    final actionSpan = cue == null
        ? 1.0
        : cue.actionDuration.inMicroseconds / cue.duration.inMicroseconds;
    final actionTime = cue == null
        ? 0.0
        : (totalTime / actionSpan).clamp(0.0, 1.0);
    final celebrationTime = cue?.winner == null
        ? 0.0
        : ((totalTime - actionSpan) / (1 - actionSpan)).clamp(0.0, 1.0);
    final direction = cue?.ropeDelta.sign ?? 0;
    final pullStart = cue?.isStrongPull == true ? 0.34 : 0.21;
    final pullEnd = cue?.isStrongPull == true ? 0.75 : 0.66;
    final pullProgress = cue == null || cue.isNeutral
        ? 0.0
        : _interval(actionTime, pullStart, pullEnd, Curves.easeOutCubic);
    final settle = cue == null
        ? 0.0
        : _interval(actionTime, pullEnd, 1, Curves.easeOutBack);
    final overshoot = cue == null || cue.isNeutral
        ? 0.0
        : math.sin(settle * math.pi) * 0.08 * direction;
    final visualRopePosition = cue == null
        ? widget.ropePosition.toDouble()
        : _lerp(
                cue.fromPosition.toDouble(),
                cue.toPosition.toDouble(),
                pullProgress,
              ) +
              overshoot;
    final tension = cue == null
        ? 0.62 + ambient * 0.08
        : cue.isSpeedTie
        ? 0.72 + math.sin(actionTime * math.pi) * 0.28
        : cue.isNeutral
        ? 0.5
        : 0.72 + _interval(actionTime, 0.1, pullStart, Curves.easeIn) * 0.28;
    final vibration = cue?.isSpeedTie == true
        ? math.sin(actionTime * math.pi * 8) *
              2.2 *
              math.sin(actionTime * math.pi)
        : cue != null && !cue.isNeutral
        ? math.sin(settle * math.pi * 4) * 1.2 * (1 - settle)
        : math.sin(_ambientController.value * math.pi * 2) * 0.6;

    final markSpacing = size.width * 0.40 / 8;
    final ropeShift = -visualRopePosition * markSpacing;
    final baseCharacterShift = ropeShift * 0.38;
    final anticipation = cue == null
        ? 0.0
        : _interval(
            actionTime,
            0,
            cue.isStrongPull ? 0.22 : 0.18,
            Curves.easeInOut,
          );
    final force = cue == null
        ? 0.0
        : math.sin(pullProgress * math.pi / 2).clamp(0.0, 1.0);
    final strong = cue?.isStrongPull == true;
    final loserSlide = strong ? 14.0 * force : 7.0 * force;
    final playerWins = direction > 0;
    final cpuWins = direction < 0;
    final playerX =
        baseCharacterShift +
        (playerWins ? -3 * anticipation : 3 * anticipation) +
        (cpuWins ? loserSlide : 0);
    final cpuX =
        baseCharacterShift +
        (cpuWins ? 3 * anticipation : -3 * anticipation) +
        (playerWins ? -loserSlide : 0);
    final answerBounce = _reduceMotion
        ? 0.0
        : math.sin(_answerController.value * math.pi);
    final playerAnswerBounce = _answerSide == _AnswerSide.player
        ? answerBounce
        : 0.0;
    final cpuAnswerBounce = _answerSide == _AnswerSide.cpu ? answerBounce : 0.0;
    final celebrationWave =
        math.sin(celebrationTime * math.pi * 3) * (1 - celebrationTime * 0.45);
    final neutralMiss = cue?.isNeutral == true && !cue!.bothCorrect
        ? math.sin(actionTime * math.pi)
        : 0.0;
    final playerCelebrates = cue?.winner == TugWinner.player;
    final cpuCelebrates = cue?.winner == TugWinner.cpu;
    final playerY =
        -ambient * 1.4 -
        playerAnswerBounce * 4 -
        (playerCelebrates ? celebrationWave.abs() * 10 : 0) +
        (cpuCelebrates ? Curves.easeOut.transform(celebrationTime) * 8 : 0) +
        neutralMiss * 6;
    final cpuY =
        -ambient * 1.2 -
        cpuAnswerBounce * 4 -
        (cpuCelebrates ? celebrationWave.abs() * 10 : 0) +
        (playerCelebrates ? Curves.easeOut.transform(celebrationTime) * 8 : 0) +
        neutralMiss * 6;
    final playerRotation =
        (playerWins
                ? -0.045
                : cpuWins
                ? 0.095
                : 0.0) *
            force +
        (playerCelebrates ? celebrationWave * 0.035 : 0) +
        neutralMiss * 0.035;
    final cpuRotation =
        (cpuWins
                ? 0.045
                : playerWins
                ? -0.095
                : 0.0) *
            force -
        (cpuCelebrates ? celebrationWave * 0.035 : 0) -
        neutralMiss * 0.035;
    final characterWidth = (size.width * 0.30).clamp(88.0, 126.0);
    final characterHeight = characterWidth * 1.5;
    final characterTop = size.height * 0.115;

    final semanticRopePosition = _activeCueId != _completedCueId && cue != null
        ? cue.fromPosition
        : widget.ropePosition;
    final ropeDescription = switch (semanticRopePosition) {
      > 0 => '$semanticRopePosition marcas a favor del jugador',
      < 0 => '${semanticRopePosition.abs()} marcas a favor de la CPU',
      _ => 'en el centro',
    };

    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          'Arena de Tira y afloja. Cuerda $ropeDescription. '
          'Jugador ${widget.playerAnswered ? 'respondió' : 'pensando'}. '
          'CPU ${widget.cpuAnswered ? 'respondió' : 'pensando'}.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: Opacity(
                  opacity: entrance,
                  child: Image.asset(
                    _backgroundAsset,
                    fit: BoxFit.cover,
                    color: scheme.brightness == Brightness.dark
                        ? Colors.black.withValues(alpha: 0.42)
                        : Colors.white.withValues(alpha: 0.06),
                    colorBlendMode: scheme.brightness == Brightness.dark
                        ? BlendMode.darken
                        : BlendMode.lighten,
                    errorBuilder: (_, _, _) =>
                        ColoredBox(color: scheme.surfaceContainerLow),
                  ),
                ),
              ),
              ExcludeSemantics(
                child: CustomPaint(
                  painter: _ArenaTrackPainter(
                    colorScheme: scheme,
                    entrance: entrance,
                  ),
                ),
              ),
              _fighter(
                asset: _playerAsset,
                fallback: Icons.person_rounded,
                left: size.width * 0.055 + playerX - (1 - entrance) * 28,
                top: characterTop + playerY,
                width: characterWidth,
                height: characterHeight,
                rotation: playerRotation,
                scale:
                    1 +
                    playerAnswerBounce * 0.035 +
                    (playerCelebrates ? celebrationWave.abs() * 0.035 : 0),
                opacity: entrance,
                alignment: Alignment.bottomCenter,
              ),
              _fighter(
                asset: _cpuAsset,
                fallback: Icons.smart_toy_rounded,
                left:
                    size.width -
                    size.width * 0.055 -
                    characterWidth +
                    cpuX +
                    (1 - entrance) * 28,
                top: characterTop + cpuY,
                width: characterWidth,
                height: characterHeight,
                rotation: cpuRotation,
                scale:
                    1 +
                    cpuAnswerBounce * 0.035 +
                    (cpuCelebrates ? celebrationWave.abs() * 0.035 : 0),
                opacity: entrance,
                alignment: Alignment.bottomCenter,
              ),
              ExcludeSemantics(
                child: Opacity(
                  opacity: entrance,
                  child: CustomPaint(
                    key: const Key('tug-rope-painter'),
                    painter: TugRopePainter(
                      ropePosition: visualRopePosition,
                      tension: tension.clamp(0.0, 1.0),
                      vibration: vibration,
                      colorScheme: scheme,
                    ),
                  ),
                ),
              ),
              ExcludeSemantics(
                child: CustomPaint(
                  painter: TugArenaEffectsPainter(
                    pullProgress: pullProgress,
                    celebrationProgress: celebrationTime,
                    direction: direction,
                    strongPull: strong,
                    winner: cue?.winner,
                    colorScheme: scheme,
                  ),
                ),
              ),
              _fighterLabel(
                context,
                label: 'TÚ',
                answered: widget.playerAnswered,
                opacity: entrance,
                left: 10,
                alignment: Alignment.centerLeft,
              ),
              _fighterLabel(
                context,
                label: 'CPU',
                answered: widget.cpuAnswered,
                opacity: entrance,
                right: 10,
                alignment: Alignment.centerRight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fighter({
    required String asset,
    required IconData fallback,
    required double left,
    required double top,
    required double width,
    required double height,
    required double rotation,
    required double scale,
    required double opacity,
    required Alignment alignment,
  }) => Positioned(
    left: left,
    top: top,
    width: width,
    height: height,
    child: ExcludeSemantics(
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: rotation,
          alignment: alignment,
          child: Transform.scale(
            scale: scale,
            alignment: alignment,
            child: Image.asset(
              asset,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
              gaplessPlayback: true,
              errorBuilder: (context, _, _) =>
                  Icon(fallback, size: width * 0.7),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _fighterLabel(
    BuildContext context, {
    required String label,
    required bool answered,
    required double opacity,
    required Alignment alignment,
    double? left,
    double? right,
  }) => Positioned(
    left: left,
    right: right,
    bottom: 8,
    child: Align(
      alignment: alignment,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (answered) ...[
                  const Icon(Icons.check_rounded, size: 13),
                  const SizedBox(width: 3),
                ],
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ArenaTrackPainter extends CustomPainter {
  const _ArenaTrackPainter({required this.colorScheme, required this.entrance});

  final ColorScheme colorScheme;
  final double entrance;

  @override
  void paint(Canvas canvas, Size size) {
    final baselineY = size.height * 0.83;
    final linePaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.22 * entrance)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(size.width * 0.12, baselineY),
      Offset(size.width * 0.88, baselineY),
      linePaint,
    );
    final span = size.width * 0.40;
    for (var index = 0; index < 9; index++) {
      final x = size.width / 2 - span / 2 + span * index / 8;
      final central = index == 4;
      canvas.drawLine(
        Offset(x, baselineY - (central ? 8 : 4)),
        Offset(x, baselineY + (central ? 8 : 4)),
        Paint()
          ..color = (central ? colorScheme.primary : colorScheme.onSurface)
              .withValues(alpha: entrance * (central ? 0.72 : 0.28))
          ..strokeWidth = central ? 2.4 : 1,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.20, baselineY - 2),
        width: size.width * 0.23,
        height: 12,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.13 * entrance),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.80, baselineY - 2),
        width: size.width * 0.23,
        height: 12,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.13 * entrance),
    );
  }

  @override
  bool shouldRepaint(_ArenaTrackPainter oldDelegate) =>
      oldDelegate.colorScheme != colorScheme ||
      oldDelegate.entrance != entrance;
}

double _interval(double value, double start, double end, Curve curve) {
  if (value <= start) return 0;
  if (value >= end) return 1;
  return curve.transform((value - start) / (end - start));
}

double _lerp(double start, double end, double value) =>
    start + (end - start) * value;
