import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, VoidCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/auth_provider.dart';
import '../../projects/domain/project_provider.dart';
import 'notification_models.dart';

/// Signed-in uid for the inbox (overridable in tests).
final notificationUidProvider = Provider<String?>((ref) => ref.watch(authProvider.select((s) => s.user?.id)));

/// Inbox writes, behind a seam so widget tests need no Firebase.
class NotificationStore {
  final Future<void> Function(String uid, List<String> ids) markRead;
  final Future<void> Function(String uid, List<String> ids) delete;
  final Future<int> Function(String uid, DateTime before) purgeReadBefore;
  const NotificationStore({required this.markRead, required this.delete, required this.purgeReadBefore});
}

final notificationStoreProvider = Provider<NotificationStore>((ref) {
  final s = ref.watch(firestoreServiceProvider);
  return NotificationStore(
    markRead: s.markNotificationsRead,
    delete: s.deleteNotifications,
    purgeReadBefore: s.purgeReadNotificationsBefore,
  );
});

/// My inbox (newest first, max 50). Empty when signed out.
final notificationsProvider = StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final uid = ref.watch(authProvider.select((s) => s.user?.id));
  if (uid == null || uid.isEmpty) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).streamMyNotifications(uid);
});

/// Local overlay so taps and swipes show instantly, before the server echo.
final _localReadProvider = StateProvider<Set<String>>((ref) => const {});
final _hiddenProvider = StateProvider<Set<String>>((ref) => const {});

/// What the center and the bell show.
final visibleNotificationsProvider = Provider.autoDispose<List<AppNotification>>((ref) {
  final items = ref.watch(notificationsProvider).valueOrNull ?? const <AppNotification>[];
  final read = ref.watch(_localReadProvider);
  final hidden = ref.watch(_hiddenProvider);
  return [
    for (final n in items)
      if (!hidden.contains(n.id)) (read.contains(n.id) && !n.read) ? n.asRead() : n,
  ];
});

final unreadNotificationsProvider = Provider.autoDispose<int>(
  (ref) => ref.watch(visibleNotificationsProvider).where((n) => !n.read).length,
);

/// Badge text: '' at zero, '9+' above nine.
String unreadLabel(int n) => n <= 0 ? '' : (n > 9 ? '9+' : '$n');

/// Read notices older than this are removed on open.
const notificationRetention = Duration(days: 30);

/// Undo window before a dismiss is written.
const notificationUndoWindow = Duration(seconds: 4);

class NotificationActions {
  final Ref _ref;
  NotificationActions(this._ref);
  String? get _uid => _ref.read(notificationUidProvider);
  NotificationStore get _store => _ref.read(notificationStoreProvider);
  DateTime? _lastPurge;

  void markRead(String id) => _markRead([id]);

  void markAllRead() {
    final unread = _ref.read(visibleNotificationsProvider).where((n) => !n.read).map((n) => n.id).toList();
    _markRead(unread);
  }

  void _markRead(List<String> ids) {
    final uid = _uid;
    if (uid == null || ids.isEmpty) return;
    final s = _ref.read(_localReadProvider.notifier);
    s.state = {...s.state, ...ids};
    _store.markRead(uid, ids);
  }

  /// Hides [ids] now and deletes them after the undo window.
  /// Returns the undo callback (no-op once committed).
  VoidCallback dismiss(List<String> ids) {
    final uid = _uid;
    if (uid == null || ids.isEmpty) return () {};
    final h = _ref.read(_hiddenProvider.notifier);
    h.state = {...h.state, ...ids};
    var undone = false;
    final timer = Timer(notificationUndoWindow, () {
      if (!undone) _store.delete(uid, ids);
    });
    return () {
      if (!timer.isActive) return;
      undone = true;
      timer.cancel();
      h.state = h.state.difference(ids.toSet());
    };
  }

  VoidCallback clearRead() =>
      dismiss(_ref.read(visibleNotificationsProvider).where((n) => n.read).map((n) => n.id).toList());

  /// Client-side retention: at most once per session.
  Future<void> purgeOld({DateTime? now}) async {
    final uid = _uid;
    if (uid == null || _lastPurge != null) return;
    _lastPurge = now ?? DateTime.now();
    try {
      await _store.purgeReadBefore(uid, _lastPurge!.subtract(notificationRetention));
    } catch (e) {
      debugPrint('notification purge failed: $e');
    }
  }
}

final notificationActionsProvider = Provider((ref) => NotificationActions(ref));
