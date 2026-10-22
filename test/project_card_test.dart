import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/shared/widgets/wara_project_card.dart';

void main() {
  testWidgets('card has no left urgency bar; soon deadline is tinted', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: WaraProjectCard(
            project: ProjectItem(
              id: 'x', title: 'Urgent cut', clientName: 'C', clientBudget: 1,
              editorPayout: 1, deadlineStr: 'Today', deadlineHoursLeft: 3,
              description: 'd', requiredSkills: const [],
            ),
            listId: 't',
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final leftBars = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).where((d) {
      final dec = d.decoration;
      return dec is BoxDecoration && dec.border is Border && (dec.border as Border).left.width >= 3;
    });
    expect(leftBars, isEmpty);
    final colors = tester.element(find.text('Urgent cut')).colors;
    final tinted = tester.widgetList<Text>(find.byType(Text))
        .where((t) => (t.data ?? '').contains('Today') && t.style?.color == colors.warning);
    expect(tinted, isNotEmpty);
  });
}
