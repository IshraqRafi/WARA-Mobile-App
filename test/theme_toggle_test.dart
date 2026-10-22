import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/core/theme/theme_provider.dart';
import 'package:demo_app/shared/widgets/wara_theme_toggle.dart';

Widget _app({bool reduce = false}) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduce), child: child!),
        home: const Scaffold(body: Center(child: WaraThemeToggle())),
      ),
    );

double _thumbX(WidgetTester t) => t.getCenter(find.descendant(of: find.byKey(const ValueKey('theme_thumb')), matching: find.byType(Container)).first).dx;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'wara_theme_mode': 'dark'}));

  testWidgets('tap flips theme; thumb slides left and icon swaps in ~250ms', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(WaraThemeToggle)));
    expect(container.read(themeNotifierProvider), ThemeMode.dark);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    final start = _thumbX(tester);

    await tester.tap(find.byKey(const ValueKey('theme_toggle')));
    await tester.pump();
    expect(container.read(themeNotifierProvider), ThemeMode.light);
    await tester.pump(const Duration(milliseconds: 120));
    expect(_thumbX(tester), lessThan(start));
    await tester.pump(const Duration(milliseconds: 140));
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode_rounded), findsNothing);
  });

  testWidgets('reduced motion: no animation', (tester) async {
    await tester.pumpWidget(_app(reduce: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme_toggle')));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
  });
}
