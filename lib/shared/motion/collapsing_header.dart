import 'package:flutter/material.dart';
import '../widgets/wara_page_header.dart';
import 'motion.dart';

/// Pinned sliver version of [WaraPageHeader]: the logo shrinks slightly, the
/// subtitle folds away and a hairline appears as the list scrolls.
/// Scroll-driven only. Under reduce-motion it stays at the compact size.
class CollapsingHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color background;
  final Color divider;
  final EdgeInsets padding;

  const CollapsingHeader({
    super.key,
    required this.title,
    required this.background,
    required this.divider,
    this.subtitle,
    this.trailing,
    this.padding = EdgeInsets.zero,
  });

  static const double expanded = 76;
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
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: h.background,
          border: Border(bottom: BorderSide(color: h.divider.withValues(alpha: t), width: 0.5)),
        ),
        child: Padding(
          padding: h.padding,
          child: Center(
            child: WaraPageHeader(title: h.title, subtitle: h.subtitle, trailing: h.trailing, collapse: t),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_Delegate old) =>
      old.h.title != h.title ||
      old.h.subtitle != h.subtitle ||
      old.h.trailing != h.trailing ||
      old.h.background != h.background ||
      old.h.divider != h.divider ||
      old.reduced != reduced ||
      old.textScale != textScale;
}
