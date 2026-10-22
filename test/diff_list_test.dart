import 'package:demo_app/shared/motion/diff_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(List<String> items, {bool reduced = false, Set<String> skip = const {}}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(
          body: DiffList<String>(
            items: items,
            idOf: (s) => s,
            skipExit: skip.contains,
            itemBuilder: (_, s, _) => SizedBox(height: 50, child: Text(s)),
          ),
        ),
      ),
    );

double h(WidgetTester t, String id) => t.getSize(find.byKey(ValueKey('diff_$id'))).height;

void main() {
  testWidgets('new items grow in, removed items collapse then leave', (t) async {
    await t.pumpWidget(app(['a', 'b']));
    expect(h(t, 'a'), 50);
    await t.pumpWidget(app(['c', 'a', 'b']));
    await t.pump(const Duration(milliseconds: 50));
    expect(h(t, 'c'), lessThan(50));
    await t.pumpAndSettle();
    expect(h(t, 'c'), 50);

    await t.pumpWidget(app(['c', 'b']));
    await t.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const ValueKey('diff_a_out')), findsOneWidget);
    expect(h(t, 'a_out'), lessThan(50));
    await t.pumpAndSettle();
    expect(find.text('a'), findsNothing);
  });

  testWidgets('skipExit ids leave at once', (t) async {
    await t.pumpWidget(app(['a', 'b']));
    await t.pumpWidget(app(['b'], skip: {'a'}));
    expect(find.text('a'), findsNothing);
  });

  testWidgets('reduce-motion: no animation', (t) async {
    await t.pumpWidget(app(['a'], reduced: true));
    await t.pumpWidget(app(['n', 'a'], reduced: true));
    await t.pump();
    expect(h(t, 'n'), 50);
    await t.pumpWidget(app(['n'], reduced: true));
    await t.pump();
    await t.pump();
    expect(find.text('a'), findsNothing);
  });
}
