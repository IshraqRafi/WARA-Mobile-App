import 'dart:math';

import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/payments/domain/payout.dart';
import 'package:demo_app/features/payments/presentation/bkash_pay_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wallet validation, masking, TrxID format', () {
    expect(isValidWallet('01712345678'), isTrue);
    expect(isValidWallet('01212345678'), isFalse);
    expect(isValidWallet('0171234567'), isFalse);
    expect(isValidWallet('+8801712345678'), isFalse);
    expect(maskWallet('01712345678'), '017*****678');
    for (var i = 0; i < 50; i++) {
      expect(generateTrxId(Random(i)), matches(RegExp(r'^BK[A-Z0-9]{10}$')));
    }
  });

  testWidgets('details -> otp -> pin -> processing -> success returns receipt', (t) async {
    BkashReceipt? got;
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () async => got = await Navigator.of(ctx).push<BkashReceipt>(MaterialPageRoute(
            builder: (_) => const BkashPayScreen(payee: 'Ed', amount: 1200, reference: 'Promo', processing: Duration(milliseconds: 10)),
          )),
          child: const Text('go'),
        ),
      ),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.text('bKash'), findsOneWidget);
    expect(find.text('৳1,200'), findsOneWidget);

    await t.enterText(find.byKey(const ValueKey('bkash_wallet')), '0121');
    await t.tap(find.byKey(const ValueKey('bkash_next')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('bkash_error')), findsOneWidget);

    await t.enterText(find.byKey(const ValueKey('bkash_wallet')), '01712345678');
    await t.tap(find.byKey(const ValueKey('bkash_next')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('bkash_test_hint')), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('bkash_otp')), '123456');
    await t.tap(find.byKey(const ValueKey('bkash_next')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('bkash_pin')), '1234');
    await t.tap(find.byKey(const ValueKey('bkash_next')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('bkash_error')), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('bkash_pin')), '12345');
    await t.tap(find.byKey(const ValueKey('bkash_next')));
    await t.pump();
    expect(find.text('Processing…'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 20));
    await t.pumpAndSettle();
    final trx = t.widget<SelectableText>(find.byKey(const ValueKey('bkash_trx'))).data!;
    expect(trx, matches(RegExp(r'^BK[A-Z0-9]{10}$')));
    await t.tap(find.byKey(const ValueKey('bkash_next')));
    await t.pumpAndSettle();
    expect(got?.trxId, trx);
    expect(got?.wallet, '01712345678');
  });

  testWidgets('pay chooser offers Mark paid and Pay with bKash', (t) async {
    PayMethod? m;
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Builder(builder: (ctx) => TextButton(onPressed: () async => m = await choosePayMethod(ctx, title: 'Mark paid?', detail: 'x'), child: const Text('go'))),
    ));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('confirm_paid')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('confirm_bkash')));
    await t.pumpAndSettle();
    expect(m, PayMethod.bkash);
  });
}
