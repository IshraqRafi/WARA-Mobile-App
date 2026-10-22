import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'motion.dart';

/// Owns the drag progress for one swipeable row. Pass [onUpdate] to
/// `Dismissible.onUpdate` and wrap the background icons in [SwipeIcon]. A
/// haptic fires once each time the drag crosses the commit threshold.
class SwipeFeedback extends StatefulWidget {
  final Widget Function(BuildContext context, ValueListenable<double> progress, DismissUpdateCallback onUpdate) builder;
  const SwipeFeedback({super.key, required this.builder});

  @override
  State<SwipeFeedback> createState() => _SwipeFeedbackState();
}

class _SwipeFeedbackState extends State<SwipeFeedback> {
  final ValueNotifier<double> _progress = ValueNotifier(0);

  void _onUpdate(DismissUpdateDetails d) {
    if (d.reached && !d.previousReached) Haptics.medium();
    _progress.value = d.progress;
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _progress, _onUpdate);
}

/// Scales its child with swipe progress (0.8 -> 1.25, capped). Static under
/// reduce-motion. Only this widget repaints while dragging.
class SwipeIcon extends StatelessWidget {
  final ValueListenable<double> progress;
  final Widget child;
  const SwipeIcon({super.key, required this.progress, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return child;
    return ValueListenableBuilder<double>(
      valueListenable: progress,
      child: child,
      builder: (context, p, child) {
        final t = (p / 0.4).clamp(0.0, 1.0); // Dismissible's default threshold
        return Transform.scale(scale: 0.8 + 0.45 * Curves.easeOut.transform(t), child: child);
      },
    );
  }
}
