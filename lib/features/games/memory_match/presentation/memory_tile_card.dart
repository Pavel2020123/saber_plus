import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/memory_match_models.dart';

/// A two-faced card. The hidden face never exposes the answer to semantics.
class MemoryTileCard extends StatefulWidget {
  const MemoryTileCard({
    required this.tile,
    required this.revealed,
    required this.matched,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final MemoryMatchTile tile;
  final bool revealed;
  final bool matched;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<MemoryTileCard> createState() => _MemoryTileCardState();
}

class _MemoryTileCardState extends State<MemoryTileCard>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _flip;
  late final AnimationController _celebration;
  bool _reduceMotion = false;
  bool _visible = true;
  bool _foreground = true;
  bool _celebratePending = false;

  bool get _front => widget.revealed || widget.matched;
  bool get _canAnimate => _visible && _foreground && !_reduceMotion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
      value: _front ? 1 : 0,
    );
    _celebration = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _visible = TickerMode.valuesOf(context).enabled;
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant MemoryTileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.matched && !oldWidget.matched) {
      _celebratePending = true;
    }
    _syncAnimation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncAnimation();
  }

  void _syncAnimation() {
    if (_reduceMotion) {
      _flip.value = _front ? 1 : 0;
      _celebration.value = 1;
      _celebratePending = false;
      return;
    }
    if (!_canAnimate) {
      _flip.stop();
      _celebration.stop();
      return;
    }
    if (_front) {
      if (!_flip.isCompleted) _flip.forward();
    } else if (!_flip.isDismissed) {
      _flip.reverse();
    }
    if (_celebratePending) {
      _celebratePending = false;
      _celebration.forward(from: 0);
    } else if (!_celebration.isCompleted) {
      _celebration.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flip.dispose();
    _celebration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tappable = widget.enabled && !widget.matched && !widget.revealed;
    return Semantics(
      button: !widget.matched,
      enabled: tappable,
      excludeSemantics: true,
      label: widget.matched
          ? 'Pareja encontrada: ${widget.tile.text}'
          : _front
          ? widget.tile.text
          : 'Tarjeta oculta',
      onTap: tappable ? widget.onTap : null,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_flip, _celebration]),
          builder: (context, _) {
            final progress = Curves.easeInOutCubic.transform(_flip.value);
            final showingFront = progress >= 0.5;
            // Swap faces at the edge; both have a non-negative horizontal scale.
            final angle = math.pi * (showingFront ? progress - 1 : progress);
            final pulse = math.sin(_celebration.value * math.pi) * 0.045;
            return Transform.scale(
              scale: 1 + pulse,
              child: Transform(
                key: const Key('memory-card-perspective'),
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0018)
                  ..rotateY(angle),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Material(
                    animationDuration: _reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                    elevation: widget.matched ? 0 : 2,
                    color: showingFront
                        ? widget.matched
                              ? scheme.primaryContainer
                              : scheme.surface
                        : scheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: widget.matched
                            ? scheme.primary.withValues(alpha: 0.65)
                            : scheme.outlineVariant,
                        width: widget.matched ? 1.5 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: tappable ? widget.onTap : null,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (showingFront)
                            _frontFace(context)
                          else
                            _backFace(context),
                          if (widget.matched && _celebration.value < 1)
                            IgnorePointer(
                              child: CustomPaint(
                                painter: _PairSparkPainter(
                                  progress: _celebration.value,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _frontFace(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = widget.matched ? scheme.onPrimaryContainer : scheme.onSurface;
    return Padding(
      key: ValueKey('front-${widget.tile.id}'),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                widget.matched
                    ? Icons.check_circle_rounded
                    : widget.tile.isPrompt
                    ? Icons.psychology_alt_outlined
                    : Icons.auto_stories_outlined,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  widget.matched
                      ? 'Pareja'
                      : widget.tile.isPrompt
                      ? 'Concepto'
                      : 'Respuesta',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  widget.tile.text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backFace(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      key: ValueKey('back-${widget.tile.id}'),
      painter: _CardBackPainter(color: scheme.primary),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.12),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.psychology_rounded,
            size: 32,
            color: scheme.primary,
          ),
        ),
      ),
    );
  }
}

class _CardBackPainter extends CustomPainter {
  const _CardBackPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = color.withValues(alpha: 0.13)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width + size.height; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), ink);
      canvas.drawLine(Offset(x, 0), Offset(x - size.height, size.height), ink);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(8),
        const Radius.circular(13),
      ),
      ink..color = color.withValues(alpha: 0.24),
    );
  }

  @override
  bool shouldRepaint(_CardBackPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PairSparkPainter extends CustomPainter {
  const _PairSparkPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = math.sin(progress * math.pi);
    final ink = Paint()
      ..color = color.withValues(alpha: opacity * 0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width - 22, 23);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final vector = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + vector * (5 + progress * 11),
        center + vector * (8 + progress * 15),
        ink,
      );
    }
  }

  @override
  bool shouldRepaint(_PairSparkPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
