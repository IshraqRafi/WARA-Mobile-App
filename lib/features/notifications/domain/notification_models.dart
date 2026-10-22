import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-user inbox item at users/{uid}/notifications/{id}.
enum NotificationType { revision, approved, message, assigned, submitted }

class AppNotification {
  final String id;
  final NotificationType type;
  final String? projectId;
  final String? chatId;
  final String title;
  final String body;
  final String fromUid;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    this.projectId,
    this.chatId,
    required this.title,
    this.body = '',
    required this.fromUid,
    required this.createdAt,
    this.read = false,
  });

  /// Fields for a new doc; createdAt is the server time (required by rules).
  static Map<String, dynamic> draft({
    required NotificationType type,
    required String title,
    String body = '',
    required String fromUid,
    String? projectId,
    String? chatId,
  }) =>
      {
        'type': type.name,
        if (projectId != null && projectId.isNotEmpty) 'projectId': projectId,
        if (chatId != null && chatId.isNotEmpty) 'chatId': chatId,
        'title': title.length > 120 ? title.substring(0, 120) : title,
        'body': body.length > 500 ? body.substring(0, 500) : body,
        'fromUid': fromUid,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      };

  factory AppNotification.fromMap(String id, Map<String, dynamic> m) {
    final raw = m['createdAt'];
    return AppNotification(
      id: id,
      type: NotificationType.values.firstWhere((e) => e.name == m['type'], orElse: () => NotificationType.message),
      projectId: m['projectId'] as String?,
      chatId: m['chatId'] as String?,
      title: m['title'] as String? ?? '',
      body: m['body'] as String? ?? '',
      fromUid: m['fromUid'] as String? ?? '',
      // Pending server timestamps read as null locally.
      createdAt: raw is Timestamp ? raw.toDate() : DateTime.now(),
      read: m['read'] as bool? ?? false,
    );
  }

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        projectId: projectId,
        chatId: chatId,
        title: title,
        body: body,
        fromUid: fromUid,
        createdAt: createdAt,
        read: read ?? this.read,
      );
}
