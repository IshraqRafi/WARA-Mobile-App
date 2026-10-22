import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/editor/presentation/widgets/profile_scorecard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectItem p(String id, ProjectStatus s, {bool late = false, String ed = 'me'}) => ProjectItem(
    id: id, title: id, clientName: 'C', editorPayout: 1, deadlineStr: '', deadlineHoursLeft: 1, description: '',
    requiredSkills: const [], status: s, claimedByEditorId: ed, submittedLate: late);

void main() {
  test('on-time rate over approved work', () {
    final s = EditorScore.of([
      p('a', ProjectStatus.approved), p('b', ProjectStatus.approved, late: true),
      p('c', ProjectStatus.approved), p('d', ProjectStatus.approved),
      p('e', ProjectStatus.submitted, late: true), p('f', ProjectStatus.approved, ed: 'x'),
    ], 'me');
    expect(s.onTime, 0.75);
    expect(s.done, 4);
    expect(EditorScore.of(const [], 'me').onTime, isNull);
  });
  testWidgets('renders three figures, dashes when empty', (t) async {
    Future<void> pump(EditorScore s, double r, int n) => t.pumpWidget(MaterialApp(theme: AppTheme.dark,
        home: Scaffold(body: ProfileScorecard(score: s, rating: r, ratingCount: n))));
    await pump(const EditorScore(0.75, 4), 4.62, 3);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    await pump(const EditorScore(null, 0), 0, 0);
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('0'), findsOneWidget);
  });
}
