import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/shared/motion/wara_refresh.dart';

void main() {
  Future<void> run(WidgetTester tester, {required bool reduce}) async {
    final done = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          body: WaraRefresh(
            onRefresh: () {
              calls++;
              return done.future;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [for (var i = 0; i < 30; i++) SizedBox(height: 50, child: Text('row $i'))],
            ),
          ),
        ),
      ),
    ));
    await tester.fling(find.text('row 0'), const Offset(0, 400), 1000);
    await tester.pump();
    expect(calls, 1);
    await tester.pump(const Duration(milliseconds: 100));
    done.complete();
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  }

  testWidgets('pull past threshold refreshes until the future completes', (t) => run(t, reduce: false));
  testWidgets('reduced motion: refresh still works', (t) => run(t, reduce: true));
}
