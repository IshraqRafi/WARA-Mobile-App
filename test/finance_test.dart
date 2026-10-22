import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/features/manager/presentation/screens/manager_finance_screen.dart';
import 'package:demo_app/features/projects/domain/project_provider.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectItem _p(String id, ProjectStatus s, double payout, {double? legacy}) => ProjectItem(
      id: id, title: id, clientName: 'c', legacyClientBudget: legacy, editorPayout: payout,
      deadlineStr: '', deadlineHoursLeft: 10, description: '', requiredSkills: const [], status: s);

void main() {
  test('margin is null without a price and warns when negative', () {
    expect(projectMargin(null, 100), isNull);
    expect(projectMargin(1000, 400)!.percent, 60);
    expect(projectMargin(300, 400)!.amount, -100);
  });

  test('private finance wins over legacy, missing price is unknown', () {
    final a = _p('a', ProjectStatus.approved, 400, legacy: 900);
    final b = _p('b', ProjectStatus.claimed, 200);
    final f = {'a': const ProjectFinance(clientPrice: 1000)};
    expect(clientPriceOf(a, f), 1000);
    expect(clientPriceOf(a, const {}), 900);
    expect(clientPriceOf(b, f), isNull);
    final s = FinanceSummary.of([a, b], f);
    expect(s.revenue, 1000);
    expect(s.committed, 600);
    expect(s.marginPercent, 60);
    expect(FinanceSummary.of([b], const {}).revenue, isNull);
  });
}
