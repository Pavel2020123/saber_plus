import 'dart:async';

import 'package:flutter/material.dart';

class AnimatedStreakFlame extends StatefulWidget {
  const AnimatedStreakFlame({
    super.key,
    required this.color,
    this.size = 34,
    this.animate = true,
    this.continuous = false,
    this.semanticLabel = 'Racha activa',
  });

  final Color color;
  final double size;
  final bool animate;
  final bool continuous;
  final String semanticLabel;

  @override
  State<AnimatedStreakFlame> createState() => _AnimatedStreakFlameState();
}

class _AnimatedStreakFlameState extends State<AnimatedStreakFlame>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _flickerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _entranceScale =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.55, end: 1.3), weight: 48),
        TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.92), weight: 24),
        TweenSequenceItem(tween: Tween(begin: 0.92, end: 1), weight: 28),
      ]).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Curves.easeOutCubic,
        ),
      );
  late final Animation<double> _flickerScale =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1, end: 1.12), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.96), weight: 22),
        TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.07), weight: 23),
        TweenSequenceItem(tween: Tween(begin: 1.07, end: 1), weight: 35),
      ]).animate(
        CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
      );
  late final Animation<double> _rotation =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: -0.05), weight: 18),
        TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.05), weight: 28),
        TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.025), weight: 24),
        TweenSequenceItem(tween: Tween(begin: -0.025, end: 0), weight: 30),
      ]).animate(
        CurvedAnimation(parent: _flickerController, curve: Curves.easeInOut),
      );

  bool? _animationsDisabled;
  Timer? _nextFlicker;
  var _animationGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (_animationsDisabled == disabled) return;
    _animationsDisabled = disabled;
    _startIfAllowed();
  }

  @override
  void didUpdateWidget(covariant AnimatedStreakFlame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate ||
        oldWidget.continuous != widget.continuous ||
        oldWidget.color != widget.color) {
      _startIfAllowed();
    }
  }

  void _startIfAllowed() {
    final generation = ++_animationGeneration;
    _nextFlicker?.cancel();
    _entranceController.stop();
    _flickerController.stop();
    if (_animationsDisabled == true || !widget.animate) {
      _entranceController.value = 1;
      _flickerController.value = 1;
      return;
    }
    _flickerController.value = 1;
    _entranceController.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted &&
          generation == _animationGeneration &&
          widget.animate &&
          _animationsDisabled != true) {
        _playFlicker(generation);
      }
    });
  }

  void _playFlicker(int generation) {
    _flickerController.forward(from: 0).whenCompleteOrCancel(() {
      if (!mounted ||
          generation != _animationGeneration ||
          !widget.animate ||
          !widget.continuous ||
          _animationsDisabled == true) {
        return;
      }
      _nextFlicker = Timer(
        const Duration(milliseconds: 180),
        () => _playFlicker(generation),
      );
    });
  }

  @override
  void dispose() {
    _animationGeneration++;
    _nextFlicker?.cancel();
    _entranceController.dispose();
    _flickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticLabel,
    child: ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _entranceController,
            _flickerController,
          ]),
          child: Icon(
            Icons.local_fire_department_rounded,
            color: widget.color,
            size: widget.size,
          ),
          builder: (context, child) => Transform.rotate(
            angle: _rotation.value,
            child: Transform.scale(
              scale: _entranceScale.value * _flickerScale.value,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
