import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'motion.dart';

/// Light/dark crossfade. [reveal] snapshots the current frame, flips the
/// theme underneath, then fades the snapshot out (400ms easeOutCubic) so
/// every colour on screen blends at once. The snapshot image exists only for
/// the length of the transition.
class ThemeReveal extends StatefulWidget {
  final Widget child;
  const ThemeReveal({super.key, required this.child});

  static ThemeRevealState? maybeOf(BuildContext context) => context.findAncestorStateOfType<ThemeRevealState>();

  /// Runs [toggle] with the crossfade ([origin] is kept for API stability), or just runs it
  /// when there is no host or motion is reduced.
  static void run(BuildContext context, Offset origin, VoidCallback toggle) {
    final host = maybeOf(context);
    if (host == null || Motion.reduced(context)) {
      toggle();
      return;
    }
    host.reveal(origin, toggle);
  }

  @override
  State<ThemeReveal> createState() => ThemeRevealState();
}

class ThemeRevealState extends State<ThemeReveal> with SingleTickerProviderStateMixin {
  final GlobalKey _boundary = GlobalKey();
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  ui.Image? _image;

  void reveal(Offset origin, VoidCallback toggle) {
    final boundary = _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (_image != null || boundary == null || boundary.debugNeedsPaint) {
      toggle();
      return;
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final image = boundary.toImageSync(pixelRatio: dpr);
    setState(() {
      _image = image;
    });
    toggle();
    _c.forward(from: 0).whenComplete(_clear);
  }

  void _clear() {
    final img = _image;
    if (!mounted) return;
    setState(() => _image = null);
    img?.dispose();
  }

  @override
  void dispose() {
    _c.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (image != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, child) => Opacity(
                  opacity: 1 - Curves.easeOutCubic.transform(_c.value),
                  child: child,
                ),
                child: RawImage(image: image, fit: BoxFit.fill),
              ),
            ),
          ),
      ],
    );
  }

}
