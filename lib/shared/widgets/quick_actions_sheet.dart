import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../motion/motion.dart';

class QuickAction {
  final String id;
  final String label;
  final IconData icon;
  final String? hint;
  final VoidCallback run;
  const QuickAction({required this.id, required this.label, required this.icon, required this.run, this.hint});
}

/// Filters [actions] by a case-insensitive match on label or hint.
List<QuickAction> filterQuickActions(List<QuickAction> actions, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return actions;
  return actions
      .where((a) => a.label.toLowerCase().contains(q) || (a.hint?.toLowerCase().contains(q) ?? false))
      .toList();
}

/// Search palette opened by long-pressing the tab bar. Runs the chosen
/// action after the sheet closes.
Future<void> showQuickActions(BuildContext context, List<QuickAction> actions) async {
  Haptics.medium();
  final picked = await showModalBottomSheet<QuickAction>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: Motion.reduced(context) ? AnimationStyle.noAnimation : null,
    builder: (_) => QuickActionsSheet(actions: actions),
  );
  picked?.run();
}

class QuickActionsSheet extends StatefulWidget {
  final List<QuickAction> actions;
  const QuickActionsSheet({super.key, required this.actions});

  @override
  State<QuickActionsSheet> createState() => _QuickActionsSheetState();
}

class _QuickActionsSheetState extends State<QuickActionsSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown = filterQuickActions(widget.actions, _q);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        key: const Key('quick_actions'),
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border.all(color: colors.border),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('quick_actions_search'),
              autofocus: true,
              onChanged: (v) => setState(() => _q = v),
              decoration: InputDecoration(
                hintText: 'Search actions or projects',
                prefixIcon: Icon(Icons.search_rounded, color: colors.muted, size: 20),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: shown.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No matches', key: const Key('quick_actions_empty'), style: TextStyle(color: colors.muted)),
                    )
                  : Material(
                      type: MaterialType.transparency,
                      child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: shown.length,
                      itemBuilder: (ctx, i) {
                        final a = shown[i];
                        return ListTile(
                          key: Key('qa_${a.id}'),
                          dense: true,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          leading: Icon(a.icon, size: 20, color: colors.muted),
                          title: Text(a.label, style: TextStyle(color: colors.text)),
                          subtitle: a.hint == null ? null : Text(a.hint!, style: TextStyle(color: colors.muted, fontSize: 12)),
                          onTap: () => Navigator.of(context).pop(a),
                        );
                      },
                    ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
