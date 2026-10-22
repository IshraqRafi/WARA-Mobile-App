import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';

String groupedTaka(num v) => '৳${groupedDigits(v)}';

String groupedDigits(num v) {
  final s = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0 && s[i - 1] != '-') b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// Hours to the deadline (live when deadlineAt is set).
int offerHoursLeft(ProjectItem p, DateTime now) => p.deadlineAt?.difference(now).inHours ?? p.deadlineHoursLeft;

/// Compact deadline pill text: '<1h', '30h', '2d'.
String offerDue(int h) => h < 1 ? '<1h' : (h < 48 ? '${h}h' : '${h ~/ 24}d');

/// Posted within the last 24h (hidden on legacy docs without postedAt).
bool isNewOffer(ProjectItem p, DateTime now) {
  final at = p.postedAt;
  return at != null && now.difference(at) < const Duration(hours: 24);
}

/// Live deadline label: '2d left', '5h left', '<1h left', 'Overdue'.
String offerDueLabel(int h) => h < 0 ? 'Overdue' : '${offerDue(h)} left';

/// Compact marketplace offer (~76dp). Editor payout only, never client
/// price. Missing fields are hidden.
class OfferCard extends StatelessWidget {
  final ProjectItem project;
  final VoidCallback onLongPress;
  final VoidCallback? onTap;
  final DateTime? now;
  const OfferCard({super.key, required this.project, required this.onLongPress, this.onTap, this.now});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final at = now ?? DateTime.now();
    final skill = project.requiredSkills.map((s) => s.trim()).where((s) => s.isNotEmpty).firstOrNull;
    final h = offerHoursLeft(project, at);
    final dueColor = h < 0 ? c.error : (h < 24 ? c.warning : c.muted);
    const tab = [FontFeature.tabularFigures()];
    final meta = t.bodySmall?.copyWith(color: c.muted, fontFeatures: tab);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        scale: 0.98,
        child: Material(
          color: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: c.border, width: 0.5)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('offer_${project.id}'),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  if (isNewOffer(project, at)) ...[
                    Semantics(
                      label: 'New',
                      child: Container(key: const ValueKey('offer_new'), width: 6, height: 6,
                          decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(project.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: t.titleSmall?.copyWith(color: c.text, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  Text.rich(
                    key: const ValueKey('offer_payout'),
                    TextSpan(children: [
                      TextSpan(text: '৳', style: t.labelSmall?.copyWith(color: c.muted, fontWeight: FontWeight.w500)),
                      TextSpan(text: groupedDigits(project.editorPayout),
                          style: t.titleMedium?.copyWith(color: c.text, fontWeight: FontWeight.w700, fontFeatures: tab)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 4),
                Text.rich(
                  key: const ValueKey('offer_meta'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  TextSpan(style: meta, children: [
                    TextSpan(text: offerDueLabel(h), style: meta?.copyWith(color: dueColor, fontWeight: h < 24 ? FontWeight.w600 : null)),
                    if (skill != null) TextSpan(text: '  ·  $skill'),
                  ]),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only offer detail (tap). Shows the brief; payout only.
Future<void> showOfferDetail(BuildContext context, ProjectItem p) {
  final c = context.colors;
  final t = Theme.of(context).textTheme;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
    builder: (_) => SafeArea(
      child: Padding(
        key: const ValueKey('offer_detail'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.title, style: t.titleMedium?.copyWith(color: c.text, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(groupedTaka(p.editorPayout), style: t.titleSmall?.copyWith(color: c.text, fontFeatures: const [FontFeature.tabularFigures()])),
          if (p.requiredSkills.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(p.requiredSkills.join(' · '), style: t.bodySmall?.copyWith(color: c.muted)),
          ],
          if (p.description.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(p.description.trim(), style: t.bodyMedium?.copyWith(color: c.text)),
          ],
          const SizedBox(height: 12),
          Text('Swipe right or long-press the card to claim.', style: t.bodySmall?.copyWith(color: c.muted)),
        ]),
      ),
    ),
  );
}

/// Shimmer placeholder matching [OfferCard]'s compact height.
class OfferCardSkeleton extends StatelessWidget {
  const OfferCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border, width: 0.5)),
        child: const Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: 0.6, child: SkeletonBox(height: 16))), SizedBox(width: 12), SkeletonBox(width: 64, height: 18)]),
          SkeletonBox(width: 110, height: 12),
        ]),
      ),
    );
  }
}
