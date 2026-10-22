import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import 'wara_status_chip.dart';

/// The single project-card spec shared by manager and editor screens:
/// client + status header, title, brief, meta (deadline / assignee),
/// optional skills, notice and submission blocks, then payout + actions.
class WaraProjectCard extends StatelessWidget {
  final ProjectItem project;
  final VoidCallback? onTap;
  final bool showAssignee;
  final bool showSkills;
  final bool showStatus;
  final int descriptionMaxLines;
  final String payoutLabel;
  /// Overrides the amount in the footer (defaults to the editor payout).
  final double? amount;
  final Widget? notice;
  final List<Widget> actions;

  const WaraProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.showAssignee = false,
    this.showSkills = false,
    this.showStatus = true,
    this.descriptionMaxLines = 2,
    this.payoutLabel = 'Editor payout',
    this.amount,
    this.notice,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final p = project;

    Widget meta(IconData icon, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: c.muted),
            const SizedBox(width: AppSpacing.xs),
            Flexible(child: Text(text, style: t.bodySmall, overflow: TextOverflow.ellipsis)),
          ],
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brLg,
          side: BorderSide(color: p.isOverdue ? c.error.withValues(alpha: 0.6) : c.border, width: p.isOverdue ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.clientName.isEmpty ? 'No client' : p.clientName.toUpperCase(),
                        style: t.labelMedium?.copyWith(letterSpacing: 0.8),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showStatus) ...[
                      const SizedBox(width: AppSpacing.sm),
                      WaraStatusChip.project(p),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(p.title, style: t.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    p.description,
                    maxLines: descriptionMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(color: c.muted),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (p.deadlineStr.isNotEmpty) meta(Icons.schedule_rounded, p.deadlineStr),
                    if (showAssignee)
                      meta(
                        p.claimedByEditorName != null ? Icons.person_rounded : Icons.person_outline_rounded,
                        p.claimedByEditorName ?? 'Unassigned',
                      ),
                  ],
                ),
                if (showSkills && p.requiredSkills.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs + 2,
                    runSpacing: AppSpacing.xs + 2,
                    children: [for (final s in p.requiredSkills) WaraStatusChip(label: s)],
                  ),
                ],
                if (notice != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  notice!,
                ],
                if (p.submissionLink != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(color: c.surface, borderRadius: AppRadius.brMd, border: Border.all(color: c.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.link_rounded, color: c.info, size: 16),
                            const SizedBox(width: AppSpacing.xs + 2),
                            Text('Submission', style: t.labelLarge),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(p.submissionLink!, style: t.bodySmall, overflow: TextOverflow.ellipsis),
                        if (p.submissionNote != null && p.submissionNote!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text('Note: ${p.submissionNote!}', style: t.bodySmall?.copyWith(color: c.text)),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Divider(height: 1, color: c.border),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(payoutLabel.toUpperCase(), style: t.labelMedium?.copyWith(letterSpacing: 0.8)),
                        Text('৳${(amount ?? p.editorPayout).toInt()}', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    if (actions.isNotEmpty)
                      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact button sizing for card action rows (still 40dp tall).
ButtonStyle waraCompactButton() => const ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(40, 40)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm)),
    );
