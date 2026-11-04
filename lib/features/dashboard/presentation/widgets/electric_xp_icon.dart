import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Decorative current running through the approved Lucide glyph, not a new icon.
/// A short pulse followed by a pause avoids a permanently active frame loop.
class ElectricXpIcon extends StatefulWidget {
  const ElectricXpIcon({required this.xp, this.size = 20, super.key});

  final int xp;
  final double size;

  @override
  State<ElectricXpIcon> createState() => _ElectricXpIconState();
}

class _ElectricXpIconState extends State<ElectricXpIcon>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  Timer? _timer;
  bool _enabled = false;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  void _configure() {
    final enabled =
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context);
    if (enabled == _enabled) return;
    _enabled = enabled;
    _timer?.cancel();
    if (enabled) {
      _pulse.forward(from: 0);
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted && _enabled) _pulse.forward(from: 0);
      });
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _configure();
  }

  @override
  void didUpdateWidget(ElectricXpIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_enabled && widget.xp > oldWidget.xp) _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size + 8,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final phase = _pulse.value;
              final energy = _enabled && phase < 1
                  ? math.sin(phase * math.pi)
                  : 0.0;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    LucideIcons.zap,
                    size: widget.size,
                    color: colors.primary,
                  ),
                  if (energy > 0)
                    Opacity(
                      key: const Key('xp-electric-flow'),
                      opacity: energy * .85,
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (rect) => LinearGradient(
                          begin: Alignment(-1, -3 + phase * 6),
                          end: Alignment(1, -1 + phase * 6),
                          colors: const [
                            Color(0x0014CFFF),
                            Color(0xFF14CFFF),
                            Color(0xFFE5FCFF),
                            Color(0x0014CFFF),
                          ],
                          stops: const [0, .35, .55, 1],
                        ).createShader(rect),
                        child: Icon(LucideIcons.zap, size: widget.size),
                      ),
                    ),
                  for (var index = 0; index < 3; index++)
                    if (energy > 0)
                      Transform.translate(
                        offset: Offset(
                          math.cos(index * 2.1 - .6) *
                              (widget.size * .48 + phase * 3),
                          math.sin(index * 2.1 - .6) *
                              (widget.size * .48 + phase * 3),
                        ),
                        child: Transform.rotate(
                          angle: index * 2.1 - .6,
                          child: Opacity(
                            opacity: energy * .65,
                            child: Container(
                              width: 3,
                              height: 1.4,
                              decoration: BoxDecoration(
                                color: colors.brightness == Brightness.dark
                                    ? const Color(0xFF80E8FF)
                                    : const Color(0xFF087EAD),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
