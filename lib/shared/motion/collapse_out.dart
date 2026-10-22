import 'package:flutter/widgets.dart';
import 'motion.dart';

/// Fades and collapses [child] to zero height when [out] becomes true,
/// then calls [onEnd]. Used to animate a claimed card out of a list.
class CollapseOut extends StatefulWidget {
  final bool out;
  final VoidCallback? onEnd;
  final Widget child;

  const CollapseOut({super.key, required this.out, required this.child, this.onEnd});

  @override
  State<CollapseOut> createState() => _CollapseOutState();
}

class _CollapseOutState extends State<CollapseOut> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: 1);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeInCubic);

  @override
  void didUpdateWidget(CollapseOut old) {
    super.didUpdateWidget(old);
    if (!old.out && widget.out) {
      _c.duration = Motion.of(context, Motion.medium);
      _c.reverse().whenComplete(() {
        if (mounted) widget.onEnd?.call();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
        sizeFactor: _a,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: _a, child: widget.child),
      );
}
