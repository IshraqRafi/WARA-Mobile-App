import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/shared/motion/swipe_feedback.dart';

Widget _row({bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          body: SwipeFeedback(
            builder: (context, progress, onUpdate) => Dismissible(
              key: const ValueKey('r'),
              onUpdate: onUpdate,
              confirmDismiss: (_) async => false,
              background: Align(alignment: Alignment.centerLeft, child: SwipeIcon(progress: progress, child: const Icon(Icons.check))),
              child: const SizedBox(height: 80, width: 800, child: Text('card')),
            ),
          ),
        ),
      ),
    );

double _scale(WidgetTester t) =>
    t.widget<Transform>(find.ancestor(of: find.byIcon(Icons.check), matching: find.byType(Transform)).first).transform.getMaxScaleOnAxis();

void main() {
  testWidgets('icon grows with drag and haptic fires once at threshold', (tester) async {
    final haptics = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
      return null;
    });
    await tester.pumpWidget(_row());
    final g = await tester.startGesture(tester.getCenter(find.text('card')));
    await g.moveBy(const Offset(80, 0));
    await tester.pump();
    final small = _scale(tester);
    await g.moveBy(const Offset(300, 0));
    await tester.pump();
    await g.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(_scale(tester), greaterThan(small));
    expect(haptics.length, 1);
    await g.up();
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion: icon does not scale', (tester) async {
    await tester.pumpWidget(_row(reduce: true));
    final g = await tester.startGesture(tester.getCenter(find.text('card')));
    await g.moveBy(const Offset(200, 0));
    await tester.pump();
    expect(find.ancestor(of: find.byIcon(Icons.check), matching: find.byType(Transform)), findsNothing);
    await g.up();
    await tester.pumpAndSettle();
  });
}
