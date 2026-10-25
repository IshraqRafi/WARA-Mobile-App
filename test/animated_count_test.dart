import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/shared/motion/motion.dart';

Widget _wrap(Widget w, {bool reduce = false}) => MaterialApp(
      theme: AppTheme.dark,
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduce), child: child!),
      home: Scaffold(body: Center(child: w)),
    );

String _text(WidgetTester t) => t.widget<Text>(find.byType(Text)).data!;

void main() {
  test('taka format groups and rounds', () {
    expect(takaFormat(1234567.4), '৳1,234,567');
    expect(takaFormat(0), '৳0');
  });

  testWidgets('tweens from 0 with currency formatting, then from previous value', (t) async {
    await t.pumpWidget(_wrap(const AnimatedCount(value: 12000, format: takaFormat)));
    expect(_text(t), '৳0');
    await t.pump(const Duration(milliseconds: 200));
    final mid = _text(t);
    expect(mid, matches(RegExp(r'^৳\d{1,3}(,\d{3})*$')));
    expect(mid, isNot('৳0'));
    expect(mid, isNot('৳12,000'));
    await t.pump(const Duration(milliseconds: 420));
    expect(_text(t), '৳12,000');

    await t.pumpWidget(_wrap(const AnimatedCount(value: 10000, format: takaFormat)));
    await t.pump(const Duration(milliseconds: 100));
    final v = int.parse(_text(t).replaceAll(RegExp(r'[৳,]'), ''));
    expect(v, inExclusiveRange(10000, 12000)); // from previous, not from 0
    await t.pumpAndSettle();
    expect(_text(t), '৳10,000');
  });

  testWidgets('reduce-motion jumps straight to the value', (t) async {
    await t.pumpWidget(_wrap(const AnimatedCount(value: 42), reduce: true));
    expect(_text(t), '42');
    await t.pumpWidget(_wrap(const AnimatedCount(value: 7), reduce: true));
    await t.pump();
    expect(_text(t), '7');
  });

  testWidgets('skeleton column: slim cards, shimmer only with motion', (t) async {
    await t.pumpWidget(_wrap(const CardSkeletonColumn(count: 3, height: 64)));
    expect(find.byType(CardSkeleton), findsNWidgets(3));
    expect(t.getSize(find.byType(CardSkeleton).first).height, 64 + AppSpacing.sm);
    expect(find.byType(ShaderMask), findsOneWidget);
    await t.pumpWidget(_wrap(const CardSkeletonColumn(), reduce: true));
    expect(find.byType(ShaderMask), findsNothing);
  });
}
