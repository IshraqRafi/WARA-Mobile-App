import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../editor/presentation/widgets/revision_checklist.dart';
import '../../../payments/presentation/bkash_pay_screen.dart';
import '../../../payments/presentation/pay_flow.dart';
import '../../../projects/domain/project_provider.dart';
import '../widgets/revision_request_sheet.dart';

/// Submitted work, oldest submit first.
List<ProjectItem> reviewQueue(List<ProjectItem> projects) =>
    projects.where((p) => p.status == ProjectStatus.submitted).toList()
      ..sort((a, b) => (a.submittedAt ?? '').compareTo(b.submittedAt ?? ''));

/// 'Review (n)' entry; hidden when nothing is waiting.
class ReviewQueueButton extends ConsumerWidget {
  const ReviewQueueButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(projectsProvider.select((ps) => ps.where((p) => p.status == ProjectStatus.submitted).length));
    if (n == 0) return const SizedBox.shrink();
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: const ValueKey('review_queue_btn'),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.text,
            side: BorderSide(color: c.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const ReviewQueueScreen())),
          icon: const Icon(Icons.rate_review_outlined, size: 18),
          label: Text('Review ($n)'),
        ),
      ),
    );
  }
}

/// One submission at a time: approve & pay or send back, then advance.
class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});
  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  /// Queue captured on open; ids handled here are skipped as the stream catches up.
  late final List<String> _ids = reviewQueue(ref.read(projectsProvider)).map((p) => p.id).toList();
  final Set<String> _done = {};
  bool _forward = true;

  ProjectItem? get _current {
    final byId = {for (final p in ref.read(projectsProvider)) p.id: p};
    for (final id in _ids) {
      final p = byId[id];
      if (_done.contains(id) || p == null || p.status != ProjectStatus.submitted) continue;
      return p;
    }
    return null;
  }

  int get _remaining {
    final byId = {for (final p in ref.read(projectsProvider)) p.id: p};
    return _ids.where((id) => !_done.contains(id) && byId[id]?.status == ProjectStatus.submitted).length;
  }

  void _advance(String id) {
    Haptics.light();
    setState(() {
      _forward = true;
      _done.add(id);
    });
  }

  Future<void> _approve(ProjectItem p) async {
    final name = p.claimedByEditorName ?? 'Editor';
    final m = await choosePayMethod(context, title: 'Approve & pay?', detail: '${takaAmount(p.editorPayout)} to $name for ${p.title}.');
    if (m == null || !mounted) return;
    if (m == PayMethod.bkash) {
      final ok = await payWithBkashFlow(context, ref, [p], editorName: name);
      if (!ok || !mounted) return;
    } else {
      ref.read(projectsProvider.notifier).approveProject(p.id);
      Celebration.sparkle(context);
    }
    _advance(p.id);
  }

  void _revise(ProjectItem p) => showRevisionRequestSheet(
        context,
        projectTitle: p.title,
        onSend: (notes) {
          ref.read(projectsProvider.notifier).requestRevision(p.id, notes);
          WaraToast.show(context, message: 'Revision requested', icon: Icons.edit_note_rounded);
          _advance(p.id);
        },
      );

  @override
  Widget build(BuildContext context) {
    ref.watch(projectsProvider);
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final p = _current;
    final total = _ids.length;
    final left = _remaining;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: Text(p == null ? 'Review' : 'Review · ${total - left + 1} of $total', key: const ValueKey('review_progress')),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: Motion.of(context, Motion.medium),
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: Offset(_forward ? 0.08 : -0.08, 0), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: p == null
              ? Center(
                  key: const ValueKey('review_done'),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline_rounded, size: 40, color: c.success),
                    const SizedBox(height: 12),
                    Text('All reviewed', style: t.titleMedium?.copyWith(color: c.text)),
                    const SizedBox(height: 16),
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
                  ]),
                )
              : _ReviewCard(key: ValueKey('review_${p.id}'), project: p, onApprove: () => _approve(p), onRevise: () => _revise(p)),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ProjectItem project;
  final VoidCallback onApprove;
  final VoidCallback onRevise;
  const _ReviewCard({super.key, required this.project, required this.onApprove, required this.onRevise});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final p = project;
    final items = parseChecklist(p.revisionNotes);
    final link = p.submissionLink ?? '';
    Widget chip(String label, Color fg, Color bg, String key) => Container(
          key: ValueKey(key),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Text(label, style: t.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
        );
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
      Text(p.title, style: t.titleLarge?.copyWith(color: c.text, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('${p.claimedByEditorName ?? 'Editor'}  ·  ${takaAmount(p.editorPayout)}', style: t.bodyMedium?.copyWith(color: c.muted)),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        chip('v${p.submissionVersion < 1 ? 1 : p.submissionVersion}', c.text, c.surface, 'review_version'),
        if (p.submittedLate) chip('Late', c.error, c.error.withValues(alpha: 0.12), 'review_late'),
      ]),
      const SizedBox(height: 20),
      if (link.isNotEmpty) ...[
        Text('Delivery', style: t.labelMedium?.copyWith(color: c.muted)),
        const SizedBox(height: 6),
        Material(
          color: c.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: c.border, width: 0.5)),
          child: ListTile(
            key: const ValueKey('review_link'),
            dense: true,
            leading: Icon(Icons.link_rounded, color: c.primary, size: 20),
            title: Text(link, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(color: c.text)),
            trailing: Icon(Icons.copy_rounded, color: c.muted, size: 18),
            onTap: () {
              Clipboard.setData(ClipboardData(text: link));
              WaraToast.show(context, message: 'Link copied', icon: Icons.link_rounded);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
      if ((p.submissionNote ?? '').isNotEmpty) ...[
        Text('Note', style: t.labelMedium?.copyWith(color: c.muted)),
        const SizedBox(height: 6),
        Text(p.submissionNote!, style: t.bodyMedium?.copyWith(color: c.text)),
        const SizedBox(height: 16),
      ],
      if (items.isNotEmpty) ...[
        Text('Checklist  ${p.revisionChecks.where((i) => i >= 0 && i < items.length).length}/${items.length}',
            key: const ValueKey('review_checklist'), style: t.labelMedium?.copyWith(color: c.muted)),
        const SizedBox(height: 6),
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(p.revisionChecks.contains(i) ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18, color: p.revisionChecks.contains(i) ? c.success : c.muted),
              const SizedBox(width: 8),
              Expanded(child: Text(items[i], style: t.bodyMedium?.copyWith(color: c.text))),
            ]),
          ),
        const SizedBox(height: 16),
      ],
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: OutlinedButton(
            key: const ValueKey('review_revise'),
            onPressed: onRevise,
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Revision'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            key: const ValueKey('review_approve'),
            onPressed: onApprove,
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Approve & pay'),
          ),
        ),
      ]),
    ]);
  }
}
