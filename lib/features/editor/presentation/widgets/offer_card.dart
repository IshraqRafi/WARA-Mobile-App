import 'dart:ui';
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

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// 'Oct 25, 6:30 PM'.
String offerDate(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '${_months[d.month - 1]} ${d.day}, $h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// 'just now', '5m ago', '3h ago', '2d ago'.
String offerAgo(DateTime d, DateTime now) {
  final x = now.difference(d);
  if (x.inMinutes < 1) return 'just now';
  if (x.inHours < 1) return '${x.inMinutes}m ago';
  if (x.inDays < 1) return '${x.inHours}h ago';
  return '${x.inDays}d ago';
}

/// Centered offer detail over a blurred, dimmed backdrop. Payout only,
/// never client price. [onClaim] runs after the dialog closes so the
/// screen's claim-with-undo flow owns the snackbar.
Future<void> showOfferDetail(BuildContext context, ProjectItem p,
    {required VoidCallback onClaim, String? agencyName, DateTime? now}) async {
  final reduced = Motion.reduced(context);
  final claimed = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => OfferDetailDialog(project: p, agencyName: agencyName, now: now ?? DateTime.now()),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return AnimatedBuilder(
        animation: curved,
        builder: (_, _) => Stack(children: [
          Positioned.fill(
            child: IgnorePointer(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7 * curved.value, sigmaY: 7 * curved.value),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.28 * curved.value)),
              ),
            ),
          ),
          Opacity(
            opacity: curved.value,
            child: reduced ? child : Transform.scale(scale: 0.96 + 0.04 * curved.value, child: child),
          ),
        ]),
      );
    },
  );
  if (claimed == true) onClaim();
}

class OfferDetailDialog extends StatelessWidget {
  final ProjectItem project;
  final String? agencyName;
  final DateTime now;
  const OfferDetailDialog({super.key, required this.project, required this.now, this.agencyName});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final p = project;
    final h = offerHoursLeft(p, now);
    final dueColor = h < 0 ? c.error : (h < 24 ? c.warning : c.muted);
    const tab = [FontFeature.tabularFigures()];
    final label = t.labelSmall?.copyWith(color: c.muted, fontWeight: FontWeight.w600, letterSpacing: 0.4);
    final skills = p.requiredSkills.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    final brief = p.description.trim();
    final notes = (p.revisionNotes ?? '').trim();
    final agency = (agencyName ?? '').trim();
    final deadline = p.deadlineAt != null ? offerDate(p.deadlineAt!.toLocal()) : (p.deadlineStr.trim().isEmpty ? null : p.deadlineStr.trim());

    Widget section(String title, Widget body) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title.toUpperCase(), style: label), const SizedBox(height: 6), body]),
        );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 420, maxHeight: MediaQuery.sizeOf(context).height * 0.8),
          child: Material(
            key: const ValueKey('offer_detail'),
            color: c.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.border, width: 0.5)),
            clipBehavior: Clip.antiAlias,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(p.title, style: t.titleMedium?.copyWith(color: c.text, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('offer_detail_close'),
                    tooltip: 'Close',
                    icon: Icon(Icons.close_rounded, size: 20, color: c.muted),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ]),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(text: '৳ ', style: t.titleSmall?.copyWith(color: c.muted)),
                      TextSpan(text: groupedDigits(p.editorPayout),
                          style: t.headlineMedium?.copyWith(color: c.text, fontWeight: FontWeight.w700, fontFeatures: tab)),
                    ])),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(offerDueLabel(h), key: const ValueKey('offer_detail_due'),
                          style: t.bodySmall?.copyWith(color: dueColor, fontWeight: FontWeight.w600, fontFeatures: tab)),
                      if (deadline != null) Text('Due $deadline', style: t.bodySmall?.copyWith(color: c.muted, fontFeatures: tab)),
                    ]),
                    if (p.postedAt != null || agency.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [if (p.postedAt != null) 'Posted ${offerAgo(p.postedAt!, now)}', if (agency.isNotEmpty) agency].join('  ·  '),
                        style: t.bodySmall?.copyWith(color: c.muted),
                      ),
                    ],
                    if (skills.isNotEmpty)
                      section('Skills', Text(skills.join('  ·  '), style: t.bodyMedium?.copyWith(color: c.text))),
                    if (brief.isNotEmpty) section('Brief', SelectableText(brief, style: t.bodyMedium?.copyWith(color: c.text, height: 1.45))),
                    if (notes.isNotEmpty)
                      section('Revision notes', Text(notes, style: t.bodyMedium?.copyWith(color: c.text, height: 1.45))),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border, width: 0.5))),
                child: FilledButton(
                  key: const ValueKey('offer_detail_claim'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Claim'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
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
