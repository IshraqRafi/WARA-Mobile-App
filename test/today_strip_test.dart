import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/editor/presentation/widgets/today_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectItem p(String id, {DateTime? at, ProjectStatus s = ProjectStatus.claimed, int h = 48}) => ProjectItem(
    id: id, title: 'T$id', clientName: 'C', editorPayout: 1, deadlineStr: '', deadlineHoursLeft: h, description: '',
    requiredSkills: const [], status: s, deadlineAt: at);

void main() {
  final now = DateTime(2026, 10, 23, 12);
  test('countdown formats', () {
    expect(countdown(const Duration(days: 2, hours: 4)), '2d 4h');
    expect(countdown(const Duration(hours: 5, minutes: 12)), '5h 12m');
    expect(countdown(const Duration(minutes: 12, seconds: 30)), '12m 30s');
    expect(countdown(const Duration(hours: -3)), 'Overdue 3h');
  });
  test('picks nearest claimed deadline; legacy falls back to hours', () {
    final list = [
      p('a', at: now.add(const Duration(hours: 30))),
      p('b', at: now.add(const Duration(hours: 2)), s: ProjectStatus.submitted),
      p('c', h: 10),
    ];
    expect(nextDeadline(list, now)!.id, 'c');
    expect(nextDeadline([p('x', s: ProjectStatus.approved)], now), isNull);
  });
  testWidgets('tone: amber under 24h, error overdue; tap fires', (t) async {
    var tapped = false;
    Future<Color?> tone(DateTime at) async {
      await t.pumpWidget(MaterialApp(theme: AppTheme.dark, home: Scaffold(body: TodayStrip(
          key: UniqueKey(), project: p('a', at: at), onTap: () => tapped = true, clock: () => now))));
      await t.pumpAndSettle();
      return t.widget<DefaultTextStyle>(find.ancestor(of: find.byKey(const ValueKey('today_countdown')), matching: find.byType(DefaultTextStyle)).first).style.color;
    }
    AppColors ctx() => t.element(find.byType(TodayStrip)).colors;
    expect(await tone(now.add(const Duration(hours: 5))), ctx().warning);
    expect(await tone(now.subtract(const Duration(hours: 1))), ctx().error);
    expect(await tone(now.add(const Duration(hours: 40))), ctx().text);
    await t.tap(find.byKey(const ValueKey('today_strip')));
    expect(tapped, isTrue);
    await t.pumpWidget(const SizedBox());
  });
}
