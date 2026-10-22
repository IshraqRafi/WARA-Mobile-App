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

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (parts.isEmpty) return '';
  return (parts.length == 1 ? parts.first.substring(0, 1) : '${parts[0][0]}${parts[1][0]}').toUpperCase();
}

/// Marketplace offer. Editor payout only (never client price). Fields
/// that are missing on the doc are hidden, never filled in.
class OfferCard extends StatelessWidget {
  final ProjectItem project;
  final VoidCallback onLongPress;
  final String? agencyName;
  final DateTime? now;
  const OfferCard({super.key, required this.project, required this.onLongPress, this.agencyName, this.now});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final at = now ?? DateTime.now();
    final brief = project.description.trim().split('\n').first.trim();
    final type = project.requiredSkills.where((s) => s.trim().isNotEmpty).firstOrNull;
    final h = offerHoursLeft(project, at);
    final urgent = h < 24;
    final ini = initials(agencyName ?? '');
    const tab = [FontFeature.tabularFigures()];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Pressable(
        scale: 0.98,
        child: Material(
          color: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: c.border, width: 0.5)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('offer_${project.id}'),
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (type != null)
                    Flexible(
                      child: Container(
                        key: const ValueKey('offer_type'),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(6), border: Border.all(color: c.border, width: 0.5)),
                        child: Text(type, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: t.labelSmall?.copyWith(color: c.muted, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  if (isNewOffer(project, at)) ...[
                    const SizedBox(width: 8),
                    Semantics(
                      label: 'New',
                      child: Container(key: const ValueKey('offer_new'), width: 6, height: 6,
                          decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
                    ),
                  ],
                  const Spacer(),
                  Container(
                    key: const ValueKey('offer_due'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: urgent ? c.warningTint : c.card,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.schedule_rounded, size: 12, color: urgent ? c.warning : c.muted),
                      const SizedBox(width: 4),
                      Text(offerDue(h),
                          style: t.labelSmall?.copyWith(color: urgent ? c.warning : c.muted, fontWeight: FontWeight.w600, fontFeatures: tab)),
                    ]),
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                Text.rich(
                  key: const ValueKey('offer_payout'),
                  TextSpan(children: [
                    TextSpan(text: '৳ ', style: t.titleSmall?.copyWith(color: c.muted, fontWeight: FontWeight.w500)),
                    TextSpan(text: groupedDigits(project.editorPayout),
                        style: t.headlineMedium?.copyWith(color: c.text, fontWeight: FontWeight.w600, letterSpacing: -0.5, fontFeatures: tab)),
                  ]),
                ),
                const SizedBox(height: 4),
                Text(project.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: t.bodyMedium?.copyWith(color: c.text, fontWeight: FontWeight.w500)),
                if (brief.isNotEmpty)
                  Text(brief, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: c.muted)),
                if (ini.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(children: [
                    // Duration/length and included revisions aren't stored on
                    // offers yet, so they're not shown.
                    const Spacer(),
                    if (ini.isNotEmpty)
                      Tooltip(
                        message: agencyName!,
                        child: CircleAvatar(
                          key: const ValueKey('offer_avatar'),
                          radius: 11,
                          backgroundColor: c.card,
                          child: Text(ini, style: t.labelSmall?.copyWith(color: c.muted, fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ]),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder shaped like [OfferCard].
class OfferCardSkeleton extends StatelessWidget {
  const OfferCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border, width: 0.5)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [SkeletonBox(width: 56, height: 16), Spacer(), SkeletonBox(width: 40, height: 16)]),
          SizedBox(height: AppSpacing.md),
          SkeletonBox(width: 120, height: 28),
          SizedBox(height: 8),
          FractionallySizedBox(widthFactor: 0.6, child: SkeletonBox(height: 14)),
          SizedBox(height: 6),
          FractionallySizedBox(widthFactor: 0.85, child: SkeletonBox(height: 12)),
        ]),
      ),
    );
  }
}
