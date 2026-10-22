import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/auth/presentation/screens/login_screen.dart';
import 'package:demo_app/shared/widgets/wara_empty_state.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => ProviderScope(
      child: MaterialApp(theme: theme ?? AppTheme.dark, home: child),
    );

void main() {
  for (final entry in {'dark': AppTheme.dark, 'light': AppTheme.light}.entries) {
    testWidgets('login screen renders Google sign-in (${entry.key})', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen(), theme: entry.value));
      await tester.pump();
      expect(find.textContaining('Google'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('empty state shows title, message and fires its action', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_wrap(Scaffold(
      body: WaraEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nothing here yet',
        message: 'New projects appear here.',
        actionLabel: 'New project',
        onAction: () => tapped++,
      ),
    )));
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('New projects appear here.'), findsOneWidget);
    await tester.tap(find.text('New project'));
    expect(tapped, 1);
  });
}
