import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/shared/motion/container_transform.dart';

Widget _app({bool reduce = false}) => MaterialApp(
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduce), child: child!),
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => ContainerTransformRoute.open<void>(ctx,
                  color: Colors.blue, builder: (_) => const Scaffold(body: Text('create'))),
              child: const Text('New project'),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('morphs from the button rect to full screen', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text('New project'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final mid = tester.getRect(find.byType(ClipRRect).last);
    expect(mid.width, lessThan(800));
    expect(mid.width, greaterThan(100));
    await tester.pumpAndSettle();
    expect(find.text('create'), findsOneWidget);
    expect(find.byType(ClipRRect), findsNothing);
  });

  testWidgets('reduced motion opens instantly', (tester) async {
    await tester.pumpWidget(_app(reduce: true));
    await tester.tap(find.text('New project'));
    await tester.pump();
    await tester.pump();
    expect(find.text('create'), findsOneWidget);
    expect(find.byType(ClipRRect), findsNothing);
  });
}
