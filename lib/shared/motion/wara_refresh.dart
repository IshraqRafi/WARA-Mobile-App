import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/wara_logo.dart';
import 'motion.dart';

/// Branded pull-to-refresh. Pulling down from the top rotates the Wara logo
/// and fills it bottom-up; past the threshold a release calls [onRefresh] and
/// the logo spins until the returned future completes (the providers' refresh
/// futures complete when fresh data arrives). Drag state lives in a
/// ValueNotifier so the list never rebuilds while pulling, and the spin
/// controller only runs while refreshing.
///
/// The wrapped scrollable must use [AlwaysScrollableScrollPhysics].
class WaraRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  const WaraRefresh({super.key, required this.onRefresh, required this.child});

  static const double threshold = 90;

  @override
  State<WaraRefresh> createState() => _WaraRefreshState();
}

class _WaraRefreshState extends State<WaraRefresh> with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _pull = ValueNotifier(0);
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  bool _refreshing = false;
  bool _armed = false;

  @override
  void dispose() {
    _pull.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _setPull(double v) {
    v = v.clamp(0, WaraRefresh.threshold * 1.5).toDouble();
    final armed = v >= WaraRefresh.threshold;
    if (armed && !_armed) Haptics.light();
    _armed = armed;
    _pull.value = v;
  }

  Future<void> _start() async {
    _refreshing = true;
    _pull.value = WaraRefresh.threshold;
    if (!Motion.reduced(context)) _spin.repeat();
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _spin.stop();
        _spin.value = 0;
        _refreshing = false;
        _armed = false;
        _pull.value = 0;
      }
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (_refreshing || n.metrics.axis != Axis.vertical || n.depth != 0) return false;
    if (n is OverscrollNotification && n.dragDetails != null && n.overscroll < 0) {
      _setPull(_pull.value - n.overscroll); // clamping physics (Android)
    } else if (n is ScrollUpdateNotification) {
      if (n.metrics.pixels < 0) {
        if (n.dragDetails != null) _setPull(-n.metrics.pixels); // bouncing physics (iOS)
      } else if (_pull.value > 0 && n.dragDetails != null && (n.scrollDelta ?? 0) > 0) {
        _setPull(_pull.value - n.scrollDelta!);
      }
      if (n.dragDetails == null && _pull.value > 0) _release();
    } else if (n is ScrollEndNotification && _pull.value > 0) {
      _release();
    }
    return false;
  }

  void _release() {
    if (_armed) {
      _start();
    } else {
      _armed = false;
      _pull.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return NotificationListener<OverscrollIndicatorNotification>(
      onNotification: (n) {
        if (n.leading) n.disallowIndicator();
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Stack(children: [
          widget.child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pull, _spin]),
                  builder: (context, _) {
                    final pull = _pull.value;
                    if (pull <= 0) return const SizedBox.shrink();
                    final p = (pull / WaraRefresh.threshold).clamp(0.0, 1.0);
                    final angle = (_refreshing ? _spin.value : p * 0.75) * 2 * math.pi;
                    return Padding(
                      padding: EdgeInsets.only(top: 8 + math.min(pull, WaraRefresh.threshold) * 0.4),
                      child: Center(
                        child: Opacity(
                          opacity: p,
                          child: Transform.rotate(
                            angle: angle,
                            child: Transform.scale(
                              scale: 0.6 + 0.4 * p,
                              child: _FillingLogo(fill: _refreshing ? 1 : p, track: colors.outline),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Greyed logo with the full-colour logo revealed bottom-up by [fill].
class _FillingLogo extends StatelessWidget {
  final double fill;
  final Color track;
  const _FillingLogo({required this.fill, required this.track});

  @override
  Widget build(BuildContext context) {
    const logo = WaraLogo(size: 36);
    return Stack(children: [
      const Opacity(opacity: 0.35, child: logo),
      ClipRect(
        child: Align(alignment: Alignment.bottomCenter, heightFactor: fill, child: logo),
      ),
    ]);
  }
}
