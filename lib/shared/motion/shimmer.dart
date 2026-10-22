import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'motion.dart';

/// One sweeping highlight shared by every [SkeletonBox] below it.
/// Wrapped in a [RepaintBoundary] so only the skeleton repaints. With
/// reduce-motion the skeleton is drawn static.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = c.border;
    final hi = c.isDark ? const Color(0x33FFFFFF) : const Color(0x99FFFFFF);
    final reduced = Motion.reduced(context);
    return RepaintBoundary(
      child: reduced
          ? widget.child
          : AnimatedBuilder(
              animation: _c,
              child: widget.child,
              builder: (context, child) => ShaderMask(
                blendMode: BlendMode.srcATop,
                shaderCallback: (rect) {
                  final dx = (_c.value * 3 - 1) * rect.width;
                  return LinearGradient(
                    colors: [base, Color.alphaBlend(hi, base), base],
                    stops: const [0.35, 0.5, 0.65],
                    transform: _SlideGradient(dx),
                  ).createShader(rect);
                },
                child: child,
              ),
            ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double dx;
  const _SlideGradient(this.dx);
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(dx, 0, 0);
}

/// A solid placeholder block painted in the border colour.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius radius;
  const SkeletonBox({super.key, this.width, required this.height, this.radius = AppRadius.brXs});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: context.colors.border, borderRadius: radius),
      );
}

/// Placeholder matching the collapsed project card (~72px).
class ProjectCardSkeleton extends StatelessWidget {
  const ProjectCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(color: c.card, borderRadius: AppRadius.brLg, border: Border.all(color: c.border)),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [Expanded(child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.65, child: SkeletonBox(height: 16))), SizedBox(width: AppSpacing.lg), SkeletonBox(width: 56, height: 16)]),
            Row(children: [SkeletonBox(width: 72, height: 12), SizedBox(width: AppSpacing.lg), SkeletonBox(width: 56, height: 12)]),
          ],
        ),
      ),
    );
  }
}

/// Placeholder matching an inbox row: avatar plus two text lines.
class InboxRowSkeleton extends StatelessWidget {
  const InboxRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            SkeletonBox(width: 44, height: 44, radius: AppRadius.brPill),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(widthFactor: 0.45, child: SkeletonBox(height: 14)),
                  SizedBox(height: AppSpacing.sm),
                  FractionallySizedBox(widthFactor: 0.8, child: SkeletonBox(height: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// A non-scrollable, shimmering column of [count] skeleton rows.
class SkeletonList extends StatelessWidget {
  final int count;
  final Widget item;
  final EdgeInsetsGeometry padding;
  const SkeletonList({super.key, required this.item, this.count = 5, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) => Shimmer(
        child: ListView.builder(
          padding: padding,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          itemBuilder: (_, _) => item,
        ),
      );
}
