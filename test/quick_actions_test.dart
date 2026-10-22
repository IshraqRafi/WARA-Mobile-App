import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/shared/widgets/quick_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('palette filters and runs the picked action after closing', (t) async {
    var ran = '';
    final actions = [
      QuickAction(id: 'chat', label: 'Open chat', icon: Icons.chat, run: () => ran = 'chat'),
      QuickAction(id: 'mark_read', label: 'Mark all read', icon: Icons.done_all, run: () => ran = 'read'),
      QuickAction(id: 'p_1', label: 'Wedding reel', hint: 'claimed', icon: Icons.arrow_outward, run: () => ran = 'p1'),
    ];
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Builder(builder: (c) => Scaffold(body: TextButton(onPressed: () => showQuickActions(c, actions), child: const Text('go')))),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('quick_actions')), findsOneWidget);
    await t.enterText(find.byKey(const Key('quick_actions_search')), 'wed');
    await t.pump();
    expect(find.byKey(const Key('qa_chat')), findsNothing);
    await t.tap(find.byKey(const Key('qa_p_1')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('quick_actions')), findsNothing);
    expect(ran, 'p1');
  });

  test('filter matches hint too, empty query keeps all', () {
    final a = [QuickAction(id: 'x', label: 'Alpha', hint: 'submitted', icon: Icons.add, run: () {})];
    expect(filterQuickActions(a, ''), hasLength(1));
    expect(filterQuickActions(a, 'SUBM'), hasLength(1));
    expect(filterQuickActions(a, 'zzz'), isEmpty);
  });
}
