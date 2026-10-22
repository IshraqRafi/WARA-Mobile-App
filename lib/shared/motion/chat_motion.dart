import 'dart:math' as math;
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';
import 'motion.dart';

/// Springs a freshly arrived chat message in: a slight rise, a scale from the
/// sender's side and a fade, driven by a critically-soft spring. Set
/// [animate] false for history so only new messages move. Static under
/// reduce-motion.
class MessageSpringIn extends StatefulWidget {
  final bool animate;
  final bool fromRight;
  final Widget child;
  const MessageSpringIn({super.key, required this.animate, required this.fromRight, required this.child});

  @override
  State<MessageSpringIn> createState() => _MessageSpringInState();
}

class _MessageSpringInState extends State<MessageSpringIn> with SingleTickerProviderStateMixin {
  AnimationController? _c;

  static final SpringDescription _spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 420, ratio: 0.72);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c == null && widget.animate && !Motion.reduced(context)) {
      _c = AnimationController.unbounded(vsync: this)
        ..animateWith(SpringSimulation(_spring, 0, 1, 0)).whenComplete(() {
          if (mounted) setState(() => _c = null);
        });
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    return AnimatedBuilder(
      animation: c,
      child: widget.child,
      builder: (context, child) {
        final t = c.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - t)),
            child: Transform.scale(
              scale: 0.92 + 0.08 * t,
              alignment: widget.fromRight ? Alignment.bottomRight : Alignment.bottomLeft,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Fades its child in once when it first appears (read receipts).
class FadeInOnce extends StatelessWidget {
  final Widget child;
  const FadeInOnce({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, Motion.slow),
      curve: Motion.curve,
      child: child,
      builder: (context, v, child) => Opacity(opacity: v, child: child),
    );
  }
}

/// Three bouncing dots for "is typing". NOT wired: the app has no typing
/// state yet. Mount it only while someone is typing; its ticker lives only
/// as long as the widget. Dots are static under reduce-motion.
class TypingDots extends StatefulWidget {
  final Color color;
  final double size;
  const TypingDots({super.key, required this.color, this.size = 7});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: s * 0.25),
                child: Transform.translate(
                  offset: Offset(0, _c.isAnimating ? -s * 0.6 * _bump(_c.value, i) : 0),
                  child: Opacity(
                    opacity: _c.isAnimating ? 0.4 + 0.6 * _bump(_c.value, i) : 0.7,
                    child: Container(
                      width: s,
                      height: s,
                      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static double _bump(double t, int i) {
    final x = (t - i * 0.18) % 1.0;
    return x < 0.4 ? math.sin(x / 0.4 * math.pi) : 0;
  }
}
