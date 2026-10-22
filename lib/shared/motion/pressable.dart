import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'motion.dart';

/// Scales its child to 0.97 while pressed and ticks a selection haptic on
/// release. Uses a raw [Listener], so the child keeps its own tap handling
/// (buttons, InkWell) and a scroll that starts on it cancels the press.
class Pressable extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double scale;

  const Pressable({super.key, required this.child, this.enabled = true, this.scale = 0.97});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  Offset? _origin;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (e) {
        _origin = e.position;
        _set(true);
      },
      onPointerMove: (e) {
        if (_origin != null && (e.position - _origin!).distance > kTouchSlop) {
          _origin = null;
          _set(false);
        }
      },
      onPointerUp: (_) {
        if (_origin != null) HapticFeedback.selectionClick();
        _origin = null;
        _set(false);
      },
      onPointerCancel: (_) {
        _origin = null;
        _set(false);
      },
      child: AnimatedScale(
        scale: _down && !Motion.reduced(context) ? widget.scale : 1,
        duration: Motion.of(context, Motion.fast),
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}
