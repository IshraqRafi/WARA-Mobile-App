import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/manager/presentation/screens/manager_finance_screen.dart';

void main() {
  testWidgets('finance metric labels stay on one line at 320px', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FinanceMetricStrip(metrics: const [
            FinanceMetric('Revenue', '৳1,250,000'),
            FinanceMetric('Paid', '৳480,000'),
            FinanceMetric('Committed', '৳9,999,999'),
            FinanceMetric('Margin', '62%'),
          ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    double? h;
    for (final label in ['Revenue', 'Paid', 'Committed', 'Margin']) {
      final t = tester.widget<Text>(find.text(label));
      expect(t.maxLines, 1);
      final para = tester.renderObject<RenderParagraph>(find.text(label));
      expect(para.didExceedMaxLines, isFalse);
      final lineH = para.getFullHeightForCaret(const TextPosition(offset: 0));
      expect(para.size.height, lessThanOrEqualTo(lineH + 0.5));
      final tileH = tester.getSize(find.byKey(ValueKey('metric-$label'))).height;
      h ??= tileH;
      expect(tileH, h);
    }
  });
}
