import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/auth/presentation/screens/login_screen.dart';
import 'package:demo_app/shared/widgets/wara_empty_state.dart';
import 'package:demo_app/shared/widgets/wara_stat_strip.dart';
import 'package:demo_app/shared/widgets/wara_status_chip.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => ProviderScope(
      child: MaterialApp(theme: theme ?? AppTheme.dark, home: child),
    );

void main() {
  for (final entry in {'dark': AppTheme.dark, 'light': AppTheme.light}.entries) {
    testWidgets('login screen renders role slider and Google sign-in (${entry.key})', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), theme: entry.value));
      await tester.pump();
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Editor'), findsOneWidget);
      expect(find.text('Manager'), findsOneWidget);
      expect(find.text('wara.io'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('role slider reports the tapped role', (tester) async {
    var role = UserRole.editor;
    await tester.pumpWidget(_wrap(Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => RoleSlider(value: role, onChanged: (r) => setState(() => role = r)),
      ),
    )));
    await tester.tap(find.text('Manager'));
    await tester.pumpAndSettle();
    expect(role, UserRole.manager);
    await tester.tap(find.text('Editor'));
    await tester.pumpAndSettle();
    expect(role, UserRole.editor);
  });

  testWidgets('stat strip selects a segment and clears on second tap', (tester) async {
    int? selected;
    await tester.pumpWidget(_wrap(Scaffold(
      body: SizedBox(
        width: 320,
        child: StatefulBuilder(
          builder: (context, setState) => WaraStatStrip(
            stats: const [
              WaraStat(label: 'Open', value: 3, tone: WaraTone.info),
              WaraStat(label: 'Active', value: 12, tone: WaraTone.warning),
              WaraStat(label: 'Review', value: 0, tone: WaraTone.success),
              WaraStat(label: 'Overdue', value: 1, tone: WaraTone.error),
            ],
            selected: selected,
            onSelect: (i) => setState(() => selected = i),
          ),
        ),
      ),
    )));
    expect(tester.takeException(), isNull);
    expect(find.descendant(of: find.byType(WaraStatStrip), matching: find.byType(InkWell)), findsNothing);
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    final pillA = tester.getRect(find.byKey(const ValueKey('stat_pill')));
    await tester.tap(find.text('Overdue'));
    await tester.pumpAndSettle();
    expect(selected, 3);
    expect(tester.getRect(find.byKey(const ValueKey('stat_pill'))).left, greaterThan(pillA.left));
    // Content is centred in its cell; selection does not tint the text.
    final cell = tester.getRect(find.byKey(const ValueKey('stat_Overdue')));
    final content = tester.getRect(find.ancestor(of: find.text('Overdue'), matching: find.byType(Column)).first);
    expect((content.center.dy - cell.center.dy).abs(), lessThan(1.0));
    expect((content.center.dx - cell.center.dx).abs(), lessThan(1.0));
    final pillBox = tester.widget<DecoratedBox>(find.byKey(const ValueKey('stat_pill'))).decoration as BoxDecoration;
    expect(pillBox.borderRadius, BorderRadius.circular(8));
    await tester.tap(find.text('Overdue'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Active'));
    await tester.pump();
    expect(selected, isNull);
  });

  testWidgets('empty state shows a short title and fires its action', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_wrap(Scaffold(
      body: WaraEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No projects',
        actionLabel: 'New project',
        onAction: () => tapped++,
      ),
    )));
    expect(find.text('No projects'), findsOneWidget);
    await tester.tap(find.text('New project'));
    expect(tapped, 1);
  });
}
