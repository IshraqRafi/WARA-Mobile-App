import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/editor/presentation/widgets/submit_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectItem p({int v = 0}) => ProjectItem(id: 'p', title: 'T', clientName: 'C', editorPayout: 1, deadlineStr: '',
    deadlineHoursLeft: 10, description: '', requiredSkills: const [], status: ProjectStatus.claimed, submissionVersion: v);

void main() {
  test('linkKind validates and recognizes hosts', () {
    expect(linkKind('https://drive.google.com/file/d/x'), LinkKind.drive);
    expect(linkKind('https://docs.google.com/x'), LinkKind.drive);
    expect(linkKind('https://app.frame.io/r/x'), LinkKind.frameio);
    expect(linkKind('https://f.io/abc'), LinkKind.frameio);
    expect(linkKind('https://www.dropbox.com/s/x'), LinkKind.dropbox);
    expect(linkKind('https://youtu.be/x'), LinkKind.youtube);
    expect(linkKind('https://www.youtube.com/watch?v=x'), LinkKind.youtube);
    expect(linkKind('https://vimeo.com/1'), LinkKind.other);
    expect(linkKind('notyoutube.com.evil'), isNull);
    expect(linkKind('ftp://x.com'), isNull);
    expect(linkKind('https://localhost'), isNull);
    expect(linkKind('https://evilyoutube.com/x'), LinkKind.other);
  });

  Future<List<String>> run(WidgetTester t, {int v = 0, int open = 0, required String link}) async {
    final got = <String>[];
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark, home: Scaffold(body: Builder(builder: (ctx) => TextButton(
        onPressed: () => showSubmitSheet(ctx, p(v: v), openChecks: open, onSubmit: (l, n) => got.add('$l|$n')),
        child: const Text('go'))))));
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('submit_link')), link);
    await t.pump();
    return got;
  }

  testWidgets('blocks invalid link, shows kind and next version', (t) async {
    final got = await run(t, v: 1, link: 'drive');
    expect(find.text('v2'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('submit_go')));
    await t.pumpAndSettle();
    expect(got, isEmpty);
    expect(find.textContaining('full link'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('submit_link')), 'https://drive.google.com/x');
    await t.pumpAndSettle();
    expect(find.text('Google Drive'), findsOneWidget);
    await t.enterText(find.byKey(const ValueKey('submit_note')), 'cut 2');
    await t.tap(find.byKey(const ValueKey('submit_go')));
    await t.pumpAndSettle();
    expect(got, ['https://drive.google.com/x|cut 2']);
  });

  testWidgets('unticked revision items prompt once', (t) async {
    final got = await run(t, open: 2, link: 'https://f.io/x');
    await t.tap(find.byKey(const ValueKey('submit_go')));
    await t.pumpAndSettle();
    expect(got, isEmpty);
    expect(find.textContaining('2 revision items are unticked'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('submit_go')));
    await t.pumpAndSettle();
    expect(got, hasLength(1));
  });
}
