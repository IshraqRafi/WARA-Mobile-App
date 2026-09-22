import 'package:cloud_firestore/cloud_firestore.dart';

enum ConversationType { channel, direct }

class ChatConversation {
  final String id;
  final String agencyId;
  final ConversationType type;
  final String title;
  final String? description;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String lastMessage;
  final String lastSenderName;
  final DateTime lastMessageTime;
  final int unreadCount;

  const ChatConversation({
    required this.id,
    required this.agencyId,
    required this.type,
    required this.title,
    this.description,
    required this.participantIds,
    required this.participantNames,
    required this.participantPhotos,
    required this.lastMessage,
    required this.lastSenderName,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  /// Helper to get the display title for a DM from current user's perspective
  String getDisplayName(String currentUserId) {
    if (type == ConversationType.channel) return title;
    for (final entry in participantNames.entries) {
      if (entry.key != currentUserId) return entry.value;
    }
    return title;
  }

  /// Helper to get the recipient photo URL for a DM
  String? getDisplayPhoto(String currentUserId) {
    if (type == ConversationType.channel) return null;
    for (final entry in participantPhotos.entries) {
      if (entry.key != currentUserId) return entry.value;
    }
    return null;
  }

  /// Helper to get the other participant's ID in a DM
  String? getOtherParticipantId(String currentUserId) {
    if (type == ConversationType.channel) return null;
    return participantIds.firstWhere((id) => id != currentUserId, orElse: () => '');
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agencyId': agencyId,
      'type': type.name,
      'title': title,
      if (description != null) 'description': description,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastSenderName': lastSenderName,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
    };
  }

  factory ChatConversation.fromMap(String id, Map<String, dynamic> map) {
    DateTime time;
    if (map['lastMessageTime'] is Timestamp) {
      time = (map['lastMessageTime'] as Timestamp).toDate();
    } else if (map['lastMessageTime'] is String) {
      time = DateTime.tryParse(map['lastMessageTime'] as String) ?? DateTime.now();
    } else {
      time = DateTime.now();
    }

    return ChatConversation(
      id: id,
      agencyId: map['agencyId'] as String? ?? '',
      type: map['type'] == 'direct' ? ConversationType.direct : ConversationType.channel,
      title: map['title'] as String? ?? 'Conversation',
      description: map['description'] as String?,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantPhotos: Map<String, String?>.from(map['participantPhotos'] ?? {}),
      lastMessage: map['lastMessage'] as String? ?? '',
      lastSenderName: map['lastSenderName'] as String? ?? '',
      lastMessageTime: time,
      unreadCount: (map['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  ChatConversation copyWith({
    String? lastMessage,
    String? lastSenderName,
    DateTime? lastMessageTime,
    int? unreadCount,
  }) {
    return ChatConversation(
      id: id,
      agencyId: agencyId,
      type: type,
      title: title,
      description: description,
      participantIds: participantIds,
      participantNames: participantNames,
      participantPhotos: participantPhotos,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderName: lastSenderName ?? this.lastSenderName,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String agencyId;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String senderRole; // 'manager' | 'editor'
  final String text;
  final String? attachmentUrl;
  final String? attachmentType; // 'drive', 'frame_io', 'vimeo', 'link'
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.agencyId,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.senderRole,
    required this.text,
    this.attachmentUrl,
    this.attachmentType,
    required this.createdAt,
  });

  bool isMe(String currentUserId) => senderId == currentUserId;

  bool get hasAssetLink {
    if (attachmentUrl != null && attachmentUrl!.isNotEmpty) return true;
    final lower = text.toLowerCase();
    return lower.contains('drive.google.com') ||
        lower.contains('frame.io') ||
        lower.contains('dropbox.com') ||
        lower.contains('vimeo.com') ||
        lower.contains('youtube.com') ||
        lower.contains('youtu.be') ||
        lower.contains('wetransfer.com');
  }

  String? get detectedAssetUrl {
    if (attachmentUrl != null && attachmentUrl!.isNotEmpty) return attachmentUrl;
    final exp = RegExp(r'(https?:\/\/[^\s]+)');
    final match = exp.firstMatch(text);
    return match?.group(0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'agencyId': agencyId,
      'senderId': senderId,
      'senderName': senderName,
      if (senderPhotoUrl != null) 'senderPhotoUrl': senderPhotoUrl,
      'senderRole': senderRole,
      'text': text,
      if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
      if (attachmentType != null) 'attachmentType': attachmentType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChatMessage.fromMap(String id, Map<String, dynamic> map) {
    DateTime time;
    if (map['createdAt'] is Timestamp) {
      time = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      time = DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now();
    } else {
      time = DateTime.now();
    }

    return ChatMessage(
      id: id,
      conversationId: map['conversationId'] as String? ?? '',
      agencyId: map['agencyId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? 'User',
      senderPhotoUrl: map['senderPhotoUrl'] as String?,
      senderRole: map['senderRole'] as String? ?? 'editor',
      text: map['text'] as String? ?? '',
      attachmentUrl: map['attachmentUrl'] as String?,
      attachmentType: map['attachmentType'] as String?,
      createdAt: time,
    );
  }
}
