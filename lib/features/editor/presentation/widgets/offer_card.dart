import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

String groupedTaka(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0 && s[i - 1] != '-') b.write(',');
    b.write(s[i]);
  }
  return '৳$b';
}

String _due(ProjectItem p) {
  final h = p.deadlineAt?.difference(DateTime.now()).inHours ?? p.deadlineHoursLeft;
  if (h < 1) return '<1h';
  if (h < 48) return '${h}h';
  return '${h ~/ 24}d';
}

/// Offer: payout and deadline first, then one line of brief. Editor payout
/// only (never client price). Long-press claims.
class OfferCard extends StatelessWidget {
  final ProjectItem project;
  final VoidCallback onLongPress;
  const OfferCard({super.key, required this.project, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final brief = project.description.trim().split('\n').first;
    Widget figure(String label, String value, {Key? key, CrossAxisAlignment a = CrossAxisAlignment.start}) => Column(
          crossAxisAlignment: a,
          children: [
            Text(label, style: t.labelSmall?.copyWith(color: c.muted)),
            const SizedBox(height: 2),
            Text(value, key: key, style: t.headlineSmall?.copyWith(color: c.text, fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: c.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('offer_${project.id}'),
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: figure('Payout', groupedTaka(project.editorPayout), key: const ValueKey('offer_payout'))),
                figure('Due in', _due(project), a: CrossAxisAlignment.end),
              ]),
              const SizedBox(height: AppSpacing.sm),
              Text(project.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(color: c.text, fontWeight: FontWeight.w500)),
              if (brief.isNotEmpty)
                Text(brief, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: c.muted)),
            ]),
          ),
        ),
      ),
    );
  }
}
