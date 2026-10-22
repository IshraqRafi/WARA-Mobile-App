import 'package:flutter/material.dart';
import '../../../payments/presentation/bkash_pay_screen.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';
import '../../../../shared/widgets/wara_avatar.dart';

enum Urgency { overdue, thisWeek, later }

Urgency urgencyOf(ProjectItem p) {
  if (p.isOverdue || p.deadlineHoursLeft < 0) return Urgency.overdue;
  if (p.deadlineHoursLeft <= 7 * 24) return Urgency.thisWeek;
  return Urgency.later;
}

/// What one editor is owed: editor payouts on claimed or submitted work
/// (approved = paid, per the existing approve flow). Only submitted work can
/// be marked paid; claimed work is still in progress.
class EditorOwed {
  final String id;
  final String name;
  final List<ProjectItem> projects; // most urgent first
  const EditorOwed(this.id, this.name, this.projects);

  double get owed => projects.fold(0, (a, p) => a + p.editorPayout);
  int get earliestHours => projects.first.deadlineHoursLeft;
  List<ProjectItem> get payable => [for (final p in projects) if (p.status == ProjectStatus.submitted) p];
  bool get anyOverdue => projects.any((p) => urgencyOf(p) == Urgency.overdue);
}

class EditorLedger {
  final List<EditorOwed> editors; // most urgent first
  final Map<Urgency, double> byUrgency;
  const EditorLedger(this.editors, this.byUrgency);

  double get total => byUrgency.values.fold(0, (a, b) => a + b);

  factory EditorLedger.of(List<ProjectItem> projects) {
    final groups = <String, List<ProjectItem>>{};
    final names = <String, String>{};
    final buckets = {for (final u in Urgency.values) u: 0.0};
    for (final p in projects) {
      final id = p.claimedByEditorId;
      if (id == null || (p.status != ProjectStatus.claimed && p.status != ProjectStatus.submitted)) continue;
      groups.putIfAbsent(id, () => []).add(p);
      names[id] = p.claimedByEditorName ?? 'Editor';
      buckets[urgencyOf(p)] = buckets[urgencyOf(p)]! + p.editorPayout;
    }
    int hrs(ProjectItem p) => urgencyOf(p) == Urgency.overdue ? -1 << 20 : p.deadlineHoursLeft;
    final editors = [
      for (final e in groups.entries) EditorOwed(e.key, names[e.key]!, e.value..sort((a, b) => hrs(a).compareTo(hrs(b)))),
    ]..sort((a, b) {
        final c = hrs(a.projects.first).compareTo(hrs(b.projects.first));
        return c != 0 ? c : b.owed.compareTo(a.owed);
      });
    return EditorLedger(editors, buckets);
  }
}

String taka(double v) =>
    '৳${v.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

String dueLabel(ProjectItem p) {
  if (urgencyOf(p) == Urgency.overdue) {
    final d = (-p.deadlineHoursLeft / 24).ceil();
    return d <= 0 ? 'Overdue' : '${d}d overdue';
  }
  final d = (p.deadlineHoursLeft / 24).floor();
  return d == 0 ? '${p.deadlineHoursLeft}h left' : '${d}d left';
}

String dueDate(int hoursLeft, {DateTime? now}) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final d = (now ?? DateTime.now()).add(Duration(hours: hoursLeft));
  return '${d.day} ${m[d.month - 1]}';
}

Color urgencyColor(AppColors c, Urgency u) => switch (u) {
      Urgency.overdue => c.error.withValues(alpha: 0.6),
      Urgency.thisWeek => c.warning.withValues(alpha: 0.5),
      Urgency.later => c.muted.withValues(alpha: 0.4),
    };

const urgencyLabel = {Urgency.overdue: 'Overdue', Urgency.thisWeek: 'This week', Urgency.later: 'Later'};

