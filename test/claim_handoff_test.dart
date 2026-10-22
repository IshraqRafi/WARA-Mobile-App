import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/shared/motion/claim_handoff.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> run(WidgetTester t, {required bool reduced, required VoidCallback onArrive}) async {
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      builder: (ctx, child) => MediaQuery(data: MediaQuery.of(ctx).copyWith(disableAnimations: reduced), child: child!),
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () => ClaimHandoff.fly(ctx, from: const Rect.fromLTWH(16, 200, 360, 72), label: 'Promo', onArrive: onArrive),
          child: const Text('go'),
        ),
      ),
    ));
    await t.tap(find.text('go'));
  }

  testWidgets('ghost flies to the tab, then arrives', (t) async {
    var arrived = 0;
    await run(t, reduced: false, onArrive: () => arrived++);
    await t.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('claim_ghost')), findsOneWidget);
    expect(arrived, 0);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('claim_ghost')), findsNothing);
    expect(arrived, 1);
  });

  testWidgets('reduce-motion skips the flight', (t) async {
    var arrived = 0;
    await run(t, reduced: true, onArrive: () => arrived++);
    await t.pump();
    expect(find.byKey(const ValueKey('claim_ghost')), findsNothing);
    expect(arrived, 1);
  });
}
