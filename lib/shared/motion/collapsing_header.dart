import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'motion.dart';

/// Pinned sliver header that collapses as the list scrolls: the leading
/// logo shrinks and drifts at a slower rate than the content (light
/// parallax), the title scales down, and a hairline appears once collapsed.
/// Scroll-driven only, so it costs nothing while idle. Under reduce-motion it
/// stays pinned at the compact size with no parallax.
class CollapsingHeader extends StatelessWidget {
  final Widget Function(double size) leading;
  final String title;
  final TextStyle? titleStyle;
  final Widget? trailing;
  final Color background;
  final Color divider;
  final EdgeInsets padding;

  const CollapsingHeader({
    super.key,
    required this.leading,
    required this.title,
    required this.background,
    required this.divider,
    this.titleStyle,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  static const double expanded = 84;
  static const double collapsed = 60;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return SliverPersistentHeader(
      pinned: true,
      delegate: _Delegate(this, reduced, MediaQuery.textScalerOf(context).scale(1)),
    );
  }
}

class _Delegate extends SliverPersistentHeaderDelegate {
  final CollapsingHeader h;
  final bool reduced;
  final double textScale;
  _Delegate(this.h, this.reduced, this.textScale);

  @override
  double get maxExtent => reduced ? minExtent : CollapsingHeader.expanded * textScale.clamp(1, 1.4);
  @override
  double get minExtent => CollapsingHeader.collapsed * textScale.clamp(1, 1.4);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = reduced || range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    final logo = lerpDouble(42, 32, t)!;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: h.background,
          border: Border(bottom: BorderSide(color: h.divider.withValues(alpha: t), width: 0.5)),
        ),
        child: Padding(
          padding: h.padding,
          child: Row(
            children: [
              // Parallax: the logo lags the collapse slightly.
              Transform.translate(offset: Offset(0, (1 - t) * -4 + shrinkOffset.clamp(0, range) * 0.08), child: h.leading(logo)),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.scale(
                    scale: lerpDouble(1, 0.86, t)!,
                    alignment: Alignment.centerLeft,
                    child: Text(h.title, style: h.titleStyle, maxLines: 1),
                  ),
                ),
              ),
              if (h.trailing != null) h.trailing!,
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_Delegate old) =>
      old.h != h || old.reduced != reduced || old.textScale != textScale;
}
