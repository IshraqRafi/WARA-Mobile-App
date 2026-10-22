import 'package:flutter/widgets.dart';
import 'motion.dart';

/// Horizontal shared-axis entrance for tab bodies. When [index] changes the
/// new tab slides in from the side of travel (right when moving right) while
/// fading in. The child (an IndexedStack shell) keeps every tab's state; the
/// controller only runs during the 250ms switch.
class SharedAxisTabs extends StatefulWidget {
  final int index;
  final Widget child;
  const SharedAxisTabs({super.key, required this.index, required this.child});

  @override
  State<SharedAxisTabs> createState() => _SharedAxisTabsState();
}

class _SharedAxisTabsState extends State<SharedAxisTabs> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.medium, value: 1);
  late final CurvedAnimation _curve = CurvedAnimation(parent: _c, curve: Motion.curve);
  double _dir = 1;

  @override
  void didUpdateWidget(SharedAxisTabs old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      if (Motion.reduced(context)) {
        _c.value = 1;
        return;
      }
      _dir = widget.index > old.index ? 1 : -1;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final t = _curve.value;
        if (t == 1) return child!;
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(_dir * 30 * (1 - t), 0), child: child),
        );
      },
    );
  }
}

/// Outline -> filled icon morph: crossfade with a small scale pop.
class MorphIcon extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final Color color;
  final double size;

  const MorphIcon({
    super.key,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.medium),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween<double>(begin: 0.7, end: 1).animate(a), child: child),
      ),
      child: Icon(
        selected ? selectedIcon : icon,
        key: ValueKey(selected),
        size: size,
        color: color,
      ),
    );
  }
}
