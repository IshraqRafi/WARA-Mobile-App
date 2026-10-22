import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Section title with optional subtitle and trailing action.
class WaraSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const WaraSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, style: text.titleMedium)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: text.bodySmall),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Grouped card used for settings/forms: an optional header above a
/// rounded container whose children are separated by dividers.
class WaraSectionCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsetsGeometry contentPadding;
  final bool divided;

  const WaraSectionCard({
    super.key,
    this.title,
    this.subtitle,
    required this.children,
    this.contentPadding = EdgeInsets.zero,
    this.divided = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 && divided) items.add(Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg, color: c.border));
      items.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          WaraSectionHeader(
            title: title!,
            subtitle: subtitle,
            padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.sm, left: AppSpacing.xs),
          ),
        Container(
          padding: contentPadding,
          decoration: BoxDecoration(color: c.card, borderRadius: AppRadius.brLg, border: Border.all(color: c.border)),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: items),
        ),
      ],
    );
  }
}
