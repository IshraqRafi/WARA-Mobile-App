import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/editor/presentation/widgets/revision_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectItem p({String? notes, String? note, List<int> checks = const [], ProjectStatus s = ProjectStatus.claimed}) => ProjectItem(
    id: 'p', title: 'T', clientName: 'C', editorPayout: 1, deadlineStr: '', deadlineHoursLeft: 10, description: '',
    requiredSkills: const [], status: s, revisionNotes: notes, submissionNote: note, revisionChecks: checks);

void main() {
  test('splits lines and strips markers', () {
    expect(parseChecklist('- Trim intro\n* Louder VO\n• Fix color\n1. New logo\n2) End card\n\n  plain'),
        ['Trim intro', 'Louder VO', 'Fix color', 'New logo', 'End card', 'plain']);
  });
  test('items from revisionNotes, legacy prefix, only while claimed', () {
    expect(revisionItems(p(notes: 'a\nb')), ['a', 'b']);
    expect(revisionItems(p(note: 'Revision Request: x\ny')), ['x', 'y']);
    expect(revisionItems(p(note: 'just a note')), isEmpty);
    expect(revisionItems(p(notes: 'a', s: ProjectStatus.submitted)), isEmpty);
    expect(openRevisionItems(p(notes: 'a\nb\nc', checks: [0, 2, 9])), 1);
  });
  testWidgets('shows progress and toggles', (t) async {
    final taps = <int>[];
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark, home: Scaffold(body: RevisionChecklist(
        items: const ['a', 'b', 'c', 'd', 'e'], checked: const [0, 1, 3], onToggle: taps.add))));
    expect(find.text('3/5 done'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('revision_item_4')));
    expect(taps, [4]);
  });
}
