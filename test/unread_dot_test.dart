import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/chat/domain/chat_models.dart';
import 'package:demo_app/shared/widgets/wara_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget bar(bool dot) => MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        bottomNavigationBar: WaraBottomBar(selectedIndex: 0, onItemSelected: (_) {}, items: [
          const WaraNavItem(icon: Icons.home, label: 'Home'),
          WaraNavItem(icon: Icons.chat, label: 'Messages', hasBadge: dot),
        ]),
      ),
    );

void main() {
  testWidgets('Messages tab shows a plain dot only when a chat is unread', (t) async {
    await t.pumpWidget(bar(false));
    expect(find.byKey(const Key('tab_dot_Messages')), findsNothing);
    await t.pumpWidget(bar(true));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('tab_dot_Messages')), findsOneWidget);
  });

  test('unread = incoming last message not in readBy', () {
    ChatConversation c(String? from, List<String> readBy) => ChatConversation(
        id: 'dm_a_b', agencyId: 'A', type: ConversationType.direct, title: '', participantIds: const ['a', 'b'],
        participantNames: const {}, participantPhotos: const {}, lastSenderName: 'A', lastMessageTime: DateTime(2026),
        lastMessage: 'hi', lastSenderId: from, readBy: readBy);
    expect(c('a', ['a']).isUnreadFor('b'), isTrue);
    expect(c('a', ['a', 'b']).isUnreadFor('b'), isFalse);
    expect(c('b', ['b']).isUnreadFor('b'), isFalse);
  });
}
