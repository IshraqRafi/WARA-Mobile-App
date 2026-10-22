import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/manager/presentation/widgets/editor_ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectItem p(String id, String ed, double pay, int hrs, ProjectStatus s, {bool overdue = false}) => ProjectItem(
      id: id, title: 'Project $id', clientName: 'C', editorPayout: pay, deadlineStr: '', deadlineHoursLeft: hrs,
      description: '', requiredSkills: const [], status: s, claimedByEditorId: ed, claimedByEditorName: 'Ed $ed',
      isOverdue: overdue);

void main() {
  final items = [
    p('1', 'a', 1000, 400, ProjectStatus.submitted),
    p('2', 'b', 500, 30, ProjectStatus.claimed),
    p('3', 'b', 700, -5, ProjectStatus.submitted, overdue: true),
    p('4', 'c', 900, 10, ProjectStatus.approved),
  ];

  test('groups owed work by editor, sorted by urgency', () {
    final l = EditorLedger.of(items);
    expect(l.editors.map((e) => e.id), ['b', 'a']);
    expect(l.total, 2200);
    expect(l.byUrgency[Urgency.overdue], 700);
    expect(l.byUrgency[Urgency.thisWeek], 500);
    expect(l.byUrgency[Urgency.later], 1000);
    expect(l.editors.first.projects.first.id, '3');
    expect(l.editors.first.payable.map((x) => x.id), ['3']);
  });

  testWidgets('expands and marks paid only after confirming', (t) async {
    final paid = <String>[];
    final e = EditorLedger.of(items).editors.first;
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: EditorOwedCard(editor: e, onPay: (ps) => paid.addAll(ps.map((x) => x.id)))),
    ));
    expect(find.byKey(const ValueKey('row_3')), findsNothing);
    await t.tap(find.byKey(const ValueKey('editor_b')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('row_3')), findsOneWidget);
    expect(find.byKey(const ValueKey('pay_2')), findsNothing); // claimed: in progress
    await t.tap(find.byKey(const ValueKey('pay_3')));
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(paid, isEmpty);
    await t.tap(find.byKey(const ValueKey('pay_3')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('confirm_paid')));
    await t.pumpAndSettle();
    expect(paid, ['3']);
  });

  testWidgets('urgency bar renders only non-empty segments', (t) async {
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark,
        home: Scaffold(body: UrgencyBar(byUrgency: const {Urgency.overdue: 0, Urgency.thisWeek: 300, Urgency.later: 100}))));
    expect(find.byKey(const ValueKey('urgency_overdue')), findsNothing);
    expect(find.byKey(const ValueKey('urgency_thisWeek')), findsOneWidget);
    expect(find.text('Overdue ৳0'), findsOneWidget);
  });
}
