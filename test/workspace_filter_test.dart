import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/features/projects/domain/project_provider.dart';

ProjectItem _p(String id, {String? by, ProjectStatus status = ProjectStatus.claimed, double payout = 100}) => ProjectItem(
      id: id,
      title: id,
      clientName: 'c',
      
      editorPayout: payout,
      deadlineStr: '',
      deadlineHoursLeft: 48,
      description: '',
      requiredSkills: const [],
      status: status,
      claimedByEditorId: by,
    );

void main() {
  final all = [
    _p('open', status: ProjectStatus.open),
    _p('mine1', by: 'me'),
    _p('mine2', by: 'me', status: ProjectStatus.approved, payout: 500),
    _p('theirs', by: 'other'),
    _p('theirsDone', by: 'other', status: ProjectStatus.approved, payout: 900),
  ];

  test('workspace only contains the current editor\'s projects', () {
    final w = workspaceFor(all, 'me');
    expect(w.items.map((p) => p.id), ['mine1', 'mine2']);
    expect(w.earned, 500);
  });

  test('no uid owns nothing', () {
    expect(workspaceFor(all, null).items, isEmpty);
    expect(workspaceFor(all, '').items, isEmpty);
    expect(activeClaimCount(all, null), 0);
  });

  test('badge counts only own active claims', () {
    expect(activeClaimCount(all, 'me'), 1);
    expect(activeClaimCount(all, 'other'), 1);
  });
}
