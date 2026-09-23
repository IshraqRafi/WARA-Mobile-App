import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../domain/chat_models.dart';
import '../../domain/chat_provider.dart';
import '../widgets/chat_bubble.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String title;
  final ConversationType type;
  final String? otherUserId;
  final String? otherUserPhoto;

  const ChatRoomScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.type = ConversationType.channel,
    this.otherUserId,
    this.otherUserPhoto,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Subscribe to messages stream for this conversation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).subscribeToConversationMessages(widget.conversationId);
      ref.read(chatProvider.notifier).markAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSend() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    _msgCtrl.clear();
    setState(() => _isSending = true);

    await ref.read(chatProvider.notifier).sendMessage(
          conversationId: widget.conversationId,
          text: text,
        );

    setState(() => _isSending = false);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _showAttachLinkDialog() {
    final colors = context.colors;
    final linkCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.attachment_rounded, color: colors.primary, size: 20),
            const SizedBox(width: 8),
            Text('Share Asset Link', style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paste a Google Drive, Dropbox, Frame.io, or Vimeo URL:', style: TextStyle(color: colors.muted, fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: linkCtrl,
              autofocus: true,
              style: TextStyle(color: colors.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://drive.google.com/...',
                hintStyle: TextStyle(color: colors.muted, fontSize: 12),
                fillColor: colors.card,
                filled: true,
                prefixIcon: Icon(Icons.link_rounded, color: colors.primary, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              style: TextStyle(color: colors.text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Add a brief note (optional)...',
                hintStyle: TextStyle(color: colors.muted, fontSize: 12),
                fillColor: colors.card,
                filled: true,
                prefixIcon: Icon(Icons.notes_rounded, color: colors.muted, size: 18),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.isDark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final link = linkCtrl.text.trim();
              final note = noteCtrl.text.trim();
              if (link.isEmpty) return;

              final fullText = note.isNotEmpty ? '$note\n$link' : link;
              ref.read(chatProvider.notifier).sendMessage(
                    conversationId: widget.conversationId,
                    text: fullText,
                    attachmentUrl: link,
                  );
              Navigator.pop(ctx);
              Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
              WaraToast.show(context, message: 'Asset link shared with team!', icon: Icons.check_circle_rounded);
            },
            child: const Text('Share Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentUser = ref.watch(authProvider).user;
    final messagesMap = ref.watch(chatProvider).messagesMap;
    final messages = messagesMap[widget.conversationId] ?? [];
    final isChannel = widget.type == ConversationType.channel;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.text, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            if (isChannel)
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.tag_rounded, color: colors.primary, size: 18),
              )
            else
              WaraAvatar(
                name: widget.title,
                photoUrl: widget.otherUserPhoto,
                radius: 17,
                fontSize: 12,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isChannel
                        ? '${currentUser?.agencyName ?? "Agency Room"} • General Channel'
                        : 'Active in Agency Workspace',
                    style: TextStyle(color: colors.muted, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: colors.muted, size: 20),
            onPressed: () {
              WaraToast.show(
                context,
                message: isChannel
                    ? 'Agency General Channel: visible to all verified team members.'
                    : 'End-to-end encrypted direct message with ${widget.title}.',
                icon: Icons.shield_outlined,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Message Feed
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.card,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isChannel ? Icons.forum_outlined : Icons.chat_bubble_outline_rounded,
                                size: 36,
                                color: colors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isChannel ? 'Welcome to # agency-room!' : 'Start your conversation',
                              style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isChannel
                                  ? 'This is the primary agency channel. Announce project drops, discuss timelines, or share asset folders.'
                                  : 'Direct messaging thread with ${widget.title}. All messages stay private within your agency.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.isMe(currentUser?.id ?? '');

                        // Check if previous message is from same sender to group avatars
                        final isFirstInGroup = index == 0 || messages[index - 1].senderId != msg.senderId;

                        return ChatBubble(
                          message: msg,
                          isMe: isMe,
                          showAvatar: isFirstInGroup,
                        );
                      },
                    ),
            ),

            // Bottom Input Composer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Row(
                children: [
                  // Attachment / Asset Link Button
                  IconButton(
                    icon: Icon(Icons.add_link_rounded, color: colors.primary, size: 22),
                    tooltip: 'Share Asset Link',
                    onPressed: _showAttachLinkDialog,
                  ),

                  // Text Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colors.border),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        style: TextStyle(color: colors.text, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: isChannel ? 'Message # agency-room...' : 'Message ${widget.title}...',
                          hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button
                  GestureDetector(
                    onTap: _handleSend,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: colors.isDark ? Colors.black : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
