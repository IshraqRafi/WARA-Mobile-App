import 'package:flutter/widgets.dart';
import 'motion.dart';

/// An int that counts up from 0 on first build and tweens to new values.
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String prefix;
  final Duration duration;

  const AnimatedCount({super.key, required this.value, this.style, this.prefix = '', this.duration = const Duration(milliseconds: 600)});

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, duration);
    if (d == Duration.zero) return Text('$prefix$value', style: style);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: d,
      curve: Motion.curve,
      builder: (context, v, _) => Text('$prefix$v', style: style),
    );
  }
}
