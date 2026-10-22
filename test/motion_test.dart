import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/shared/motion/motion.dart';
import 'package:demo_app/shared/widgets/wara_project_card.dart';

Widget _wrap(Widget child, {bool reduce = false}) => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: Scaffold(body: child),
        ),
      ),
    );

ProjectItem _p(String id) => ProjectItem(
      id: id,
      title: 'Reel cut $id',
      clientName: 'Client',
      
      editorPayout: 5000,
      deadlineStr: 'Fri',
      deadlineHoursLeft: 48,
      description: 'Brief text $id',
      requiredSkills: const ['Premiere'],
    );

void main() {
  setUp(StaggerIn.reset);

  testWidgets('card expands and collapses; one open per list', (tester) async {
    await tester.pumpWidget(_wrap(ListView(children: [
      WaraProjectCard(project: _p('a'), listId: 'l'),
      WaraProjectCard(project: _p('b'), listId: 'l'),
    ])));
    await tester.pumpAndSettle();
    expect(find.text('Brief text a'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('card_toggle_a')));
    await tester.pumpAndSettle();
    expect(find.text('Brief text a'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('card_toggle_b')));
    await tester.pumpAndSettle();
    expect(find.text('Brief text a'), findsNothing);
    expect(find.text('Brief text b'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('card_toggle_b')));
    await tester.pumpAndSettle();
    expect(find.text('Brief text b'), findsNothing);
  });

  testWidgets('Pressable scales down while pressed and keeps child taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(Center(
      child: Pressable(child: ElevatedButton(onPressed: () => taps++, child: const Text('Go'))),
    )));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Go')));
    await tester.pumpAndSettle();
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale;
    expect(scale, lessThan(1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale, 1);
  });

  testWidgets('reduced motion: Pressable does not scale', (tester) async {
    await tester.pumpWidget(_wrap(
      Center(child: Pressable(child: ElevatedButton(onPressed: () {}, child: const Text('Go')))),
      reduce: true,
    ));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Go')));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale, 1);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion: stagger and shimmer are static', (tester) async {
    await tester.pumpWidget(_wrap(
      const Column(children: [
        StaggerIn(screen: 's2', index: 3, child: Text('row')),
        Shimmer(child: SizedBox(width: 10, height: 10)),
      ]),
      reduce: true,
    ));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('row'), findsOneWidget);
  });
}
