import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'wara_status_chip.dart';

/// Compact metric card: tinted icon badge, big value, label.
class WaraStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final WaraTone tone;
  final VoidCallback? onTap;

  const WaraStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.tone = WaraTone.neutral,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      button: onTap != null,
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg, side: BorderSide(color: c.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: tone.bg(c), borderRadius: AppRadius.brMd),
                  child: Icon(icon, size: 20, color: tone.fg(c)),
                ),
                const SizedBox(height: AppSpacing.md),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: text.headlineSmall),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
