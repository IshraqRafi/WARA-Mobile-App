import 'package:flutter/widgets.dart';
import 'motion.dart';

/// '৳1,234' style formatter used while tweening currency.
String takaFormat(num v) =>
    '৳${v.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

/// A number that tweens from its previous value (0 on first build) to
/// [value] over 600ms easeOutCubic. Every frame is formatted with [format],
/// so currency keeps its symbol and separators mid-tween. Jumps straight to
/// the value under reduce-motion.
class AnimatedCount extends StatefulWidget {
  final num value;
  final String Function(num v) format;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCount({
    super.key,
    required this.value,
    this.format = _plain,
    this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  static String _plain(num v) => '${v.round()}';

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  double _from = 0;
  late double _to = widget.value.toDouble();
  bool _started = false;

  double get _current => _from + (_to - _from) * Curves.easeOutCubic.transform(_c.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context) || _to == 0) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCount old) {
    super.didUpdateWidget(old);
    final next = widget.value.toDouble();
    if (next == _to) return;
    _from = _current;
    _to = next;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: widget.format(_to),
        excludeSemantics: true,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => Text(widget.format(_current), maxLines: 1, softWrap: false, style: widget.style),
        ),
      );
}
