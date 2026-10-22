import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/editor/presentation/widgets/offer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grouped taka', () {
    expect(groupedTaka(1200000), '৳1,200,000');
    expect(groupedTaka(950), '৳950');
  });
  testWidgets('shows payout, due and one-line brief; long-press claims', (t) async {
    var claimed = 0;
    final p = ProjectItem(id: 'p', title: 'Reel', clientName: 'C', editorPayout: 12000, legacyClientBudget: 99999,
        deadlineStr: '', deadlineHoursLeft: 30, description: 'Cut a 30s reel\nsecond line', requiredSkills: const [],
        status: ProjectStatus.open);
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark, home: Scaffold(body: OfferCard(project: p, onLongPress: () => claimed++))));
    expect(find.text('৳12,000'), findsOneWidget);
    expect(find.text('30h'), findsOneWidget);
    expect(find.text('Cut a 30s reel'), findsOneWidget);
    expect(find.textContaining('99'), findsNothing); // never the client figure
    await t.longPress(find.byKey(const ValueKey('offer_p')));
    expect(claimed, 1);
  });
}
