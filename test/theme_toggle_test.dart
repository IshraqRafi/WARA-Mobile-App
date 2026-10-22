import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:demo_app/core/theme/theme_provider.dart';
import 'package:demo_app/shared/widgets/wara_theme_toggle.dart';

Widget _app({bool reduce = false}) => ProviderScope(
      child: MaterialApp(
        builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduce), child: child!),
        home: const Scaffold(body: Center(child: WaraThemeToggle())),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'wara_theme_mode': 'dark'}));

  testWidgets('tap flips the theme and animates for ~400ms, then settles', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(WaraThemeToggle)));
    expect(container.read(themeNotifierProvider), ThemeMode.dark);
    await tester.tap(find.byKey(const ValueKey('theme_toggle')));
    await tester.pump();
    expect(container.read(themeNotifierProvider), ThemeMode.light);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('reduced motion: no animation', (tester) async {
    await tester.pumpWidget(_app(reduce: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme_toggle')));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
  });
}
