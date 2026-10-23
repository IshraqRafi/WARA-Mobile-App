import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/notifications/domain/notification_models.dart';
import 'package:demo_app/features/notifications/domain/notification_provider.dart';
import 'package:demo_app/features/notifications/presentation/widgets/notification_center_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification n(String id, {bool read = false, NotificationType type = NotificationType.revision}) => AppNotification(
    id: id, type: type, title: 'T$id', body: 'B$id', fromUid: 'm', projectId: 'p', createdAt: DateTime.now(), read: read);

final deleted = <String>[];
final marked = <String>[];
final purges = <DateTime>[];
final store = NotificationStore(
  markRead: (_, ids) async => marked.addAll(ids),
  delete: (_, ids) async => deleted.addAll(ids),
  purgeReadBefore: (_, before) async {
    purges.add(before);
    return 0;
  },
);

Widget host(List<AppNotification> items, Widget child) => ProviderScope(
      key: UniqueKey(),
      overrides: [
        notificationsProvider.overrideWith((ref) => Stream.value(items)),
        notificationUidProvider.overrideWithValue('u1'),
        notificationStoreProvider.overrideWithValue(store),
      ],
      child: MaterialApp(theme: AppTheme.dark, home: Scaffold(body: Center(child: child))),
    );

void main() {
  setUp(() {
    deleted.clear();
    marked.clear();
    purges.clear();
  });

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

  testWidgets('swipe removes a card; deletes after the undo window', (t) async {
    await t.pumpWidget(host([n('1'), n('2')], const NotificationSheet()));
    await t.pumpAndSettle();
    await t.drag(find.text('T1'), const Offset(-600, 0));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('T1'), findsNothing);
    expect(find.text('Notification removed'), findsOneWidget);
    expect(deleted, isEmpty);
    await t.pump(notificationUndoWindow);
    await t.pumpAndSettle();
    expect(deleted, ['1']);
  });

  testWidgets('undo restores the card and nothing is deleted', (t) async {
    await t.pumpWidget(host([n('1'), n('2')], const NotificationSheet()));
    await t.pumpAndSettle();
    await t.drag(find.text('T1'), const Offset(-600, 0));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 700)); // toast slide-in
    await t.tap(find.byKey(const ValueKey('toast_action')));
    await t.pump();
    expect(find.text('T1'), findsOneWidget);
    await t.pump(notificationUndoWindow);
    expect(deleted, isEmpty);
  });

  testWidgets('Clear read: hidden with none read; deletes only read', (t) async {
    await t.pumpWidget(host([n('1')], const NotificationSheet()));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('clear_read')), findsNothing);
    await t.pumpWidget(host([n('1'), n('2', read: true), n('3', read: true)], const NotificationSheet()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('clear_read')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('T2'), findsNothing);
    expect(find.text('T1'), findsOneWidget);
    expect(find.byKey(const ValueKey('clear_read')), findsNothing);
    await t.pump(notificationUndoWindow);
    await t.pumpAndSettle();
    expect(deleted, unorderedEquals(['2', '3']));
  });

  testWidgets('marking read dims the card, drops the badge, keeps it listed', (t) async {
    late WidgetRef r;
    await t.pumpWidget(host([n('1'), n('2')], Consumer(builder: (_, ref, _) {
      r = ref;
      return const Column(children: [NotificationBellButton(), Expanded(child: NotificationSheet())]);
    })));
    await t.pumpAndSettle();
    expect(find.descendant(of: find.byKey(const ValueKey('notification_badge')), matching: find.text('2')), findsOneWidget);
    r.read(notificationActionsProvider).markRead('1');
    await t.pumpAndSettle();
    expect(marked, ['1']);
    expect(find.text('T1'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('notification_badge')), matching: find.text('1')), findsOneWidget);
    final op = t.widget<AnimatedOpacity>(find.ancestor(of: find.text('T1'), matching: find.byType(AnimatedOpacity)).first);
    expect(op.opacity, lessThan(1));
  });

  testWidgets('opening the center purges read notices older than 30 days, once', (t) async {
    await t.pumpWidget(host([n('1')], const NotificationSheet()));
    await t.pumpAndSettle();
    expect(purges, hasLength(1));
    expect(DateTime.now().difference(purges.single).inDays, 30);
  });
}
