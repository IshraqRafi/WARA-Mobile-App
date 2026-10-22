import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'wara_status_chip.dart';

/// Inline message banner (error by default) on a 12% status tint.
class WaraBanner extends StatelessWidget {
  final String message;
  final WaraTone tone;
  final IconData? icon;

  const WaraBanner({super.key, required this.message, this.tone = WaraTone.error, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = tone.fg(c);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: tone.bg(c),
          borderRadius: AppRadius.brMd,
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon ?? (tone == WaraTone.error ? Icons.error_outline_rounded : Icons.info_outline_rounded), color: fg, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg))),
          ],
        ),
      ),
    );
  }
}
