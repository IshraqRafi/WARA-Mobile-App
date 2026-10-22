import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/shared/motion/celebration.dart';

Widget _app(void Function(BuildContext) fire, {bool reduce = false}) => MaterialApp(
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduce), child: child!),
      home: Scaffold(body: Builder(builder: (ctx) => TextButton(onPressed: () => fire(ctx), child: const Text('go')))),
    );

int _bursts(WidgetTester t) =>
    find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_BurstPainter').evaluate().length;

void main() {
  for (final confetti in [false, true]) {
    testWidgets('${confetti ? 'confetti' : 'sparkle'} paints then removes itself', (tester) async {
      await tester.pumpWidget(_app((c) => confetti ? Celebration.confetti(c) : Celebration.sparkle(c)));
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(_bursts(tester), 1);
      await tester.pumpAndSettle();
      expect(_bursts(tester), 0);
      expect(tester.binding.transientCallbackCount, 0);
    });
  }

  testWidgets('reduced motion: no particles', (tester) async {
    await tester.pumpWidget(_app((c) => Celebration.confetti(c), reduce: true));
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(_bursts(tester), 0);
  });
}
