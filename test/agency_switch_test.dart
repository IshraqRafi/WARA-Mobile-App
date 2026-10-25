import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/shared/motion/agency_switch.dart';

final _id = StateProvider<(String?, String?, UserRole?)>((_) => ('u1', null, UserRole.editor));

void main() {
  late Completer<void> load;
  late List<String> routes;
  late List<String> errors;
  late int taps;

  Future<ProviderContainer> pump(WidgetTester t, {bool reduce = false, bool fail = false}) async {
    load = Completer<void>();
    routes = [];
    errors = [];
    taps = 0;
    final container = ProviderContainer(overrides: [agencyIdentityProvider.overrideWith((ref) => ref.watch(_id))]);
    addTearDown(container.dispose);
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: reduce),
          child: AgencySwitchHost(
            reload: (_) => fail ? Future.error(Exception('denied')) : load.future,
            navigate: (_, r) => routes.add(r),
            onError: errors.add,
            child: child!,
          ),
        ),
        home: Scaffold(body: Center(child: ElevatedButton(onPressed: () => taps++, child: const Text('tap')))),
      ),
    ));
    return container;
  }

  Future<void> advance(WidgetTester t, int ms) async {
    for (var i = 0; i < ms ~/ 20; i++) {
      await t.pump(const Duration(milliseconds: 20));
    }
  }

  Finder overlay() => find.byKey(const Key('agency_switch_overlay'));
  double bar(WidgetTester t) => t.widget<FractionallySizedBox>(find.byKey(const Key('agency_switch_bar'))).widthFactor!;

  testWidgets('agency change: overlay, blocks input, waits for 2.5s and data, routes home, fades out', (t) async {
    final c = await pump(t);
    expect(overlay(), findsNothing);
    c.read(_id.notifier).state = ('u1', 'A', UserRole.editor);
    await t.pump();
    await advance(t, 300);
    expect(overlay(), findsOneWidget);
    await t.tap(find.text('tap'), warnIfMissed: false);
    expect(taps, 0);

    load.complete();
    await advance(t, 1200);
    expect(bar(t), inExclusiveRange(0.0, 0.9));
    expect(routes, isEmpty); // data ready, but 2.5s not reached
    await advance(t, 1400);
    await advance(t, 300);
    expect(routes, ['/editor/available']);
    await t.pumpAndSettle();
    expect(overlay(), findsNothing);
    expect(errors, isEmpty);
    await t.tap(find.text('tap'));
    expect(taps, 1);
  });

  testWidgets('slow data: bar holds until data arrives', (t) async {
    final c = await pump(t);
    c.read(_id.notifier).state = ('u1', 'B', UserRole.manager);
    await t.pump();
    await advance(t, 3500);
    expect(routes, isEmpty);
    expect(bar(t), closeTo(0.9, 0.001));
    load.complete();
    await t.pumpAndSettle();
    expect(routes, ['/manager/workflow']);
    expect(overlay(), findsNothing);
  });

  testWidgets('failure shows error toast; sign-in (uid change) does not trigger', (t) async {
    final c = await pump(t, fail: true, reduce: true);
    c.read(_id.notifier).state = ('u2', 'A', UserRole.editor); // new user: sign-in
    await t.pump();
    expect(overlay(), findsNothing);
    c.read(_id.notifier).state = ('u2', 'C', UserRole.editor);
    await t.pump();
    await advance(t, 120);
    final logoScale = t.widget<Transform>(find.descendant(of: overlay(), matching: find.byType(Transform)).first);
    expect(logoScale.transform.getMaxScaleOnAxis(), 1.0); // no scale under reduce-motion
    await t.pumpAndSettle();
    expect(errors, ["Couldn't load agency data"]);
    expect(overlay(), findsNothing);
  });
}
