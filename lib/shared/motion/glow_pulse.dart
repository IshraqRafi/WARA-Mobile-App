import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'motion.dart';

/// Plays a brief glow behind [child] plus a medium haptic whenever
/// [active] flips from false to true (e.g. a project becoming approved).
class GlowPulse extends StatefulWidget {
  final bool active;
  final Color color;
  final Widget child;

  const GlowPulse({super.key, required this.active, required this.color, required this.child});

  @override
  State<GlowPulse> createState() => _GlowPulseState();
}

class _GlowPulseState extends State<GlowPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didUpdateWidget(GlowPulse old) {
    super.didUpdateWidget(old);
    if (!old.active && widget.active) {
      HapticFeedback.mediumImpact();
      if (!Motion.reduced(context)) _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // Rise fast, decay slow.
        final t = _c.value;
        final k = _c.isAnimating ? (t < 0.25 ? t / 0.25 : 1 - (t - 0.25) / 0.75) : 0.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: k <= 0
                ? const []
                : [BoxShadow(color: widget.color.withValues(alpha: 0.55 * k), blurRadius: 18 * k, spreadRadius: 2 * k)],
          ),
          child: child,
        );
      },
    );
  }
}
