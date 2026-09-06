import 'package:flutter/material.dart';

/// Decorative motion only. Never drives a game clock or a game result.
class GameSceneMotion extends StatefulWidget {
  const GameSceneMotion({
    required this.builder,
    this.duration = const Duration(milliseconds: 2600),
    this.repeat = true,
    super.key,
  });

  final Widget Function(BuildContext context, double phase) builder;
  final Duration duration;
  final bool repeat;

  @override
  State<GameSceneMotion> createState() => _GameSceneMotionState();
}

class _GameSceneMotionState extends State<GameSceneMotion>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _resumed = true;
  bool _reduced = false;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _visible =
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    _updateMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _updateMotion();
  }

  void _updateMotion() {
    if (!_resumed || !_visible || _reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      if (widget.repeat) {
        _controller.repeat();
      } else if (!_controller.isCompleted) {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => widget.builder(
      context,
      _reduced ? (widget.repeat ? 0.25 : 1) : _controller.value,
    ),
  );
}
