import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/notifications/domain/notification_models.dart';
import 'package:demo_app/features/notifications/domain/notification_provider.dart';
import 'package:demo_app/features/notifications/presentation/widgets/notification_center_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification n(String id, {bool read = false, NotificationType type = NotificationType.revision}) => AppNotification(
    id: id, type: type, title: 'T$id', body: 'B$id', fromUid: 'm', projectId: 'p', createdAt: DateTime.now(), read: read);

Widget host(List<AppNotification> items, Widget child) => ProviderScope(
      key: UniqueKey(),
      overrides: [notificationsProvider.overrideWith((ref) => Stream.value(items))],
      child: MaterialApp(theme: AppTheme.dark, home: Scaffold(body: Center(child: child))),
    );

void main() {
  test('badge label caps at 9+', () {
    expect(unreadLabel(0), '');
    expect(unreadLabel(3), '3');
    expect(unreadLabel(9), '9');
    expect(unreadLabel(10), '9+');
  });

  test('relative time', () {
    final now = DateTime(2026, 1, 10, 12);
    expect(relativeTime(now, now), 'now');
    expect(relativeTime(now.subtract(const Duration(minutes: 5)), now), '5m');
    expect(relativeTime(now.subtract(const Duration(hours: 3)), now), '3h');
    expect(relativeTime(now.subtract(const Duration(days: 2)), now), '2d');
  });

  testWidgets('bell shows unread count only', (t) async {
    await t.pumpWidget(host([n('1'), n('2'), n('3', read: true)], const NotificationBellButton()));
    await t.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const ValueKey('notification_badge')), matching: find.text('2')), findsOneWidget);
  });

  testWidgets('bell hides badge with no unread; 9+ cap', (t) async {
    await t.pumpWidget(host([n('1', read: true)], const NotificationBellButton()));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification_badge')), findsNothing);
    await t.pumpWidget(host([for (var i = 0; i < 12; i++) n('$i')], const NotificationBellButton()));
    await t.pumpAndSettle();
    expect(find.text('9+'), findsOneWidget);
  });

  testWidgets('sheet lists items with Mark all read; empty state', (t) async {
    await t.pumpWidget(host([n('1'), n('2', read: true, type: NotificationType.message)], const NotificationSheet()));
    await t.pumpAndSettle();
    expect(find.text('T1'), findsOneWidget);
    expect(find.text('T2'), findsOneWidget);
    expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
    expect(find.byKey(const ValueKey('mark_all_read')), findsOneWidget);
    await t.pumpWidget(host(const [], const NotificationSheet()));
    await t.pumpAndSettle();
    expect(find.text("You're all caught up"), findsOneWidget);
  });
}
