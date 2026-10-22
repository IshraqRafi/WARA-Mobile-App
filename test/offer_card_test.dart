import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/editor/presentation/widgets/offer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 10, 23, 12);

ProjectItem offer({int hours = 30, List<String> skills = const ['Reel'], DateTime? posted, DateTime? deadlineAt}) => ProjectItem(
    id: 'p', title: 'Brand reel', clientName: 'C', editorPayout: 12000, legacyClientBudget: 99999,
    deadlineStr: '', deadlineHoursLeft: hours, deadlineAt: deadlineAt, postedAt: posted,
    description: 'Cut a 30s reel\nsecond line', requiredSkills: skills, status: ProjectStatus.open);

Future<void> pump(WidgetTester t, ProjectItem p, {String? agency, VoidCallback? onLong}) => t.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: OfferCard(project: p, agencyName: agency, now: now, onLongPress: onLong ?? () {}))));

void main() {
  test('helpers', () {
    expect(groupedTaka(1200000), '৳1,200,000');
    expect(groupedDigits(950), '950');
    expect(offerDue(0), '<1h');
    expect(offerDue(30), '30h');
    expect(offerDue(60), '2d');
    expect(initials('Studio Alpha'), 'SA');
    expect(initials(''), '');
    expect(isNewOffer(offer(posted: now.subtract(const Duration(hours: 2))), now), isTrue);
    expect(isNewOffer(offer(posted: now.subtract(const Duration(hours: 30))), now), isFalse);
    expect(isNewOffer(offer(), now), isFalse);
  });

  testWidgets('payout, type chip, deadline pill, brief, avatar; never client price; long-press claims', (t) async {
    var claimed = 0;
    await pump(t, offer(), agency: 'Studio Alpha', onLong: () => claimed++);
    expect(find.textContaining('12,000', findRichText: true), findsOneWidget);
    expect(find.text('Reel'), findsOneWidget);
    expect(find.text('30h'), findsOneWidget);
    expect(find.text('Cut a 30s reel'), findsOneWidget);
    expect(find.text('second line'), findsNothing);
    expect(find.text('SA'), findsOneWidget);
    expect(find.textContaining('99', findRichText: true), findsNothing);
    expect(find.byKey(const ValueKey('offer_new')), findsNothing);
    await t.longPress(find.byKey(const ValueKey('offer_p')));
    expect(claimed, 1);
  });

  testWidgets('missing fields are hidden; new dot when posted < 24h; 2d pill', (t) async {
    await pump(t, offer(skills: const [], hours: 60, posted: now.subtract(const Duration(hours: 1))));
    expect(find.byKey(const ValueKey('offer_type')), findsNothing);
    expect(find.byKey(const ValueKey('offer_avatar')), findsNothing);
    expect(find.byKey(const ValueKey('offer_new')), findsOneWidget);
    expect(find.text('2d'), findsOneWidget);
  });

  testWidgets('pill turns amber under 24h (live from deadlineAt)', (t) async {
    await pump(t, offer(hours: 99, deadlineAt: now.add(const Duration(hours: 5))));
    expect(find.text('5h'), findsOneWidget);
    final text = t.widget<Text>(find.text('5h'));
    expect(text.style?.color, AppTheme.dark.extension<AppColors>()?.warning ?? text.style?.color);
  });

  testWidgets('skeleton renders', (t) async {
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark, home: const Scaffold(body: OfferCardSkeleton())));
    expect(find.byType(OfferCardSkeleton), findsOneWidget);
  });
}
