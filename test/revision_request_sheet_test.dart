import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/editor/presentation/widgets/revision_checklist.dart';
import 'package:demo_app/features/manager/presentation/widgets/revision_request_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('send disabled until text; lines become checklist items', (t) async {
    String? sent;
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(body: RevisionRequestSheet(projectTitle: 'Reel', onSend: (s) => sent = s)),
    ));
    expect(find.text('What needs changing?'), findsOneWidget);
    final send = find.byKey(const ValueKey('revision_send'));
    expect(t.widget<ElevatedButton>(send).onPressed, isNull);
    await t.enterText(find.byKey(const ValueKey('revision_input')), '   ');
    await t.pump();
    expect(t.widget<ElevatedButton>(send).onPressed, isNull);
    await t.enterText(find.byKey(const ValueKey('revision_input')), '- Fix audio\n\n• Trim intro\n');
    await t.pump();
    await t.tap(send);
    expect(sent, '- Fix audio\n\n• Trim intro');
    expect(parseChecklist(sent), ['Fix audio', 'Trim intro']);
  });
}
