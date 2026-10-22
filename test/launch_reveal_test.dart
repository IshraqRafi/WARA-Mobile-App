import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/shared/motion/launch_reveal.dart';

Widget _app({bool reduce = false}) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: LaunchReveal(child: child!),
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );

void main() {
  setUp(LaunchReveal.reset);

  testWidgets('plays once over the app, under 900ms, then removes itself', (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('home'), findsOneWidget); // app builds underneath
    expect(find.text('w'), findsOneWidget);
    expect(LaunchReveal.total, lessThan(const Duration(milliseconds: 900)));
    await tester.pump(LaunchReveal.total + const Duration(milliseconds: 20));
    await tester.pump();
    await tester.pump();
    expect(find.text('w'), findsNothing);

    // A rebuilt app in the same process does not replay it.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_app());
    expect(find.text('w'), findsNothing);
  });

  testWidgets('skipped with reduce-motion', (tester) async {
    await tester.pumpWidget(_app(reduce: true));
    expect(find.text('w'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
