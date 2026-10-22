import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';

final _marker = RegExp(r'^\s*(?:[-*•–]|\d+[.)])\s*');

/// Manager notes split into items: one per line, list markers stripped.
List<String> parseChecklist(String? notes) => [
      for (final line in (notes ?? '').split(RegExp(r'\r?\n')))
        if (line.replaceFirst(_marker, '').trim().isNotEmpty) line.replaceFirst(_marker, '').trim(),
    ];

const _legacyPrefix = 'Revision Request: ';

/// Revision items for an in-progress project, or empty when none.
List<String> revisionItems(ProjectItem p) {
  if (p.status != ProjectStatus.claimed) return const [];
  final note = p.submissionNote ?? '';
  return parseChecklist(p.revisionNotes ?? (note.startsWith(_legacyPrefix) ? note.substring(_legacyPrefix.length) : null));
}

/// Unticked revision items on [p].
int openRevisionItems(ProjectItem p) {
  final n = revisionItems(p).length;
  return n - p.revisionChecks.where((i) => i >= 0 && i < n).length;
}

class RevisionChecklist extends StatelessWidget {
  final List<String> items;
  final List<int> checked;
  final ValueChanged<int> onToggle;
  const RevisionChecklist({super.key, required this.items, required this.checked, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final done = checked.where((i) => i >= 0 && i < items.length).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Revisions', style: t.labelMedium?.copyWith(color: c.muted))),
          Text('$done/${items.length} done', key: const ValueKey('revision_progress'),
              style: t.labelMedium?.copyWith(color: done == items.length ? c.success : c.muted)),
        ]),
        const SizedBox(height: 4),
        for (var i = 0; i < items.length; i++)
          InkWell(
            key: ValueKey('revision_item_$i'),
            borderRadius: BorderRadius.circular(8),
            onTap: () => onToggle(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedSwitcher(
                  duration: Motion.of(context, Motion.fast),
                  child: Icon(
                    checked.contains(i) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    key: ValueKey(checked.contains(i)),
                    size: 18,
                    color: checked.contains(i) ? c.primary : c.muted,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: Motion.of(context, Motion.fast),
                    style: (t.bodySmall ?? const TextStyle()).copyWith(
                      color: checked.contains(i) ? c.muted : c.text,
                      decoration: checked.contains(i) ? TextDecoration.lineThrough : null,
                      decorationColor: c.muted,
                    ),
                    child: Text(items[i]),
                  ),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}
