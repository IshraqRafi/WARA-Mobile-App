import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/shared/motion/theme_reveal.dart';

Widget _app(ValueNotifier<bool> dark, {bool reduce = false}) => ValueListenableBuilder<bool>(
      valueListenable: dark,
      builder: (_, d, _) => MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: d ? ThemeMode.dark : ThemeMode.light,
        themeAnimationDuration: Duration.zero,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
          child: ThemeReveal(child: child!),
        ),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => TextButton(
              onPressed: () => ThemeReveal.run(ctx, const Offset(40, 40), () => dark.value = !dark.value),
              child: const Text('toggle'),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('reveal overlays a snapshot with a growing hole, then clears', (tester) async {
    final dark = ValueNotifier(false);
    await tester.pumpWidget(_app(dark));
    await tester.tap(find.text('toggle'));
    await tester.pump();
    expect(dark.value, isTrue);
    expect(find.byType(RawImage), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(RawImage), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('reduced motion: theme flips with no overlay', (tester) async {
    final dark = ValueNotifier(false);
    await tester.pumpWidget(_app(dark, reduce: true));
    await tester.tap(find.text('toggle'));
    await tester.pump();
    expect(dark.value, isTrue);
    expect(find.byType(RawImage), findsNothing);
  });
}
