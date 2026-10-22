import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';

enum LinkKind { drive, frameio, dropbox, youtube, other }

/// Null when [raw] is not a usable http(s) URL with a dotted host.
LinkKind? linkKind(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) return null;
  final host = uri.host.toLowerCase();
  if (!host.contains('.') || host.startsWith('.') || host.endsWith('.')) return null;
  bool on(String d) => host == d || host.endsWith('.$d');
  if (on('drive.google.com') || on('docs.google.com')) return LinkKind.drive;
  if (on('frame.io') || on('f.io')) return LinkKind.frameio;
  if (on('dropbox.com') || on('db.tt')) return LinkKind.dropbox;
  if (on('youtube.com') || on('youtu.be')) return LinkKind.youtube;
  return LinkKind.other;
}

String linkKindLabel(LinkKind k) => switch (k) {
      LinkKind.drive => 'Google Drive',
      LinkKind.frameio => 'Frame.io',
      LinkKind.dropbox => 'Dropbox',
      LinkKind.youtube => 'YouTube',
      LinkKind.other => 'Link',
    };

IconData _kindIcon(LinkKind k) => switch (k) {
      LinkKind.drive => Icons.add_to_drive_rounded,
      LinkKind.frameio => Icons.movie_filter_outlined,
      LinkKind.dropbox => Icons.inventory_2_outlined,
      LinkKind.youtube => Icons.play_circle_outline_rounded,
      LinkKind.other => Icons.link_rounded,
    };

typedef SubmitCallback = void Function(String link, String note);

/// Delivery link + note. Shows the version this submit will create.
/// [openChecks] > 0 asks once before submitting with unticked revision items.
Future<void> showSubmitSheet(BuildContext context, ProjectItem project,
    {required SubmitCallback onSubmit, int openChecks = 0}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => SubmitSheet(project: project, onSubmit: onSubmit, openChecks: openChecks),
  );
}

class SubmitSheet extends StatefulWidget {
  final ProjectItem project;
  final SubmitCallback onSubmit;
  final int openChecks;
  const SubmitSheet({super.key, required this.project, required this.onSubmit, this.openChecks = 0});

  @override
  State<SubmitSheet> createState() => _SubmitSheetState();
}

class _SubmitSheetState extends State<SubmitSheet> {
  late final _link = TextEditingController(text: widget.project.submissionLink ?? '');
  final _note = TextEditingController();
  bool _touched = false;
  bool _warned = false;

  @override
  void initState() {
    super.initState();
    _link.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _link.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final kind = linkKind(_link.text);
    if (kind == null) {
      setState(() => _touched = true);
      Haptics.light();
      return;
    }
    if (widget.openChecks > 0 && !_warned) {
      setState(() => _warned = true);
      Haptics.light();
      return;
    }
    widget.onSubmit(_link.text.trim(), _note.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    final kind = linkKind(_link.text);
    final showError = _touched && kind == null;
    final version = widget.project.submissionVersion + 1;
    InputDecoration deco(String hint, {Widget? prefix, String? error}) => InputDecoration(
          filled: true,
          fillColor: c.surface,
          hintText: hint,
          hintStyle: TextStyle(color: c.muted, fontSize: 13),
          prefixIcon: prefix,
          errorText: error,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
        );
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Submit', style: t.titleMedium?.copyWith(color: c.text, fontWeight: FontWeight.w600))),
          Container(
            key: const ValueKey('submit_version'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
            child: Text('v$version', style: t.labelMedium?.copyWith(color: c.muted)),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('submit_link'),
          controller: _link,
          keyboardType: TextInputType.url,
          autocorrect: false,
          style: TextStyle(color: c.text, fontSize: 14),
          decoration: deco('Delivery link',
              prefix: Icon(_kindIcon(kind ?? LinkKind.other), size: 18, color: kind == null ? c.muted : c.primary),
              error: showError ? 'Enter a full link (https://…)' : null),
        ),
        AnimatedSwitcher(
          duration: Motion.of(context),
          child: kind == null || kind == LinkKind.other
              ? const SizedBox(height: AppSpacing.sm)
              : Padding(
                  key: ValueKey(kind),
                  padding: const EdgeInsets.only(top: 6, bottom: 2, left: 4),
                  child: Text(linkKindLabel(kind), key: const ValueKey('submit_kind'),
                      style: t.labelSmall?.copyWith(color: c.muted)),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const ValueKey('submit_note'),
          controller: _note,
          maxLines: 3,
          minLines: 1,
          style: TextStyle(color: c.text, fontSize: 14),
          decoration: deco('Note (optional)'),
        ),
        AnimatedSize(
          duration: Motion.of(context),
          child: _warned
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Text(
                    '${widget.openChecks} revision ${widget.openChecks == 1 ? 'item is' : 'items are'} unticked. Submit anyway?',
                    key: const ValueKey('submit_warn'),
                    style: t.bodySmall?.copyWith(color: c.warning),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('submit_go'),
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(_warned ? 'Submit anyway' : 'Submit v$version'),
          ),
        ),
      ]),
    );
  }
}
