import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/notification_models.dart';
import '../../domain/notification_provider.dart';
import '../../../chat/domain/chat_models.dart';
import '../../../chat/domain/chat_provider.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';

void showNotificationCenter(BuildContext context) {
  final colors = context.colors;
  showModalBottomSheet(
    context: context,
    backgroundColor: colors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _NotificationCenterSheet(),
  );
}

class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final unreadCount = ref.watch(notificationProvider.select((s) => s.unreadCount));

    return InkWell(
      onTap: () => showNotificationCenter(context),
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              unreadCount > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded,
              color: unreadCount > 0 ? colors.primary : colors.muted,
              size: 20,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.bg, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationCenterSheet extends ConsumerWidget {
  const _NotificationCenterSheet();

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.projectNew:
        return Icons.rocket_launch_rounded;
      case NotificationType.projectClaimed:
        return Icons.work_rounded;
      case NotificationType.submissionReceived:
        return Icons.file_upload_rounded;
      case NotificationType.projectApproved:
        return Icons.check_circle_rounded;
      case NotificationType.revisionRequested:
        return Icons.rate_review_rounded;
      case NotificationType.ratingReceived:
        return Icons.star_rounded;
      case NotificationType.chatMessage:
        return Icons.chat_bubble_rounded;
    }
  }

  Color _colorForType(NotificationType type) {
    switch (type) {
      case NotificationType.projectNew:
        return Colors.orangeAccent;
      case NotificationType.projectClaimed:
        return Colors.blueAccent;
      case NotificationType.submissionReceived:
        return Colors.cyanAccent;
      case NotificationType.projectApproved:
        return Colors.greenAccent;
      case NotificationType.revisionRequested:
        return Colors.amberAccent;
      case NotificationType.ratingReceived:
        return const Color(0xFFFFD700); // Gold
      case NotificationType.chatMessage:
        return Colors.indigoAccent;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(notificationProvider);
    final notifications = state.notifications;
    final unreadCount = state.unreadCount;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.muted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: colors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Notifications',
                  style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount New',
                      style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const Spacer(),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Mark all as read',
                      style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: colors.border, height: 1),

          // Content List
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined, color: colors.muted, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'All caught up!',
                          style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No new notifications for your agency right now.',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final iconColor = _colorForType(notif.type);

                      return InkWell(
                        onTap: () {
                          if (!notif.isRead) {
                            ref.read(notificationProvider.notifier).markAsRead(notif.id);
                          }
                          if (notif.type == NotificationType.chatMessage && notif.relatedId != null) {
                            Navigator.pop(context);
                            final convos = ref.read(chatProvider).conversations;
                            final targetConvo = convos.firstWhere(
                              (c) => c.id == notif.relatedId,
                              orElse: () => ChatConversation(
                                id: notif.relatedId!,
                                agencyId: notif.agencyId,
                                type: notif.relatedId == 'agency_general' ? ConversationType.channel : ConversationType.direct,
                                title: notif.title.replaceFirst('💬 Message from ', ''),
                                participantIds: [],
                                participantNames: {},
                                participantPhotos: {},
                                lastMessage: notif.body,
                                lastSenderName: '',
                                lastMessageTime: notif.createdAt,
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(
                                  conversationId: targetConvo.id,
                                  title: targetConvo.title,
                                  type: targetConvo.type,
                                ),
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: notif.isRead ? colors.surface : colors.surface.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: notif.isRead
                                  ? colors.border
                                  : colors.primary.withValues(alpha: 0.35),
                              width: notif.isRead ? 1 : 1.2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_iconForType(notif.type), color: iconColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              color: colors.text,
                                              fontSize: 13,
                                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatTimeAgo(notif.createdAt),
                                          style: TextStyle(color: colors.muted, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.body,
                                      style: TextStyle(
                                        color: notif.isRead ? colors.muted : colors.text.withValues(alpha: 0.85),
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!notif.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
