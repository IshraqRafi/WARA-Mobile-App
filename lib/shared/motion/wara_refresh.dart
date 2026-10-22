import 'package:flutter/material.dart';
import 'motion.dart';

/// Standard Material pull-to-refresh, themed for Wara: primary spinner on a
/// surface disc, tuned displacement, and a light haptic when the pull is
/// released past the threshold. [onRefresh] should complete when fresh data
/// arrives; the providers cap it at 8s. The spinner keeps turning only while
/// that future is pending. Reduce-motion drops the elevation shadow; the spinner
/// itself stays as it is the only progress feedback.
///
/// The wrapped scrollable must use [AlwaysScrollableScrollPhysics].
class WaraRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  const WaraRefresh({super.key, required this.onRefresh, required this.child});

  static const double displacement = 28;
  static const double edgeOffset = 4;

  Future<void> _refresh() {
    Haptics.light();
    return onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: colors.primary,
      backgroundColor: colors.surfaceContainerHigh,
      displacement: displacement,
      edgeOffset: edgeOffset,
      strokeWidth: 2.5,
      elevation: Motion.reduced(context) ? 0 : 2,
      child: child,
    );
  }
}
