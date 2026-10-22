import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/features/manager/presentation/screens/review_queue_screen.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectItem p(String id, ProjectStatus s, String at) => ProjectItem(
      id: id, title: 'P$id', clientName: 'C', editorPayout: 100, deadlineStr: '', deadlineHoursLeft: 10,
      description: '', requiredSkills: const [], status: s, submittedAt: at);

void main() {
  test('queue holds only submitted work, oldest submit first', () {
    final q = reviewQueue([
      p('1', ProjectStatus.submitted, '2026-10-22T10:00:00'),
      p('2', ProjectStatus.claimed, '2026-10-20T10:00:00'),
      p('3', ProjectStatus.submitted, '2026-10-21T10:00:00'),
      p('4', ProjectStatus.approved, '2026-10-19T10:00:00'),
    ]);
    expect(q.map((x) => x.id), ['3', '1']);
  });
}
