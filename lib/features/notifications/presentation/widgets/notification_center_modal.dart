import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../payments/presentation/payout_reveal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../projects/domain/project_provider.dart';
import '../../domain/notification_models.dart';
import '../../domain/notification_provider.dart';

void showNotificationCenter(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.colors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
    builder: (_) => const NotificationSheet(),
  );
}

/// Bell with unread badge; pops and shakes when the count goes up.
class NotificationBellButton extends ConsumerStatefulWidget {
  const NotificationBellButton({super.key});

  @override
  ConsumerState<NotificationBellButton> createState() => _BellState();
}

class _BellState extends ConsumerState<NotificationBellButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    ref.listen<int>(unreadNotificationsProvider, (prev, next) {
      if (prev != null && next > prev && !Motion.reduced(context)) {
        Haptics.light();
        _c.forward(from: 0);
      }
    });
    final unread = ref.watch(unreadNotificationsProvider);
    final label = unreadLabel(unread);
    return Semantics(
      button: true,
      label: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
      child: InkWell(
        key: const ValueKey('notification_bell'),
        onTap: () => showNotificationCenter(context),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final t = _c.value;
            // Small damped shake + pop.
            final angle = math.sin(t * math.pi * 6) * (1 - t) * 0.18;
            final scale = 1 + math.sin(t * math.pi) * 0.12;
            return Transform.rotate(angle: angle, child: Transform.scale(scale: scale, child: child));
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  unread > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
                  color: unread > 0 ? colors.text : colors.muted,
                  size: 20,
                ),
              ),
              if (label.isNotEmpty)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    key: const ValueKey('notification_badge'),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: colors.error,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.bg, width: 1.5),
                    ),
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.1)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String relativeTime(DateTime t, [DateTime? now]) {
  final d = (now ?? DateTime.now()).difference(t);
  if (d.inMinutes < 1) return 'now';
  if (d.inMinutes < 60) return '${d.inMinutes}m';
  if (d.inHours < 24) return '${d.inHours}h';
  if (d.inDays < 7) return '${d.inDays}d';
  return '${t.day}/${t.month}';
}

IconData notificationIcon(NotificationType t) => switch (t) {
      NotificationType.revision => Icons.edit_note_rounded,
      NotificationType.approved => Icons.check_circle_outline_rounded,
      NotificationType.message => Icons.chat_bubble_outline_rounded,
      NotificationType.assigned => Icons.person_add_alt_rounded,
      NotificationType.submitted => Icons.upload_rounded,
      NotificationType.payment => Icons.account_balance_wallet_outlined,
    };

class NotificationSheet extends ConsumerWidget {
  const NotificationSheet({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, AppNotification n) async {
    if (!n.read) ref.read(notificationActionsProvider).markRead(n.id);
    final rootCtx = Navigator.of(context, rootNavigator: true).context;
    Navigator.of(context).pop();
    final router = GoRouter.maybeOf(context);
    final isManager = ref.read(authProvider).user?.role == UserRole.manager;
    if (!isManager && (n.type == NotificationType.payment || n.type == NotificationType.approved)) {
      final project = ref.read(projectsProvider).where((p) => p.id == n.projectId).firstOrNull;
      final amount = amountFromBody(n.body) ?? project?.editorPayout;
      if (amount != null && amount > 0 && rootCtx.mounted) {
        final trx = trxFromBody(n.body);
        await showPayoutReveal(rootCtx, amount: amount,
            title: n.type == NotificationType.payment ? 'Payment received' : 'Approved',
            detail: trx != null ? 'TrxID $trx' : project?.title);
      }
    }
    if (router == null) return;
    if (n.chatId != null) {
      router.push('/chat/${n.chatId}');
    } else if (n.projectId != null) {
      if (isManager) {
        router.go(n.type == NotificationType.submitted ? '/manager/pending' : '/manager/workflow');
      } else {
        ref.read(expandedCardProvider('workspace').notifier).state = n.projectId;
        router.go('/editor/workspace');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final items = ref.watch(notificationsProvider).valueOrNull ?? const <AppNotification>[];
    final unread = items.where((n) => !n.read).length;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Text('Notifications', style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (unread > 0)
                    TextButton(
                      key: const ValueKey('mark_all_read'),
                      onPressed: () => ref.read(notificationActionsProvider).markAllRead(),
                      child: const Text('Mark all read'),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text("You're all caught up", style: TextStyle(color: c.muted, fontSize: 13)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => Divider(height: 1, indent: 56, color: c.border),
                  itemBuilder: (context, i) {
                    final n = items[i];
                    return ListTile(
                      key: ValueKey('notif_${n.id}'),
                      onTap: () => _open(context, ref, n),
                      leading: Icon(notificationIcon(n.type), color: n.read ? c.muted : c.text, size: 22),
                      title: Text(n.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.text, fontSize: 14, fontWeight: n.read ? FontWeight.w500 : FontWeight.w700)),
                      subtitle: n.body.isEmpty
                          ? null
                          : Text(n.body, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted, fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(relativeTime(n.createdAt), style: TextStyle(color: c.muted, fontSize: 12)),
                          if (!n.read) ...[
                            const SizedBox(width: 8),
                            Container(width: 7, height: 7, decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle)),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
