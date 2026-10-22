import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_provider.dart';
import '../../projects/domain/project_provider.dart';
import 'notification_models.dart';

/// My inbox (newest first, max 50). Empty when signed out.
final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final uid = ref.watch(authProvider.select((s) => s.user?.id));
  if (uid == null || uid.isEmpty) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).streamMyNotifications(uid);
});

final unreadNotificationsProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(notificationsProvider).valueOrNull?.where((n) => !n.read).length ?? 0,
);

/// Badge text: '' at zero, '9+' above nine.
String unreadLabel(int n) => n <= 0 ? '' : (n > 9 ? '9+' : '$n');

class NotificationActions {
  final Ref _ref;
  NotificationActions(this._ref);
  String? get _uid => _ref.read(authProvider).user?.id;

  void markRead(String id) {
    final uid = _uid;
    if (uid != null) _ref.read(firestoreServiceProvider).markNotificationRead(uid, id);
  }

  void markAllRead() {
    final uid = _uid;
    final unread = _ref.read(notificationsProvider).valueOrNull?.where((n) => !n.read).map((n) => n.id) ?? const [];
    if (uid != null) _ref.read(firestoreServiceProvider).markNotificationsRead(uid, unread.toList());
  }
}

final notificationActionsProvider = Provider((ref) => NotificationActions(ref));
