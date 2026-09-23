import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../notifications/presentation/widgets/notification_center_modal.dart';
import '../../../projects/domain/project_provider.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/chat_models.dart';
import '../../domain/chat_provider.dart';
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

    // Channels
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
                  const NotificationBellButton(),
                ],
              ),
            ),

            // ── Seamless Modern Search Bar ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => ref.read(chatProvider.notifier).setSearchQuery(v),
                style: TextStyle(color: colors.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search messages, channels, or team members...',
                  hintStyle: TextStyle(color: colors.muted, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, color: colors.primary, size: 20),
                  filled: true,
                  fillColor: colors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: colors.primary.withValues(alpha: 0.8), width: 1.2),
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded, color: colors.muted, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            ref.read(chatProvider.notifier).setSearchQuery('');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Live Stream of Members for Direct Messages ──────────────
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: ref.watch(firestoreServiceProvider).streamEditors(agencyId: user?.agencyId),
                builder: (context, snapshot) {
                  final editors = snapshot.data ?? [];

                  // Build list of all team member profiles (excluding current user)
                  final allMembers = <Map<String, dynamic>>[];

                  // If logged-in user is an editor, add the Agency Director/Manager profile
                  if (user?.role == UserRole.editor) {
                    allMembers.add({
                      'id': 'manager_director',
                      'name': user?.agencyName.isNotEmpty == true ? '${user!.agencyName} Director' : 'Ishraq Rafi (Director)',
                      'email': 'director@wara.io',
                      'photoUrl': null,
                      'specialization': 'Agency Director • Studio Head',
                    });
                  }

                  // Add editors
                  for (final e in editors) {
                    final eid = e['id'] as String? ?? e['uid'] as String? ?? '';
                    final email = e['email'] as String? ?? '';
                    if (eid == user?.id || (user?.email != null && email == user!.email)) {
                      continue; // Skip self
                    }
                    allMembers.add(e);
                  }

                  // Apply search filter if query active
                  final q = chatState.searchQuery.trim().toLowerCase();
                  final filteredMembers = q.isEmpty
                      ? allMembers
                      : allMembers.where((m) {
                          final name = (m['name'] as String? ?? '').toLowerCase();
                          final spec = (m['specialization'] as String? ?? '').toLowerCase();
                          final email = (m['email'] as String? ?? '').toLowerCase();
                          return name.contains(q) || spec.contains(q) || email.contains(q);
                        }).toList();

                  // Filter Chips
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'All (${1 + allMembers.length})',
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
                              label: 'Direct DMs (${allMembers.length})',
                              isSelected: chatState.activeFilter == ChatFilter.direct,
                              onTap: () => ref.read(chatProvider.notifier).setFilter(ChatFilter.direct),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Feed ListView
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          children: [
                            // 1. Pinned Agency Room Card
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
                                              channelConvos.isNotEmpty && channelConvos.first.lastMessage.isNotEmpty
                                                  ? '${channelConvos.first.lastSenderName.isNotEmpty ? "${channelConvos.first.lastSenderName}: " : ""}${channelConvos.first.lastMessage}'
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
                                    '${filteredMembers.length} team members',
                                    style: TextStyle(color: colors.muted, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (filteredMembers.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.people_outline_rounded, color: colors.muted, size: 32),
                                      const SizedBox(height: 8),
                                      Text('No team members found', style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Registered agency creative editors and managers will appear here automatically.',
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
                                  itemCount: filteredMembers.length,
                                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final member = filteredMembers[index];
                                    final memberId = member['id'] as String? ?? member['uid'] as String? ?? '';
                                    final memberName = member['name'] as String? ?? 'Team Member';
                                    final memberPhoto = member['photoUrl'] as String?;
                                    final specialization = member['specialization'] as String? ?? 'Creative Editor';

                                    // Match with existing active conversation
                                    ChatConversation? matchedConvo;
                                    for (final c in directConvos) {
                                      if (c.participantIds.contains(memberId) || c.id.contains(memberId)) {
                                        matchedConvo = c;
                                        break;
                                      }
                                    }

                                    final hasRealMessage = matchedConvo != null &&
                                        matchedConvo.lastMessage.trim().isNotEmpty &&
                                        !matchedConvo.lastMessage.startsWith('Direct conversation started');

                                    final displaySnippet = hasRealMessage
                                        ? '${matchedConvo.lastSenderName.isNotEmpty ? "${matchedConvo.lastSenderName}: " : ""}${matchedConvo.lastMessage}'
                                        : specialization;

                                    final timeLabel = hasRealMessage ? _formatTimeAgo(matchedConvo.lastMessageTime) : 'Active';

                                    return GestureDetector(
                                      onTap: () {
                                        if (matchedConvo != null) {
                                          _openConversation(matchedConvo);
                                        } else {
                                          _startDirectMessage(memberId, memberName, memberPhoto);
                                        }
                                      },
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
                                              name: memberName,
                                              photoUrl: memberPhoto,
                                              radius: 20,
                                              fontSize: 13,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    memberName,
                                                    style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    displaySnippet,
                                                    style: TextStyle(
                                                      color: hasRealMessage ? colors.text.withValues(alpha: 0.85) : colors.muted,
                                                      fontSize: 12,
                                                      fontWeight: hasRealMessage ? FontWeight.w500 : FontWeight.normal,
                                                    ),
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
                                                  timeLabel,
                                                  style: TextStyle(
                                                    color: hasRealMessage ? colors.primary : colors.muted,
                                                    fontSize: 10,
                                                    fontWeight: hasRealMessage ? FontWeight.bold : FontWeight.normal,
                                                  ),
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
