import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/payments/presentation/payout_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses amount and TrxID from a payment body', () {
    expect(amountFromBody('৳1,200 · TrxID BKA1B2C3D4E5'), 1200);
    expect(trxFromBody('৳1,200 · TrxID BKA1B2C3D4E5'), 'BKA1B2C3D4E5');
    expect(amountFromBody('Project X'), isNull);
  });

  testWidgets('amount counts up to the payout', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Builder(builder: (ctx) => TextButton(onPressed: () => showPayoutReveal(ctx, amount: 2500, detail: 'TrxID BK1'), child: const Text('go'))),
    ));
    await t.tap(find.text('go'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    final mid = t.widget<Text>(find.byKey(const ValueKey('payout_reveal_amount'))).data;
    expect(mid, isNot('৳2,500'));
    await t.pumpAndSettle();
    expect(find.text('৳2,500'), findsOneWidget);
    await t.tap(find.text('Nice'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('payout_reveal')), findsNothing);
  });

  testWidgets('reduce-motion shows the final amount at once', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(builder: (ctx) => TextButton(onPressed: () => showPayoutReveal(ctx, amount: 900), child: const Text('go'))),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pump();
    await t.pump();
    expect(find.text('৳900'), findsOneWidget);
    await t.pumpAndSettle();
  });
}
