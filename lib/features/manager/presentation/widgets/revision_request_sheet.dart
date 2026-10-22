import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Opens the revision sheet; [onSend] receives the trimmed notes.
Future<void> showRevisionRequestSheet(BuildContext context,
    {required String projectTitle, required ValueChanged<String> onSend}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
    builder: (_) => RevisionRequestSheet(projectTitle: projectTitle, onSend: onSend),
  );
}

class RevisionRequestSheet extends StatefulWidget {
  final String projectTitle;
  final ValueChanged<String> onSend;
  const RevisionRequestSheet({super.key, required this.projectTitle, required this.onSend});

  @override
  State<RevisionRequestSheet> createState() => _RevisionRequestSheetState();
}

class _RevisionRequestSheetState extends State<RevisionRequestSheet> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = _ctrl.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Request revision', style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(widget.projectTitle, style: TextStyle(color: c.muted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('revision_input'),
            controller: _ctrl,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What needs changing?',
              helperText: 'One item per line',
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.border)),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const ValueKey('revision_send'),
              onPressed: text.isEmpty
                  ? null
                  : () {
                      widget.onSend(text);
                      Navigator.of(context).maybePop();
                    },
              child: const Text('Send'),
            ),
          ),
        ],
      ),
    );
  }
}
