import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'motion.dart';

/// Circular light/dark reveal. [reveal] snapshots the current frame, flips
/// the theme underneath, then shrinks the snapshot away through a growing
/// circular hole centred on the toggle. The snapshot image and controller
/// exist only for the 450ms of the transition.
class ThemeReveal extends StatefulWidget {
  final Widget child;
  const ThemeReveal({super.key, required this.child});

  static ThemeRevealState? maybeOf(BuildContext context) => context.findAncestorStateOfType<ThemeRevealState>();

  /// Runs [toggle] with the reveal from [origin] (global), or just runs it
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
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  ui.Image? _image;
  Offset _origin = Offset.zero;

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
      _origin = origin;
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
                builder: (context, child) {
                  final size = MediaQuery.sizeOf(context);
                  final maxR = _farthestCorner(_origin, size);
                  return ClipPath(
                    clipper: _HoleClipper(_origin, maxR * Curves.easeInOutCubic.transform(_c.value)),
                    child: child,
                  );
                },
                child: RawImage(image: image, fit: BoxFit.fill),
              ),
            ),
          ),
      ],
    );
  }

  static double _farthestCorner(Offset o, Size s) => [
        o.distance,
        (o - Offset(s.width, 0)).distance,
        (o - Offset(0, s.height)).distance,
        (o - Offset(s.width, s.height)).distance,
      ].reduce(math.max);
}

/// Whole rect minus a circle: the old-theme snapshot with a hole in it.
class _HoleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;
  _HoleClipper(this.center, this.radius);

  @override
  Path getClip(Size size) => Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_HoleClipper old) => old.radius != radius || old.center != center;
}
