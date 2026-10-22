import 'package:flutter/widgets.dart';
import 'motion.dart';

/// A number whose changed digits slide vertically, like an odometer:
/// up when the value grows, down when it shrinks. Unchanged digits stay put,
/// so only the columns that change animate. Static text with reduce-motion.
class RollingCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final Duration duration;

  /// Thousands separators (1,234,567).
  final bool grouped;

  const RollingCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.duration = const Duration(milliseconds: 420),
    this.grouped = false,
  });

  static String format(int v, {bool grouped = false}) => grouped
      ? '$v'.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')
      : '$v';

  @override
  State<RollingCounter> createState() => _RollingCounterState();
}

class _RollingCounterState extends State<RollingCounter> {
  bool _up = true;

  @override
  void didUpdateWidget(RollingCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _up = widget.value > old.value;
  }

  @override
  Widget build(BuildContext context) {
    final digits = RollingCounter.format(widget.value, grouped: widget.grouped);
    final label = '${widget.prefix}$digits${widget.suffix}';
    final d = Motion.of(context, widget.duration);
    if (d == Duration.zero) return Text(label, style: widget.style);
    final style = DefaultTextStyle.of(context).style.merge(widget.style);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.prefix.isNotEmpty) Text(widget.prefix, style: style),
          // Keyed from the right so the ones column stays the ones column
          // when the number gains or loses a digit.
          for (var i = 0; i < digits.length; i++)
            _Digit(
              key: ValueKey(digits.length - i),
              char: digits[i],
              up: _up,
              duration: d,
              style: style,
            ),
          if (widget.suffix.isNotEmpty) Text(widget.suffix, style: style),
        ],
      ),
    );
  }
}

class _Digit extends StatelessWidget {
  final String char;
  final bool up;
  final Duration duration;
  final TextStyle style;

  const _Digit({super.key, required this.char, required this.up, required this.duration, required this.style});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Motion.curve,
        switchOutCurve: Motion.curve,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.center,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey(char);
          // Incoming enters from below (up) / above (down); outgoing plays
          // its animation in reverse, so it leaves the opposite way.
          final begin = Offset(0, (incoming ? 1.0 : -1.0) * (up ? 1 : -1));
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: Offset.zero).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: Text(char, key: ValueKey(char), style: style),
      ),
    );
  }
}
