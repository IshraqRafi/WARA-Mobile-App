import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../features/projects/domain/project_provider.dart';
import '../motion/motion.dart';
import 'wara_status_chip.dart';

/// Urgency of a project's deadline, shown by tinting the deadline meta.
enum ProjectUrgency { none, soon, overdue }

ProjectUrgency projectUrgency(ProjectItem p) {
  if (p.isOverdue) return ProjectUrgency.overdue;
  final live = p.status == ProjectStatus.open || p.status == ProjectStatus.claimed;
  if (live && p.deadlineHoursLeft < 24) return ProjectUrgency.soon;
  return ProjectUrgency.none;
}

/// The shared project card. Collapsed it is a ~72px row: title + payout,
/// then icon meta and a status dot. Tapping expands it in place to the
/// brief, notes and the role's [actions]. With [listId], only one card per
/// list is expanded at a time.
class WaraProjectCard extends ConsumerStatefulWidget {
  final ProjectItem project;
  final String? listId;
  final bool showAssignee;
  final bool showSkills;
  final bool showStatus;
  final String payoutLabel;
  /// Overrides the payout amount (defaults to the editor payout).
  final double? amount;
  /// Extra line in the expanded body (e.g. editor payout on finance).
  final Widget? notice;
  final List<Widget> actions;

  const WaraProjectCard({
    super.key,
    required this.project,
    this.listId,
    this.showAssignee = false,
    this.showSkills = false,
    this.showStatus = true,
    this.payoutLabel = 'Payout',
    this.amount,
    this.notice,
    this.actions = const [],
  });

  @override
  ConsumerState<WaraProjectCard> createState() => _WaraProjectCardState();
}

class _WaraProjectCardState extends ConsumerState<WaraProjectCard> {
  bool _localExpanded = false;

  bool get _expanded {
    final id = widget.listId;
    if (id == null) return _localExpanded;
    return ref.watch(expandedCardProvider(id).select((e) => e == widget.project.id));
  }

  void _toggle(bool expanded) {
    final id = widget.listId;
    if (id == null) {
      setState(() => _localExpanded = !expanded);
    } else {
      ref.read(expandedCardProvider(id).notifier).state = expanded ? null : widget.project.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final p = widget.project;
    final expanded = _expanded;
    final (tone, statusLabel) = projectStatusTone(p);
    final urgent = switch (projectUrgency(p)) {
      ProjectUrgency.overdue => c.error,
      ProjectUrgency.soon => c.warning,
      ProjectUrgency.none => null,
    };

    Widget meta(IconData icon, String text, {Color? color}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? c.muted),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                text,
                style: color == null ? t.bodySmall : t.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );

    final amount = (widget.amount ?? p.editorPayout).toInt();

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(p.title, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const SizedBox(width: AppSpacing.md),
              GlowPulse(
                active: p.status == ProjectStatus.approved,
                color: c.success,
                child: Text('৳$amount', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Row(
            children: [
              if (p.deadlineStr.isNotEmpty) Flexible(child: meta(Icons.schedule_rounded, p.deadlineStr, color: urgent)),
              if (widget.showAssignee) ...[
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: meta(
                    p.claimedByEditorName != null ? Icons.person_rounded : Icons.person_outline_rounded,
                    p.claimedByEditorName ?? 'Unassigned',
                  ),
                ),
              ],
              const Spacer(),
              if (widget.showStatus)
                Tooltip(
                  message: statusLabel,
                  child: Semantics(
                    label: statusLabel,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: tone.fg(c), shape: BoxShape.circle),
                    ),
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: Motion.of(context),
                curve: Motion.curve,
                child: Icon(Icons.expand_more_rounded, size: 18, color: c.muted),
              ),
            ],
          ),
        ],
      ),
    );

    final body = !expanded
        ? const SizedBox(width: double.infinity)
        : Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, color: c.border),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p.clientName.isEmpty ? 'No client' : p.clientName.toUpperCase(),
                        style: t.labelMedium?.copyWith(letterSpacing: 0.8),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(widget.payoutLabel, style: t.labelMedium),
                  ],
                ),
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(p.description, style: t.bodyMedium),
                ],
                if (widget.showSkills && p.requiredSkills.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.xs + 2,
                    runSpacing: AppSpacing.xs + 2,
                    children: [for (final s in p.requiredSkills) WaraStatusChip(label: s)],
                  ),
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
                            Expanded(child: Text(p.submissionLink!, style: t.bodySmall, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                        if (p.submissionNote != null && p.submissionNote!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(p.submissionNote!, style: t.bodySmall?.copyWith(color: c.text)),
                        ],
                      ],
                    ),
                  ),
                ],
                if (widget.notice != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  widget.notice!,
                ],
                if (widget.actions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [for (final a in widget.actions) Pressable(child: a)],
                    ),
                  ),
                ],
              ],
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Pressable(
        scale: expanded ? 1 : 0.97,
        child: Material(
          color: c.card,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg, side: BorderSide(color: c.border)),
          clipBehavior: Clip.antiAlias,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  expanded: expanded,
                  child: InkWell(
                    key: ValueKey('card_toggle_${p.id}'),
                    onTap: () => _toggle(expanded),
                    child: header,
                  ),
                ),
                AnimatedSize(
                  duration: Motion.of(context),
                  curve: Motion.curve,
                  alignment: Alignment.topCenter,
                  child: body,
                ),
              ],
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
