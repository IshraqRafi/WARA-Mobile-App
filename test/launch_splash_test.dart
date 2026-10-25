import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/auth/domain/auth_provider.dart';
import 'package:demo_app/shared/motion/launch_splash.dart';

final _ready = StateProvider<bool>((_) => false);

Future<ProviderContainer> _pump(WidgetTester t, {bool reduce = false}) async {
  final c = ProviderContainer(overrides: [authRestoredProvider.overrideWith((ref) => ref.watch(_ready))]);
  addTearDown(c.dispose);
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(
      theme: AppTheme.light,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(disableAnimations: reduce),
        child: LaunchSplash(child: child!),
      ),
      home: const Scaffold(body: Text('home')),
    ),
  ));
  return c;
}

Future<void> _advance(WidgetTester t, int ms) async {
  for (var i = 0; i < ms ~/ 20; i++) {
    await t.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  setUp(LaunchSplash.reset);
  final splash = find.byKey(const Key('launch_splash'));

  testWidgets('fast auth: stays at least 1.2s, then fades out; white in light theme', (t) async {
    final c = await _pump(t);
    expect(splash, findsOneWidget);
    expect(find.text('home'), findsOneWidget); // app builds underneath
    final bg = t.widget<ColoredBox>(find.descendant(of: splash, matching: find.byType(ColoredBox)).first);
    expect(bg.color, Colors.white);
    c.read(_ready.notifier).state = true;
    await _advance(t, 1000);
    expect(splash, findsOneWidget);
    await _advance(t, 800);
    await t.pumpAndSettle();
    expect(splash, findsNothing);
  });

  testWidgets('slow auth: waits for it, capped at 3s', (t) async {
    await _pump(t);
    await _advance(t, 2500);
    expect(splash, findsOneWidget);
    await _advance(t, 1100);
    await t.pumpAndSettle();
    expect(splash, findsNothing);
  });

  testWidgets('plays once per process; reduce-motion has no logo scale', (t) async {
    final c = await _pump(t, reduce: true);
    final tr = t.widget<Transform>(find.descendant(of: splash, matching: find.byType(Transform)).first);
    expect(tr.transform.getMaxScaleOnAxis(), 1.0);
    c.read(_ready.notifier).state = true;
    await _advance(t, 1400);
    await t.pumpAndSettle();
    expect(splash, findsNothing);
    await t.pumpWidget(const SizedBox());
    await _pump(t);
    expect(splash, findsNothing);
  });
}
