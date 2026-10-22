import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/shared/motion/collapsing_header.dart';

Widget _app({bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce, size: const Size(400, 800)),
        child: Scaffold(
          body: CustomScrollView(slivers: [
            CollapsingHeader(
              leading: (s) => SizedBox(key: const ValueKey('logo'), width: s, height: s),
              title: 'wara.io',
              background: Colors.black,
              divider: Colors.grey,
            ),
            SliverList.list(children: [for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('row $i'))]),
          ]),
        ),
      ),
    );

void main() {
  testWidgets('header collapses and logo shrinks on scroll', (tester) async {
    await tester.pumpWidget(_app());
    expect(tester.getSize(find.byKey(const ValueKey('logo'))).width, 42);
    await tester.drag(find.text('row 2'), const Offset(0, -300));
    await tester.pump();
    expect(tester.getSize(find.byKey(const ValueKey('logo'))).width, 32);
    expect(find.text('wara.io'), findsOneWidget); // pinned
  });

  testWidgets('reduced motion: compact and static from the start', (tester) async {
    await tester.pumpWidget(_app(reduce: true));
    expect(tester.getSize(find.byKey(const ValueKey('logo'))).width, 32);
  });
}
