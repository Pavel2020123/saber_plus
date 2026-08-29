import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const saberPageTransitionDuration = Duration(milliseconds: 260);
const saberPageReverseTransitionDuration = Duration(milliseconds: 210);

CustomTransitionPage<void> saberPage({
  required LocalKey key,
  required Widget child,
}) => CustomTransitionPage<void>(
  key: key,
  child: child,
  transitionDuration: saberPageTransitionDuration,
  reverseTransitionDuration: saberPageReverseTransitionDuration,
  transitionsBuilder: (context, animation, secondaryAnimation, child) =>
      SaberPageTransition(animation: animation, child: child),
);

class SaberPageTransition extends StatelessWidget {
  const SaberPageTransition({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: Tween<double>(begin: 0.65, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.045, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
