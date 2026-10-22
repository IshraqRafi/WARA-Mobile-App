import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/shared/motion/chat_motion.dart';

Widget _wrap(Widget child, {bool reduce = false}) =>
    MaterialApp(home: MediaQuery(data: MediaQueryData(disableAnimations: reduce), child: Scaffold(body: Center(child: child))));

Finder _opacity(String text) => find.ancestor(of: find.text(text), matching: find.byType(Opacity));

void main() {
  testWidgets('new message springs in and settles to a plain child', (tester) async {
    await tester.pumpWidget(_wrap(const MessageSpringIn(animate: true, fromRight: true, child: Text('hi'))));
    await tester.pump(const Duration(milliseconds: 30));
    expect(_opacity('hi'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(_opacity('hi'), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('history and reduced motion do not animate', (tester) async {
    await tester.pumpWidget(_wrap(const MessageSpringIn(animate: false, fromRight: false, child: Text('old'))));
    expect(_opacity('old'), findsNothing);
    await tester.pumpWidget(_wrap(const MessageSpringIn(animate: true, fromRight: false, child: Text('new')), reduce: true));
    expect(_opacity('new'), findsNothing);
  });

  testWidgets('typing dots animate, but are static under reduced motion', (tester) async {
    await tester.pumpWidget(_wrap(const TypingDots(color: Colors.grey)));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(_wrap(const TypingDots(color: Colors.grey), reduce: true));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
