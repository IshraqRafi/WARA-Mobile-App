import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'wara_logo.dart';

/// Shared top bar for every tab: logo, page title, optional one-line
/// subtitle, optional trailing action. One size and style everywhere.
class WaraPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// 0 = expanded, 1 = collapsed (driven by [CollapsingHeader]).
  final double collapse;

  const WaraPageHeader({super.key, required this.title, this.subtitle, this.trailing, this.collapse = 0});

  static const double logoSize = 40;
  static const double logoSizeCollapsed = 34;

  static TextStyle? titleStyle(BuildContext context) => Theme.of(context)
      .textTheme
      .titleLarge
      ?.copyWith(color: context.colors.text, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.15);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = collapse.clamp(0.0, 1.0);
    final logo = logoSize + (logoSizeCollapsed - logoSize) * t;
    final sub = subtitle;
    return Row(
      children: [
        WaraLogo(size: logo),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle(context), maxLines: 1, overflow: TextOverflow.ellipsis),
              if (sub != null && sub.isNotEmpty)
                ClipRect(
                  child: Align(
                    alignment: Alignment.topLeft,
                    heightFactor: 1 - t,
                    child: Opacity(
                      opacity: 1 - t,
                      child: Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: c.muted),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}
