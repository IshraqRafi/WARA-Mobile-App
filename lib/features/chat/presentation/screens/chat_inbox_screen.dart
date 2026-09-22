import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../../shared/widgets/wara_theme_toggle.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/chat_models.dart';
import '../../domain/chat_provider.dart';
import '../widgets/chat_member_strip.dart';
import 'chat_room_screen.dart';

class ChatInboxScreen extends ConsumerStatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  ConsumerState<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}';
  }

  void _openConversation(ChatConversation convo) {
    final currentUser = ref.read(authProvider).user;
    final otherUid = convo.getOtherParticipantId(currentUser?.id ?? '');
    final otherName = convo.getDisplayName(currentUser?.id ?? '');
    final otherPhoto = convo.getDisplayPhoto(currentUser?.id ?? '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomScreen(
          conversationId: convo.id,
          title: otherName,
          type: convo.type,
          otherUserId: otherUid,
          otherUserPhoto: otherPhoto,
        ),
      ),
    );
  }

  void _startDirectMessage(String otherUid, String otherName, String? otherPhoto) async {
    final convo = await ref.read(chatProvider.notifier).getOrCreateDirectConversation(
          otherUserId: otherUid,
          otherUserName: otherName,
          otherUserPhoto: otherPhoto,
        );

    if (mounted) {
      _openConversation(convo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final user = ref.watch(authProvider).user;
    final chatState = ref.watch(chatProvider);
    final conversations = chatState.filteredConversations;

    // Separate into Channel and DMs
    final channelConvos = conversations.where((c) => c.type == ConversationType.channel).toList();
    final directConvos = conversations.where((c) => c.type == ConversationType.direct).toList();

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 12),
              child: Row(
                children: [
                  const WaraLogo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agency Messenger',
                          style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${user?.agencyName ?? "Wara Media Group"} • Team Chat',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const WaraThemeToggle(),
                ],
              ),
            ),

            // ── Active Creative Team Horizontal Strip ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TEAM DIRECT MESSAGES',
                    style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1),
                  ),
                  Text(
                    'Tap member to chat',
                    style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ChatMemberStrip(onSelectMember: _startDirectMessage),
            const SizedBox(height: 8),

            // ── Search & Filter Bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => ref.read(chatProvider.notifier).setSearchQuery(v),
                  style: TextStyle(color: colors.text, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search conversations or messages...',
                    hintStyle: TextStyle(color: colors.muted, fontSize: 12),
                    prefixIcon: Icon(Icons.search_rounded, color: colors.muted, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: colors.muted, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              ref.read(chatProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Filter Segment Tabs ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All (${conversations.length})',
                    isSelected: chatState.activeFilter == ChatFilter.all,
                    onTap: () => ref.read(chatProvider.notifier).setFilter(ChatFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Agency Room',
                    isSelected: chatState.activeFilter == ChatFilter.channel,
                    onTap: () => ref.read(chatProvider.notifier).setFilter(ChatFilter.channel),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Direct DMs (${directConvos.length})',
                    isSelected: chatState.activeFilter == ChatFilter.direct,
                    onTap: () => ref.read(chatProvider.notifier).setFilter(ChatFilter.direct),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Conversations Feed ──────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                children: [
                  // 1. Pinned Agency Room Card (Always accessible)
                  if (chatState.activeFilter != ChatFilter.direct) ...[
                    GestureDetector(
                      onTap: () {
                        final general = channelConvos.isNotEmpty
                            ? channelConvos.first
                            : ChatConversation(
                                id: 'agency_general',
                                agencyId: user?.agencyId ?? 'agency_demo_wara',
                                type: ConversationType.channel,
                                title: '# agency-room',
                                participantIds: [],
                                participantNames: {},
                                participantPhotos: {},
                                lastMessage: 'Welcome to ${user?.agencyName ?? "Agency"} room!',
                                lastSenderName: user?.name ?? 'Director',
                                lastMessageTime: DateTime.now(),
                              );
                        _openConversation(general);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.primary.withValues(alpha: 0.4), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Icon(Icons.tag_rounded, color: colors.primary, size: 22),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '# agency-room',
                                        style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colors.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'ALL TEAM',
                                          style: TextStyle(color: colors.primary, fontSize: 9.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    channelConvos.isNotEmpty
                                        ? '${channelConvos.first.lastSenderName}: ${channelConvos.first.lastMessage}'
                                        : 'Official studio communication and project announcement channel',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: colors.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  channelConvos.isNotEmpty ? _formatTimeAgo(channelConvos.first.lastMessageTime) : 'Live',
                                  style: TextStyle(color: colors.muted, fontSize: 10),
                                ),
                                const SizedBox(height: 4),
                                Icon(Icons.chevron_right_rounded, color: colors.muted, size: 18),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 2. Direct Messages Section
                  if (chatState.activeFilter != ChatFilter.channel) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DIRECT MESSAGES',
                          style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1),
                        ),
                        Text(
                          '${directConvos.length} active',
                          style: TextStyle(color: colors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (directConvos.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.mark_chat_unread_outlined, color: colors.muted, size: 32),
                            const SizedBox(height: 8),
                            Text('No 1-on-1 direct messages yet', style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Tap any creative editor or director in the top strip to start a private conversation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.muted, fontSize: 11),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: directConvos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final convo = directConvos[index];
                          final displayName = convo.getDisplayName(user?.id ?? '');
                          final displayPhoto = convo.getDisplayPhoto(user?.id ?? '');

                          return GestureDetector(
                            onTap: () => _openConversation(convo),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: colors.border),
                              ),
                              child: Row(
                                children: [
                                  WaraAvatar(
                                    name: displayName,
                                    photoUrl: displayPhoto,
                                    radius: 20,
                                    fontSize: 13,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          convo.lastMessage,
                                          style: TextStyle(color: colors.muted, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatTimeAgo(convo.lastMessageTime),
                                        style: TextStyle(color: colors.muted, fontSize: 10),
                                      ),
                                      const SizedBox(height: 4),
                                      Icon(Icons.chevron_right_rounded, color: colors.muted, size: 18),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (colors.isDark ? Colors.black : Colors.white) : colors.text,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
