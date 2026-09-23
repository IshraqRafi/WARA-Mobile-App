import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/domain/auth_provider.dart';
import '../../projects/domain/project_provider.dart';
import 'notification_models.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final FirestoreService _firestoreService;
  final UserSession? _user;
  StreamSubscription<List<AppNotification>>? _subscription;

  NotificationNotifier(this._firestoreService, this._user) : super(const NotificationState()) {
    _init();
  }

  void _init() {
    final agencyId = _user?.agencyId;
    if (agencyId == null || agencyId.isEmpty) return;

    _subscription = _firestoreService
        .streamNotifications(agencyId: agencyId, userId: _user?.id)
        .listen(
      (notifs) {
        state = state.copyWith(notifications: notifs);
      },
      onError: (_) {},
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> markAsRead(String notificationId) async {
    final agencyId = _user?.agencyId;
    if (agencyId == null) return;
    await _firestoreService.markNotificationAsRead(agencyId, notificationId);
  }

  Future<void> markAllAsRead() async {
    final agencyId = _user?.agencyId;
    if (agencyId == null) return;
    await _firestoreService.markAllNotificationsAsRead(agencyId, _user?.id);
  }

  Future<void> sendNotification({
    required String title,
    required String body,
    required NotificationType type,
    String? targetUserId,
    String? relatedId,
  }) async {
    final agencyId = _user?.agencyId;
    if (agencyId == null) return;

    final notif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      agencyId: agencyId,
      userId: targetUserId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      createdAt: DateTime.now(),
    );

    await _firestoreService.sendNotification(agencyId: agencyId, notification: notif);
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final user = ref.watch(authProvider).user;
  return NotificationNotifier(firestore, user);
});
