import 'package:flutter/material.dart';
import 'motion.dart';

/// A small count badge that bounces (scale pop) whenever [count] changes.
/// Renders nothing at zero.
class PopBadge extends StatefulWidget {
  final int count;
  final Color color;
  final Color textColor;
  final Color borderColor;

  const PopBadge({super.key, required this.count, required this.color, required this.textColor, required this.borderColor});

  @override
  State<PopBadge> createState() => _PopBadgeState();
}

class _PopBadgeState extends State<PopBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Motion.slow);
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1.35).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
    TweenSequenceItem(tween: Tween<double>(begin: 1.35, end: 1).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
  ]).animate(_c);

  @override
  void didUpdateWidget(PopBadge old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count && widget.count > 0 && !Motion.reduced(context)) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count <= 0) return const SizedBox.shrink();
    return ScaleTransition(
      scale: _scale,
      child: Container(
        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: widget.borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          widget.count > 99 ? '99+' : '${widget.count}',
          style: TextStyle(color: widget.textColor, fontSize: 10, height: 1.2, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
