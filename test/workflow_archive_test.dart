import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/services/firestore_service.dart';
import 'package:demo_app/features/manager/presentation/screens/manager_workflow_screen.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectItem _p(String id, ProjectStatus s, {bool archived = false}) => ProjectItem(
      id: id, agencyId: 'A', title: id, clientName: 'c', editorPayout: 1,
      deadlineStr: '', deadlineHoursLeft: 10, description: '', requiredSkills: const [],
      status: s, archived: archived,
    );

void main() {
  final all = [
    _p('open', ProjectStatus.open),
    _p('done1', ProjectStatus.approved),
    _p('done2', ProjectStatus.approved, archived: true),
    _p('rev', ProjectStatus.submitted),
  ];

  test('default Workflow hides finished and archived projects', () {
    expect(workflowVisible(all, null).map((p) => p.id), ['open', 'rev']);
  });

  test('Done filter lists approved, never archived', () {
    expect(workflowVisible(all, 4).map((p) => p.id), ['done1']);
  });

  test('archived round-trips through the map', () {
    final m = _p('x', ProjectStatus.approved, archived: true).toMap();
    expect(m['archived'], true);
    expect(ProjectItem.fromMap('x', m).archived, true);
    expect(_p('y', ProjectStatus.open).toMap().containsKey('archived'), false);
  });

  test('a refused price write no longer takes the project down with it', () async {
    var projectWritten = false;
    final ok = await createProjectWrites(
      writeProject: () async => projectWritten = true,
      writeFinance: () async => throw Exception('permission-denied'),
    );
    expect(projectWritten, true);
    expect(ok, false);
  });

  test('a refused project write surfaces as an error', () async {
    expect(
      createProjectWrites(writeProject: () async => throw Exception('permission-denied')),
      throwsException,
    );
  });
}
