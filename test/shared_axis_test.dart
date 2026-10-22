import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/shared/motion/shared_axis.dart';

Widget _wrap(int index, {bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          body: Column(children: [
            MorphIcon(selected: index == 1, icon: Icons.work_outline, selectedIcon: Icons.work, color: Colors.white),
            Expanded(child: SharedAxisTabs(index: index, child: Text('tab $index'))),
          ]),
        ),
      ),
    );

void main() {
  testWidgets('tab switch slides in from the travel side and settles', (tester) async {
    await tester.pumpWidget(_wrap(0));
    await tester.pumpWidget(_wrap(1));
    await tester.pump(const Duration(milliseconds: 60));
    final mid = tester.widget<Transform>(find.ancestor(of: find.text('tab 1'), matching: find.byType(Transform)).first);
    expect(mid.transform.getTranslation().x, greaterThan(0)); // from the right
    await tester.pumpAndSettle();
    expect(find.ancestor(of: find.text('tab 1'), matching: find.byType(Opacity)), findsNothing);
    expect(find.byIcon(Icons.work), findsOneWidget);
    expect(find.byIcon(Icons.work_outline), findsNothing);
  });

  testWidgets('reduced motion: no transition, icon swaps instantly', (tester) async {
    await tester.pumpWidget(_wrap(0, reduce: true));
    await tester.pumpWidget(_wrap(1, reduce: true));
    await tester.pump();
    expect(find.ancestor(of: find.text('tab 1'), matching: find.byType(Opacity)), findsNothing);
    expect(find.byIcon(Icons.work), findsOneWidget);
    expect(find.byIcon(Icons.work_outline), findsNothing);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
