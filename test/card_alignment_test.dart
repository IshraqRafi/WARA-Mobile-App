import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/shared/widgets/wara_project_card.dart';

const _font = '/usr/share/fonts/truetype/sand-box/google/Noto Sans/NotoSans-VariableFont_wdth,wght.ttf';

ProjectItem _p(String id, String title, ProjectStatus s, String? who, int pay) => ProjectItem(
      id: id, title: title, clientName: 'C', editorPayout: pay.toDouble(), deadlineStr: 'Oct 28',
      deadlineHoursLeft: 80, description: 'd', requiredSkills: const [], status: s, claimedByEditorName: who,
    );

const _icons = '/workspace/flutter-sdk/bin/cache/dart-sdk/bin/resources/devtools/assets/fonts/MaterialIcons-Regular.otf';

void main() {
  testWidgets('trailing price, dot and chevron align on every card', (t) async {
    if (File(_font).existsSync()) {
      final l = FontLoader('Roboto')..addFont(Future.value(ByteData.sublistView(File(_font).readAsBytesSync())));
      await l.load();
    }
    if (File(_icons).existsSync()) {
      final l = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(File(_icons).readAsBytesSync())));
      await l.load();
    }
    t.view.physicalSize = const Size(390 * 2, 420 * 2);
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
    final cards = [
      _p('a', 'Reel 0154', ProjectStatus.open, null, 600),
      _p('b', 'Brand film 0155 with a long title', ProjectStatus.claimed, 'Abdullah Ishraq Rafi Longname', 12500),
      _p('c', 'Short 0156', ProjectStatus.submitted, 'Mim', 75),
    ];
    await t.pumpWidget(ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('shot'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                for (final p in cards)
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: WaraProjectCard(project: p, listId: 'l', showAssignee: true)),
              ]),
            ),
          ),
        ),
      ),
    ));
    await t.pumpAndSettle();

    final trailing = find.byKey(const Key('card_trailing'));
    final dots = find.byKey(const Key('card_status_dot'));
    final chev = find.byKey(const Key('card_chevron'));
    expect(trailing, findsNWidgets(3));
    final rights = [for (var i = 0; i < 3; i++) t.getRect(trailing.at(i)).right];
    for (var i = 0; i < 3; i++) {
      expect(t.getRect(chev.at(i)).right, closeTo(rights[i], 0.01));
      expect(t.getRect(dots.at(i)).left, closeTo(t.getRect(dots.at(0)).left, 0.01));
      expect(rights[i], closeTo(rights[0], 0.01));
    }
    // price text right edge == trailing right edge
    for (final s in ['৳600', '৳12500', '৳75']) {
      expect(t.getRect(find.text(s)).right, closeTo(rights[0], 0.01));
    }
    await expectLater(find.byKey(const Key('shot')), matchesGoldenFile('goldens/card_alignment.png'));
  });
}
