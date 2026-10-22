import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/manager/presentation/widgets/finance_margin_hero.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectItem _p(String id, double payout, DateTime at, {ProjectStatus s = ProjectStatus.approved}) => ProjectItem(
    id: id, title: id, clientName: 'c', editorPayout: payout, deadlineStr: '', deadlineHoursLeft: 10,
    description: '', requiredSkills: const [], status: s, claimedAt: at);

final oct = DateTime(2026, 10), sep = DateTime(2026, 9);
final projects = [
  _p('a', 400, DateTime(2026, 10, 3)),
  _p('b', 300, DateTime(2026, 10, 20)),
  _p('c', 500, DateTime(2026, 9, 12)),
  _p('d', 100, DateTime(2026, 10, 5), s: ProjectStatus.claimed), // not approved
  _p('e', 100, DateTime(2026, 10, 6)), // no price
];
const finance = {
  'a': ProjectFinance(clientPrice: 1000),
  'b': ProjectFinance(clientPrice: 900),
  'c': ProjectFinance(clientPrice: 1500),
  'd': ProjectFinance(clientPrice: 999),
};

Widget _wrap(Widget w, {bool reduce = false}) => MaterialApp(
      theme: AppTheme.dark,
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduce), child: child!),
      home: Scaffold(body: w),
    );

String _value(WidgetTester t) => t.widget<Text>(find.byKey(const ValueKey('margin_value'))).data!;

void main() {
  test('monthly margin: approved + priced only, bucketed by claimedAt', () {
    final m = MonthlyMargin.of(projects, finance, oct);
    expect(m.total, 1200); // (1000-400) + (900-300)
    expect(m.cumulative.length, 31);
    expect(m.cumulative[2], 600);
    expect(m.cumulative.last, 1200);
    final p = MonthlyMargin.of(projects, finance, sep);
    expect(p.total, 1000);
    expect(m.changeVs(p), closeTo(20, 1e-9));
    expect(MonthlyMargin.of(projects, finance, DateTime(2026, 8)).total, isNull);
  });

  testWidgets('hero counts up over ~700ms and shows change vs last month', (tester) async {
    await tester.pumpWidget(_wrap(FinanceMarginHero(
        month: oct, current: MonthlyMargin.of(projects, finance, oct), previous: MonthlyMargin.of(projects, finance, sep))));
    expect(_value(tester), '৳0');
    await tester.pump(const Duration(milliseconds: 300));
    expect(_value(tester), isNot(anyOf('৳0', '৳1,200')));
    await tester.pumpAndSettle();
    expect(_value(tester), '৳1,200');
    expect(find.text('20%'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('empty month shows — and a flat line, no change chip', (tester) async {
    final empty = MonthlyMargin.of(const [], const {}, oct);
    await tester.pumpWidget(_wrap(FinanceMarginHero(month: oct, current: empty, previous: empty)));
    expect(_value(tester), '—');
    expect(find.byKey(const ValueKey('margin_change')), findsNothing);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('reduced motion: final figure immediately', (tester) async {
    await tester.pumpWidget(_wrap(
        FinanceMarginHero(
            month: oct, current: MonthlyMargin.of(projects, finance, oct), previous: MonthlyMargin.of(projects, finance, sep)),
        reduce: true));
    await tester.pump();
    expect(_value(tester), '৳1,200');
  });

  testWidgets('month switcher steps back, never past now', (tester) async {
    var m = oct;
    await tester.pumpWidget(_wrap(StatefulBuilder(
        builder: (_, set) => FinanceMonthSwitcher(month: m, now: DateTime(2026, 10, 23), onChanged: (v) => set(() => m = v)))));
    expect(find.text('Oct 2026'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byKey(const ValueKey('month_next'))).onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('month_prev')));
    await tester.pumpAndSettle();
    expect(m, sep);
    expect(find.text('Sep 2026'), findsOneWidget);
  });
}
