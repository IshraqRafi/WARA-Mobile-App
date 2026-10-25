import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';

/// Returns null on success, or a terse error ("Invalid key").
typedef JoinAgency = Future<String?> Function(String key);

/// Small centered rounded dialog over a blurred backdrop with one join-key
/// field. Resolves true when [onJoin] succeeded.
Future<bool> showJoinAgencyDialog(BuildContext context, {required JoinAgency onJoin}) async {
  final reduced = Motion.reduced(context);
  final ok = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: reduced ? Duration.zero : const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => JoinAgencyDialog(onJoin: onJoin),
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
  return ok == true;
}

class JoinAgencyDialog extends StatefulWidget {
  final JoinAgency onJoin;
  const JoinAgencyDialog({super.key, required this.onJoin});

  @override
  State<JoinAgencyDialog> createState() => _JoinAgencyDialogState();
}

class _JoinAgencyDialogState extends State<JoinAgencyDialog> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final key = _ctrl.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Enter a key');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await widget.onJoin(key);
    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Join an agency', style: t.titleMedium),
                  const SizedBox(height: 4),
                  Text('Enter the join key from your manager.', style: t.bodySmall?.copyWith(color: c.muted)),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('join_key_field'),
                    controller: _ctrl,
                    autofocus: true,
                    enabled: !_busy,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _join(),
                    decoration: InputDecoration(labelText: 'Join key', errorText: _error),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      key: const Key('join_agency_button'),
                      onPressed: _busy ? null : _join,
                      child: _busy
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Join'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Settings agency card. Without an agency it is tappable and opens
/// [showJoinAgencyDialog]; [onJoined] runs after a successful join.
class AgencyRoomCard extends StatelessWidget {
  final String agencyName;
  final String? joinKey;
  final bool connected;
  final JoinAgency onJoin;
  final VoidCallback? onJoined;
  const AgencyRoomCard({
    super.key,
    required this.agencyName,
    required this.joinKey,
    required this.connected,
    required this.onJoin,
    this.onJoined,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final card = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: connected ? c.primary.withValues(alpha: 0.25) : c.border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.meeting_room_rounded, color: c.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(connected ? agencyName : 'No agency connected',
                style: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(connected ? 'Connected Agency Room • Key: ${joinKey ?? "—"}' : 'Tap to join with a key',
                style: TextStyle(color: c.muted, fontSize: 12)),
          ]),
        ),
        if (connected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: c.successTint, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: c.success, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('Joined', style: TextStyle(color: c.success, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          )
        else
          Icon(Icons.chevron_right_rounded, color: c.muted, size: 20),
      ]),
    );
    if (connected) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('agency_card_join'),
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          final ok = await showJoinAgencyDialog(context, onJoin: onJoin);
          if (ok) onJoined?.call();
        },
        child: card,
      ),
    );
  }
}
