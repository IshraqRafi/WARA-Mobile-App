import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

enum WaraTone { neutral, success, warning, error, info }

extension WaraToneColors on WaraTone {
  Color fg(AppColors c) => switch (this) {
        WaraTone.neutral => c.text,
        WaraTone.success => c.success,
        WaraTone.warning => c.warning,
        WaraTone.error => c.error,
        WaraTone.info => c.info,
      };
  Color bg(AppColors c) => switch (this) {
        WaraTone.neutral => c.primaryTint,
        WaraTone.success => c.successTint,
        WaraTone.warning => c.warningTint,
        WaraTone.error => c.errorTint,
        WaraTone.info => c.infoTint,
      };
}

/// Maps a project to its status tone and label. Overdue wins over status.
(WaraTone, String) projectStatusTone(ProjectItem p) {
  if (p.isOverdue) return (WaraTone.error, 'Overdue');
  return switch (p.status) {
    ProjectStatus.open => (WaraTone.info, 'Open'),
    ProjectStatus.claimed => (WaraTone.warning, 'In progress'),
    ProjectStatus.submitted => (WaraTone.info, 'Submitted'),
    ProjectStatus.approved => (WaraTone.success, 'Approved'),
  };
}

/// Pill-shaped status label on a 12% tint.
class WaraStatusChip extends StatelessWidget {
  final String label;
  final WaraTone tone;
  final IconData? icon;

  const WaraStatusChip({super.key, required this.label, this.tone = WaraTone.neutral, this.icon});

  factory WaraStatusChip.project(ProjectItem p, {Key? key}) {
    final (tone, label) = projectStatusTone(p);
    return WaraStatusChip(key: key, label: label, tone: tone);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = tone.fg(c);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(color: tone.bg(c), borderRadius: AppRadius.brPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: AppSpacing.xs)],
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
        ],
      ),
    );
  }
}
