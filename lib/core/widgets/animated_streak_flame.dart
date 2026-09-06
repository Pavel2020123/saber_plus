import 'dart:math' as math;

import 'package:flutter/material.dart';

enum StreakFlameAppearance { burning, frozen, extinguished }

/// Vector fire that stays sharp in a compact badge or a large streak card.
/// Its controllers stop on hidden routes, backgrounding and reduced motion.
class AnimatedStreakFlame extends StatefulWidget {
  const AnimatedStreakFlame({
    super.key,
    required this.color,
    this.size = 34,
    this.animate = true,
    this.continuous = false,
    this.appearance = StreakFlameAppearance.burning,
    this.semanticLabel = 'Racha activa',
  });

  final Color color;
  final double size;
  final bool animate;
  final bool continuous;
  final StreakFlameAppearance appearance;
  final String semanticLabel;

  @override
  State<AnimatedStreakFlame> createState() => _AnimatedStreakFlameState();
}

class _AnimatedStreakFlameState extends State<AnimatedStreakFlame>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _fire = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final Listenable _animation = Listenable.merge([_entrance, _fire]);
  Color? _fromColor;
  bool _reducedMotion = false;
  bool _tickerEnabled = true;
  bool _foreground = true;
  bool _inViewport = true;
  bool _visibilityScheduled = false;
  ScrollableState? _scrollable;

  bool get _canAnimate =>
      widget.animate &&
      widget.appearance == StreakFlameAppearance.burning &&
      !_reducedMotion &&
      _tickerEnabled &&
      _foreground &&
      _inViewport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = MediaQuery.disableAnimationsOf(context);
    final ticker = TickerMode.valuesOf(context).enabled;
    final changed = motion != _reducedMotion || ticker != _tickerEnabled;
    final routeRevealed = !_tickerEnabled && ticker;
    _reducedMotion = motion;
    _tickerEnabled = ticker;
    final scrollable = Scrollable.maybeOf(context);
    if (_scrollable != scrollable) {
      _scrollable?.position.removeListener(_scheduleVisibilityCheck);
      _scrollable = scrollable;
      _scrollable?.position.addListener(_scheduleVisibilityCheck);
    }
    _scheduleVisibilityCheck();
    if (changed || (!_entrance.isAnimating && _entrance.value == 0)) {
      _configureMotion(replayEntrance: _entrance.value == 0 || routeRevealed);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedStreakFlame oldWidget) {
    super.didUpdateWidget(oldWidget);
    final colorChanged = oldWidget.color != widget.color;
    if (colorChanged) _fromColor = oldWidget.color;
    if (colorChanged ||
        oldWidget.animate != widget.animate ||
        oldWidget.continuous != widget.continuous ||
        oldWidget.appearance != widget.appearance) {
      _configureMotion(replayEntrance: true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _configureMotion();
  }

  void _configureMotion({bool replayEntrance = false}) {
    _entrance.stop();
    _fire.stop();
    if (!_canAnimate) {
      _entrance.value = 1;
      return;
    }
    if (replayEntrance || _entrance.value < 1) {
      _entrance.forward(from: replayEntrance ? 0 : _entrance.value);
    }
    if (widget.continuous) {
      _fire.repeat();
    } else if (replayEntrance || _fire.value < 1) {
      _fire.forward(from: replayEntrance ? 0 : _fire.value);
    }
  }

  void _scheduleVisibilityCheck() {
    if (_visibilityScheduled) return;
    _visibilityScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityScheduled = false;
      if (!mounted) return;
      final box = context.findRenderObject();
      final viewport = _scrollable?.context.findRenderObject();
      var visible = true;
      if (box is RenderBox &&
          viewport is RenderBox &&
          box.hasSize &&
          viewport.hasSize) {
        final offset = box.localToGlobal(Offset.zero, ancestor: viewport);
        visible = (offset & box.size).overlaps(Offset.zero & viewport.size);
      }
      if (_inViewport == visible) return;
      _inViewport = visible;
      _configureMotion();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollable?.position.removeListener(_scheduleVisibilityCheck);
    _entrance.dispose();
    _fire.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticLabel,
    image: true,
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            final entry = _entrance.value;
            final scale = 0.62 + 0.38 * Curves.easeOutBack.transform(entry);
            return Transform.scale(
              scale: scale,
              alignment: const Alignment(0, 0.7),
              child: CustomPaint(
                key: const Key('streak-flame-art'),
                size: Size.square(widget.size),
                painter: _FlamePainter(
                  color: Color.lerp(
                    _fromColor ?? widget.color,
                    widget.color,
                    Curves.easeOut.transform(entry),
                  )!,
                  phase: _fire.value * math.pi * 2,
                  ignition: _canAnimate ? math.sin(entry * math.pi) : 0,
                  appearance: widget.appearance,
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter({
    required this.color,
    required this.phase,
    required this.ignition,
    required this.appearance,
  });

  final Color color;
  final double phase;
  final double ignition;
  final StreakFlameAppearance appearance;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final frozen = appearance == StreakFlameAppearance.frozen;
    final extinct = appearance == StreakFlameAppearance.extinguished;
    final live = !frozen && !extinct;
    final time = live ? phase : 0.0;
    final sway = math.sin(time) * 3;
    final flutter = math.sin(time * 2 + 0.8) * 2;
    final light = Color.lerp(color, Colors.white, 0.64)!;
    final dark = Color.lerp(color, const Color(0xFF41123A), 0.4)!;

    canvas.drawOval(
      const Rect.fromLTWH(23, 87, 54, 8),
      Paint()
        ..color = (live ? color : const Color(0xFF64748B)).withValues(
          alpha: 0.12,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    if (live) {
      canvas.drawCircle(
        const Offset(50, 61),
        38 + ignition * 5,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.24 + ignition * 0.1),
              color.withValues(alpha: 0),
            ],
          ).createShader(const Rect.fromLTWH(8, 19, 84, 84)),
      );
    }

    final outer = Path()
      ..moveTo(50, 90)
      ..cubicTo(27, 90, 17, 75, 23, 56)
      ..cubicTo(25, 47, 33, 43, 31 + sway, 33 + flutter)
      ..cubicTo(42, 36, 37, 48, 43, 49)
      ..cubicTo(43, 33, 57 + sway, 27, 53 + sway, 10 + flutter)
      ..cubicTo(75 + sway, 22, 70, 42, 65, 51)
      ..cubicTo(70, 50, 74, 43, 74 - sway, 38)
      ..cubicTo(83, 49, 85, 66, 77, 77)
      ..cubicTo(72, 87, 63, 90, 50, 90)
      ..close();
    canvas.drawPath(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: extinct
              ? const [Color(0xFFC3CBD5), Color(0xFF66758A)]
              : frozen
              ? const [Color(0xFFB4ECFF), Color(0xFF4292C6)]
              : [light, color, dark],
          stops: live ? const [0, 0.48, 1] : null,
        ).createShader(const Rect.fromLTWH(20, 10, 62, 80)),
    );

    final middle = Path()
      ..moveTo(49, 87)
      ..cubicTo(30, 86, 28, 72, 35, 62)
      ..cubicTo(40, 54, 46, 48, 44 + flutter, 37)
      ..cubicTo(58 + sway, 46, 56, 60, 57, 64)
      ..cubicTo(62, 59, 65, 56, 66, 52)
      ..cubicTo(74, 66, 68, 86, 49, 87)
      ..close();
    canvas.drawPath(
      middle,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: extinct
              ? const [Color(0xFFE2E7EC), Color(0xFF96A3B4)]
              : frozen
              ? const [Color(0xFFE0FAFF), Color(0xFF8CD8F3)]
              : [Colors.white.withValues(alpha: 0.98), light, color],
        ).createShader(const Rect.fromLTWH(31, 37, 40, 51)),
    );
    final core = Path()
      ..moveTo(50, 85)
      ..cubicTo(38, 84, 38, 74, 44, 67)
      ..quadraticBezierTo(48 + flutter, 61, 48 + flutter, 55)
      ..cubicTo(58, 64, 53, 69, 60, 72)
      ..cubicTo(64, 80, 57, 86, 50, 85)
      ..close();
    canvas.drawPath(
      core,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: extinct
              ? const [Color(0xFFF1F4F7), Color(0xFFC5CFDA)]
              : [Colors.white, light],
        ).createShader(const Rect.fromLTWH(40, 55, 22, 31)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(29, 70)
        ..quadraticBezierTo(28, 63, 32, 58),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: extinct ? 0.22 : 0.57),
    );

    if (live) _drawSparks(canvas, light);
    if (frozen) _drawIce(canvas);
    if (extinct) _drawAsh(canvas);
    canvas.restore();
  }

  void _drawSparks(Canvas canvas, Color light) {
    for (var i = 0; i < 5; i++) {
      final progress = (phase / (2 * math.pi) + i * 0.21) % 1;
      final alpha = math.sin(progress * math.pi) * 0.75;
      final x = 22 + i * 14 + math.sin(phase + i) * 2;
      final y = 68 - progress * 57;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: 1.8 + i % 2,
          height: 3.2 + i % 3,
        ),
        Paint()..color = (i.isEven ? color : light).withValues(alpha: alpha),
      );
    }
  }

  void _drawIce(Canvas canvas) {
    final ice = Path()
      ..moveTo(23, 84)
      ..lineTo(18, 44)
      ..lineTo(30, 17)
      ..lineTo(65, 7)
      ..lineTo(84, 34)
      ..lineTo(86, 76)
      ..lineTo(71, 94)
      ..lineTo(38, 96)
      ..close();
    canvas.drawPath(
      ice,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x5594E6FF), Color(0x1194E6FF), Color(0x7738BDF8)],
        ).createShader(const Rect.fromLTWH(18, 7, 68, 89)),
    );
    canvas.drawPath(
      ice,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF8AD7F3),
    );
    canvas.drawPath(
      Path()
        ..moveTo(30, 17)
        ..lineTo(40, 34)
        ..lineTo(26, 51)
        ..moveTo(65, 7)
        ..lineTo(61, 27)
        ..lineTo(75, 34)
        ..lineTo(84, 34)
        ..moveTo(86, 76)
        ..lineTo(65, 83)
        ..lineTo(71, 94)
        ..moveTo(38, 96)
        ..lineTo(36, 81)
        ..lineTo(23, 84),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = Colors.white.withValues(alpha: 0.82),
    );
    canvas.drawLine(
      const Offset(23, 43),
      const Offset(28, 29),
      Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  void _drawAsh(Canvas canvas) {
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromLTWH(31 + i * 13, 88 + i % 2 * 2, 9, 4),
        Paint()..color = const Color(0xFF7E8998),
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(44, 25)
        ..cubicTo(34, 19, 48, 15, 41, 10),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2
        ..color = const Color(0xFFCBD3DD),
    );
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) =>
      color != oldDelegate.color ||
      phase != oldDelegate.phase ||
      ignition != oldDelegate.ignition ||
      appearance != oldDelegate.appearance;
}
