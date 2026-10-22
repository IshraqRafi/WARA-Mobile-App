import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/editor/domain/editor_earnings.dart';
import 'package:demo_app/features/editor/presentation/widgets/earnings_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectItem p(String id, double pay, ProjectStatus s, {String ed = 'me', DateTime? approved, DateTime? claimed}) => ProjectItem(
    id: id, title: id, clientName: 'C', editorPayout: pay, deadlineStr: '', deadlineHoursLeft: 48, description: '',
    requiredSkills: const [], status: s, claimedByEditorId: ed, approvedAt: approved, claimedAt: claimed);

void main() {
  final now = DateTime(2026, 10, 20);
  final items = [
    p('a', 1000, ProjectStatus.approved, approved: DateTime(2026, 10, 3)),
    p('b', 400, ProjectStatus.approved, approved: DateTime(2026, 9, 3)),
    p('c', 700, ProjectStatus.approved, approved: DateTime(2025, 1, 1)), // outside window
    p('d', 300, ProjectStatus.submitted, claimed: DateTime(2026, 10, 1)),
    p('e', 200, ProjectStatus.claimed),
    p('f', 999, ProjectStatus.approved, ed: 'other', approved: DateTime(2026, 10, 3)),
  ];

  test('this month, pending and six-month series from own payouts', () {
    final e = EditorEarnings.of(items, 'me', now: now);
    expect(e.thisMonth, 1000);
    expect(e.pending, 500);
    expect(e.earnedSeries, [0, 0, 0, 0, 400, 1000]);
    expect(e.pendingSeries.last, 500);
  });

  testWidgets('header shows both figures and sparklines', (t) async {
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark, home: Scaffold(body: EarningsHeader(earnings: EditorEarnings.of(items, 'me', now: now)))));
    await t.pumpAndSettle();
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.byKey(const ValueKey('earned_spark')), findsOneWidget);
    expect(find.byKey(const ValueKey('pending_spark')), findsOneWidget);
  });
}
