import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'motion.dart';

/// App-wide fade-through: the outgoing page fades out while the incoming
/// page fades in and scales up from 0.94. ~250ms; instant with reduce-motion.
CustomTransitionPage<void> fadeThroughPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.medium,
    reverseTransitionDuration: Motion.medium,
    transitionsBuilder: (context, animation, secondary, child) {
      if (Motion.reduced(context)) return child;
      final inT = CurvedAnimation(parent: animation, curve: const Interval(0.3, 1, curve: Motion.curve));
      final outT = CurvedAnimation(parent: secondary, curve: const Interval(0, 0.3, curve: Curves.easeIn));
      return FadeTransition(
        opacity: ReverseAnimation(outT),
        child: FadeTransition(
          opacity: inT,
          child: ScaleTransition(scale: Tween<double>(begin: 0.94, end: 1).animate(inT), child: child),
        ),
      );
    },
  );
}
