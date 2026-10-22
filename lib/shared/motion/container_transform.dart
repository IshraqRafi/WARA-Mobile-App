import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'motion.dart';

/// Hand-rolled container transform: the tapped widget's rect grows into the
/// full-screen route (and shrinks back on pop). The source colour fills the
/// morphing container while the destination fades in over its second half.
class ContainerTransformRoute<T> extends PageRoute<T> {
  final Rect source;
  final Color sourceColor;
  final double sourceRadius;
  final WidgetBuilder builder;
  final bool reduced;

  ContainerTransformRoute({
    required this.source,
    required this.sourceColor,
    required this.builder,
    this.sourceRadius = 16,
    this.reduced = false,
  });

  /// Opens [builder] growing out of the widget that owns [from].
  static Future<T?> open<T>(BuildContext from, {required WidgetBuilder builder, required Color color, double radius = 16}) {
    final box = from.findRenderObject() as RenderBox?;
    final size = MediaQuery.sizeOf(from);
    final rect = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.fromCenter(center: size.center(Offset.zero), width: 56, height: 56);
    return Navigator.of(from).push<T>(ContainerTransformRoute<T>(
      source: rect,
      sourceColor: color,
      sourceRadius: radius,
      builder: builder,
      reduced: Motion.reduced(from),
    ));
  }

  @override
  Duration get transitionDuration => reduced ? Duration.zero : const Duration(milliseconds: 380);
  @override
  Duration get reverseTransitionDuration => reduced ? Duration.zero : const Duration(milliseconds: 300);
  @override
  bool get opaque => false;
  @override
  bool get barrierDismissible => false;
  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final page = RepaintBoundary(child: child);
    return AnimatedBuilder(
      animation: animation,
      child: page,
      builder: (context, page) {
        final v = animation.value;
        if (v >= 1) return page!;
        final full = Offset.zero & MediaQuery.sizeOf(context);
        final t = Curves.easeInOutCubic.transform(v);
        final rect = Rect.lerp(source, full, t)!;
        final fade = const Interval(0.3, 1).transform(v);
        return Stack(children: [
          Positioned.fromRect(
            rect: rect,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(lerpDouble(sourceRadius, 0, t)!),
              child: ColoredBox(
                color: sourceColor,
                child: Opacity(
                  opacity: fade,
                  // Lay the page out at full size so it does not reflow while growing.
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: full.width, maxWidth: full.width,
                    minHeight: full.height, maxHeight: full.height,
                    child: page,
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }
}
