import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../domain/chat_models.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showAvatar;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showAvatar = true,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isManager = message.senderRole == 'manager';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Left Avatar for Other Senders
          if (!isMe) ...[
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 2),
                child: WaraAvatar(
                  name: message.senderName,
                  photoUrl: message.senderPhotoUrl,
                  radius: 16,
                  fontSize: 10,
                ),
              )
            else
              const SizedBox(width: 40),
          ],

          // Bubble Container
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender Name & Role (Only on other's messages)
                if (!isMe && showAvatar) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.senderName,
                        style: TextStyle(
                          color: colors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isManager ? colors.primary.withValues(alpha: 0.2) : colors.card,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isManager ? colors.primary : colors.border,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          isManager ? 'DIRECTOR' : 'EDITOR',
                          style: TextStyle(
                            color: isManager ? colors.primary : colors.muted,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                ],

                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? colors.primary : colors.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isMe ? colors.primary : colors.border,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Message Content
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isMe
                              ? (colors.isDark ? Colors.black : Colors.white)
                              : colors.text,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),

                      // Detect & Render Cloud Media Link Pill (e.g. Drive / Frame.io / Vimeo)
                      if (message.hasAssetLink) ...[
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            final url = message.detectedAssetUrl;
                            if (url != null) {
                              Clipboard.setData(ClipboardData(text: url));
                              WaraToast.show(
                                context,
                                message: 'Asset link copied to clipboard!',
                                icon: Icons.link_rounded,
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? (colors.isDark ? Colors.black.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.2))
                                  : colors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isMe
                                    ? (colors.isDark ? Colors.black26 : Colors.white30)
                                    : colors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.cloud_download_outlined,
                                  size: 15,
                                  color: isMe
                                      ? (colors.isDark ? Colors.black : Colors.white)
                                      : colors.primary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    message.detectedAssetUrl ?? 'Production Asset Link',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isMe
                                          ? (colors.isDark ? Colors.black : Colors.white)
                                          : colors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.copy_rounded,
                                  size: 12,
                                  color: isMe
                                      ? (colors.isDark ? Colors.black54 : Colors.white70)
                                      : colors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 4),
                      // Message Timestamp
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            color: isMe
                                ? (colors.isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.75))
                                : colors.muted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
