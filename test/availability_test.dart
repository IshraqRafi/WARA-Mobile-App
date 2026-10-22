import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/editor/presentation/widgets/availability_toggle.dart';
import 'package:demo_app/shared/widgets/availability_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget w) => MaterialApp(theme: AppTheme.dark, home: Scaffold(body: w));

void main() {
  test('parse', () {
    expect(parseAvailability('available'), Availability.available);
    expect(parseAvailability('busy'), Availability.busy);
    expect(parseAvailability(null), isNull);
    expect(parseAvailability('away'), isNull);
  });
  testWidgets('badge labels; hidden when unset', (t) async {
    await t.pumpWidget(wrap(const AvailabilityBadge('busy')));
    expect(find.text('Busy'), findsOneWidget);
    await t.pumpWidget(wrap(const AvailabilityBadge('available')));
    expect(find.text('Available'), findsOneWidget);
    await t.pumpWidget(wrap(const AvailabilityBadge(null)));
    expect(find.byType(Text), findsNothing);
  });
  testWidgets('toggle reports flips', (t) async {
    final got = <bool>[];
    await t.pumpWidget(wrap(AvailabilityToggle(available: true, onChanged: got.add)));
    expect(find.text('Available'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('availability_switch')));
    expect(got, [false]);
  });
}
