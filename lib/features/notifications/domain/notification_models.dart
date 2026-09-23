import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  projectNew,
  projectClaimed,
  submissionReceived,
  projectApproved,
  revisionRequested,
  ratingReceived,
  chatMessage,
}

class AppNotification {
  final String id;
  final String agencyId;
  final String? userId; // Specific user or null for agency-wide broadcast
  final String? senderId; // The user who triggered the event, so they don't notify themselves
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.agencyId,
    this.userId,
    this.senderId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'agencyId': agencyId,
      if (userId != null) 'userId': userId,
      if (senderId != null) 'senderId': senderId,
      'title': title,
      'body': body,
      'type': type.name,
      if (relatedId != null) 'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedDate = DateTime.now();
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      parsedDate = rawCreated.toDate();
    } else if (rawCreated is String) {
      parsedDate = DateTime.tryParse(rawCreated) ?? DateTime.now();
    }

    final rawType = map['type'] as String? ?? 'projectNew';
    final nType = NotificationType.values.firstWhere(
      (e) => e.name == rawType,
      orElse: () => NotificationType.projectNew,
    );

    return AppNotification(
      id: id,
      agencyId: map['agencyId'] as String? ?? '',
      userId: map['userId'] as String?,
      senderId: map['senderId'] as String?,
      title: map['title'] as String? ?? 'Notification',
      body: map['body'] as String? ?? '',
      type: nType,
      relatedId: map['relatedId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: parsedDate,
    );
  }

  AppNotification copyWith({
    String? id,
    String? agencyId,
    String? userId,
    String? senderId,
    String? title,
    String? body,
    NotificationType? type,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