/// Thin segmented bar of owed amounts by urgency, with a tiny legend.
class UrgencyBar extends StatelessWidget {
  final Map<Urgency, double> byUrgency;
  const UrgencyBar({super.key, required this.byUrgency});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final parts = [for (final u in Urgency.values) if (byUrgency[u]! > 0) u];
    final total = byUrgency.values.fold<double>(0, (a, b) => a + b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          key: const ValueKey('urgency_bar'),
          height: 6,
          child: total == 0
              ? ColoredBox(color: c.border)
              : Row(children: [
                  for (var i = 0; i < parts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      key: ValueKey('urgency_${parts[i].name}'),
                      flex: (byUrgency[parts[i]]! / total * 1000).round().clamp(1, 1000),
                      child: ColoredBox(color: urgencyColor(c, parts[i])),
                    ),
                  ],
                ]),
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: AppSpacing.md, runSpacing: 4, children: [
        for (final u in Urgency.values)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 6, height: 6, decoration: BoxDecoration(color: urgencyColor(c, u), shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('${urgencyLabel[u]} ${taka(byUrgency[u]!)}', style: text.labelSmall?.copyWith(color: c.muted)),
          ]),
      ]),
    ]);
  }
}

/// One editor: avatar, name, owed, count and earliest due; tap to expand the
/// project rows. [onPay] receives the projects to approve (already confirmed).
class EditorOwedCard extends StatefulWidget {
  final EditorOwed editor;
  final void Function(List<ProjectItem> projects, PayMethod method) onPay;
  const EditorOwedCard({super.key, required this.editor, required this.onPay});

  @override
  State<EditorOwedCard> createState() => _EditorOwedCardState();
}

class _EditorOwedCardState extends State<EditorOwedCard> {
  bool _open = false;

  Future<void> _pay(List<ProjectItem> ps) async {
    final e = widget.editor;
    final sum = ps.fold<double>(0, (a, p) => a + p.editorPayout);
    final m = await choosePayMethod(
      context,
      title: 'Mark paid?',
      detail: ps.length == 1 ? '${taka(sum)} to ${e.name} for ${ps.first.title}.' : '${taka(sum)} to ${e.name} for ${ps.length} projects.',
    );
    if (m != null && mounted) widget.onPay(ps, m);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final e = widget.editor;
    final n = e.projects.length;
    final dur = Motion.of(context, const Duration(milliseconds: 260));
    final payable = e.payable;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: c.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg, side: BorderSide(color: c.border)),
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: dur,
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            InkWell(
              key: ValueKey('editor_${e.id}'),
              onTap: () {
                Haptics.tick();
                setState(() => _open = !_open);
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(children: [
                  WaraAvatar(name: e.name, radius: 18, fontSize: 13),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(color: c.text, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '$n ${n == 1 ? 'project' : 'projects'} · ${e.anyOverdue ? 'Overdue' : 'Due ${dueDate(e.earliestHours)}'}',
                        style: text.labelSmall?.copyWith(color: e.anyOverdue ? c.error : c.muted),
                      ),
                    ]),
                  ),
                  Text(taka(e.owed), style: text.titleMedium?.copyWith(color: c.text, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: dur,
                    curve: Curves.easeOutCubic,
                    child: Icon(Icons.expand_more_rounded, size: 20, color: c.muted),
                  ),
                ]),
              ),
            ),
            if (_open) ...[
              Divider(height: 1, color: c.border),
              for (final p in e.projects) _row(context, c, text, p),
              if (payable.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 4, AppSpacing.md, AppSpacing.sm),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: ValueKey('pay_all_${e.id}'),
                      onPressed: () => _pay(payable),
                      child: Text('Mark all paid · ${taka(payable.fold(0, (a, p) => a + p.editorPayout))}'),
                    ),
                  ),
                ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AppColors c, TextTheme text, ProjectItem p) {
    final u = urgencyOf(p);
    final canPay = p.status == ProjectStatus.submitted;
    return Padding(
      key: ValueKey('row_${p.id}'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium?.copyWith(color: c.text)),
            Text(
              canPay ? '${dueLabel(p)} · In review' : dueLabel(p),
              style: text.labelSmall?.copyWith(color: u == Urgency.overdue ? c.error : c.muted),
            ),
          ]),
        ),
        Text(taka(p.editorPayout), style: text.labelLarge?.copyWith(color: c.text, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        if (canPay)
          IconButton(
            key: ValueKey('pay_${p.id}'),
            tooltip: 'Mark paid',
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.check_circle_outline_rounded, color: c.success, size: 20),
            onPressed: () => _pay([p]),
          )
        else
          const SizedBox(width: 40),
      ]),
    );
  }
}
