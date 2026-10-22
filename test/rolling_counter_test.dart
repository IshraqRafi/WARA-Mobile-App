import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/shared/motion/rolling_counter.dart';

Widget _wrap(Widget child, {bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  test('format groups thousands', () {
    expect(RollingCounter.format(1234567, grouped: true), '1,234,567');
    expect(RollingCounter.format(999, grouped: true), '999');
    expect(RollingCounter.format(1234567), '1234567');
  });

  testWidgets('reduced motion renders plain text', (tester) async {
    await tester.pumpWidget(_wrap(const RollingCounter(value: 1200, prefix: '৳', grouped: true), reduce: true));
    expect(find.text('৳1,200'), findsOneWidget);
  });

  testWidgets('changed digits roll, then settle on the new value', (tester) async {
    await tester.pumpWidget(_wrap(const RollingCounter(value: 19)));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);

    await tester.pumpWidget(_wrap(const RollingCounter(value: 20)));
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-roll both the old and new digits are on screen.
    expect(find.text('9'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('9'), findsNothing);
    expect(find.text('1'), findsNothing);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.bySemanticsLabel('20'), findsOneWidget);
  });
}
