import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Shared empty state: icon, title, message and an optional action.
/// Mirrors [WaraErrorState] so empty and failed screens look consistent.
class WaraEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool compact;

  const WaraEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final badge = compact ? 48.0 : 64.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: badge,
              height: badge,
              decoration: BoxDecoration(color: colors.primaryTint, shape: BoxShape.circle),
              child: Icon(icon, size: badge * 0.45, color: colors.muted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, textAlign: TextAlign.center, style: text.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(message, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.muted)),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
