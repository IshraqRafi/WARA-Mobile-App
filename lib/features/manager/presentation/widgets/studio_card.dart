import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../projects/domain/project_provider.dart';

/// Manager's studio identity: name (inline edit), join key (tap to copy),
/// share, regenerate (danger confirm) and two small stats.
class StudioCard extends ConsumerStatefulWidget {
  const StudioCard({super.key});

  @override
  ConsumerState<StudioCard> createState() => _StudioCardState();
}

class _StudioCardState extends ConsumerState<StudioCard> {
  bool _editing = false;
  bool _copied = false;
  bool _busy = false;
  late final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _copy(String key) async {
    if (key.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: key));
    Haptics.light();
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _copied = false);
  }

  // No share plugin in the app: copy an invite line and say so.
  Future<void> _share(String name, String key) async {
    if (key.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: 'Join $name on wara.io with key: $key'));
    Haptics.light();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Invite copied, paste it to your editor')));
  }

  Future<void> _saveName() async {
    final clean = _name.text.trim();
    final current = ref.read(authProvider).user?.agencyName ?? '';
    if (clean.length < 2 || clean == current) {
      setState(() => _editing = false);
      return;
    }
    setState(() => _busy = true);
    final ok = await ref.read(authProvider.notifier).renameAgency(clean);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _editing = !ok;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not rename the studio')));
    }
  }

  Future<void> _regenerate() async {
    final colors = context.colors;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Regenerate join key?'),
        content: const Text('The current key stops working immediately. Editors already in the studio stay.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    Haptics.medium();
    setState(() => _busy = true);
    final key = await ref.read(authProvider.notifier).regenerateAgencyKey();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(key == null ? 'Could not regenerate the key' : 'New key ready')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(authProvider.select((s) => s.user));
    final name = user?.agencyName.isNotEmpty == true ? user!.agencyName : 'Your studio';
    final key = user?.agencyJoinKey ?? '';
    final editors = ref.watch(editorsProvider(user?.agencyId)).valueOrNull?.length;
    final active = ref.watch(projectsProvider.select(
        (l) => l.where((p) => p.status != ProjectStatus.approved).length));
    final dur = Motion.of(context, Motion.fast);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name row
          SizedBox(
            height: 40,
            child: Row(children: [
              Expanded(
                child: _editing
                    ? TextField(
                        controller: _name,
                        autofocus: true,
                        enabled: !_busy,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveName(),
                        style: TextStyle(color: colors.text, fontSize: 17, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                      )
                    : Text(name,
                        key: const Key('studio-name'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.text, fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                key: const Key('studio-edit'),
                tooltip: _editing ? 'Save name' : 'Rename studio',
                visualDensity: VisualDensity.compact,
                icon: Icon(_editing ? Icons.check_rounded : Icons.edit_outlined, size: 18, color: colors.muted),
                onPressed: _busy
                    ? null
                    : () {
                        if (_editing) {
                          _saveName();
                        } else {
                          _name.text = user?.agencyName ?? '';
                          setState(() => _editing = true);
                        }
                      },
              ),
            ]),
          ),
          const SizedBox(height: 10),
          // Key row
          Row(children: [
            Expanded(
              child: Pressable(
                enabled: key.isNotEmpty,
                child: Semantics(
                  button: true,
                  label: 'Copy join key',
                  child: GestureDetector(
                    key: const Key('studio-key'),
                    onTap: () => _copy(key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                      child: Row(children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(key.isEmpty ? '—' : key,
                                style: TextStyle(color: colors.text, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'monospace', letterSpacing: 2)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: dur,
                          transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                          child: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded,
                              key: ValueKey(_copied), size: 18, color: _copied ? colors.success : colors.muted),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Share invite',
              icon: Icon(Icons.ios_share_rounded, size: 20, color: colors.primary),
              onPressed: key.isEmpty ? null : () => _share(name, key),
            ),
          ]),
          const SizedBox(height: 10),
          // Stats + regenerate
          Row(children: [
            _Stat(value: editors?.toString() ?? '—', label: editors == 1 ? 'editor' : 'editors'),
            const SizedBox(width: 16),
            _Stat(value: '$active', label: 'active'),
            const Spacer(),
            TextButton.icon(
              key: const Key('studio-regenerate'),
              onPressed: _busy || key.isEmpty ? null : _regenerate,
              icon: Icon(Icons.refresh_rounded, size: 16, color: colors.error),
              label: Text('Regenerate', style: TextStyle(color: colors.error, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text.rich(TextSpan(children: [
      TextSpan(text: value, style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w700)),
      TextSpan(text: ' $label', style: TextStyle(color: colors.muted, fontSize: 12)),
    ]));
  }
}
