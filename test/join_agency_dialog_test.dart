import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/editor/presentation/widgets/join_agency_dialog.dart';

Widget _host(Widget child) => MaterialApp(theme: AppTheme.light, home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('connected card is not tappable', (t) async {
    await t.pumpWidget(_host(AgencyRoomCard(agencyName: 'Alpha', joinKey: 'ALPHA-1', connected: true, onJoin: (_) async => null)));
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.byKey(const Key('agency_card_join')), findsNothing);
  });

  testWidgets('no agency: tap opens dialog, invalid key stays terse, valid key joins', (t) async {
    final tried = <String>[];
    var joined = 0;
    await t.pumpWidget(_host(AgencyRoomCard(
      agencyName: '',
      joinKey: null,
      connected: false,
      onJoin: (k) async {
        tried.add(k);
        return k == 'ALPHA-1234' ? null : 'Invalid key';
      },
      onJoined: () => joined++,
    )));
    expect(find.text('No agency connected'), findsOneWidget);
    await t.tap(find.byKey(const Key('agency_card_join')));
    await t.pumpAndSettle();
    expect(find.text('Join an agency'), findsOneWidget);

    await t.enterText(find.byKey(const Key('join_key_field')), 'NOPE');
    await t.tap(find.byKey(const Key('join_agency_button')));
    await t.pumpAndSettle();
    expect(find.text('Invalid key'), findsOneWidget);
    expect(joined, 0);

    await t.enterText(find.byKey(const Key('join_key_field')), 'ALPHA-1234');
    await t.tap(find.byKey(const Key('join_agency_button')));
    await t.pumpAndSettle();
    expect(find.text('Join an agency'), findsNothing);
    expect(tried, ['NOPE', 'ALPHA-1234']);
    expect(joined, 1);
  });
}
