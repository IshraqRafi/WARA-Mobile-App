import 'package:flutter/widgets.dart';
import 'motion.dart';

/// Staggered fade + rise for list items, played once per [screen] per
/// session: only items built in the first moments after the screen's first
/// build animate; later rebuilds and scrolling show items immediately.
class StaggerIn extends StatefulWidget {
  final String screen;
  final int index;
  final Widget child;

  const StaggerIn({super.key, required this.screen, required this.index, required this.child});

  static final Map<String, DateTime> _firstSeen = {};
  static const _window = Duration(milliseconds: 700);
  static const _step = Duration(milliseconds: 40);
  static const _maxStaggered = 8;

  /// Test hook: forget which screens have played.
  @visibleForTesting
  static void reset() => _firstSeen.clear();

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  double _delayFrac = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final first = StaggerIn._firstSeen.putIfAbsent(widget.screen, () => now);
    final play = now.difference(first) < StaggerIn._window && widget.index < StaggerIn._maxStaggered;
    if (play) {
      // Delay is folded into the controller (no timers): the first
      // [_delayFrac] of the run is idle, then the item fades and rises.
      final delay = StaggerIn._step * widget.index;
      final total = Motion.medium + delay;
      _delayFrac = delay.inMicroseconds / total.inMicroseconds;
      _c = AnimationController(vsync: this, duration: total)..forward();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) _c?.value = 1; // jump to end, stops ticking
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null || Motion.reduced(context)) return widget.child;
    final a = CurvedAnimation(parent: c, curve: Interval(_delayFrac, 1, curve: Motion.curve));
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(a),
        child: widget.child,
      ),
    );
  }
}
