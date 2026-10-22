import 'package:demo_app/core/constants/app_constants.dart';
import 'package:demo_app/core/theme/app_theme.dart';
import 'package:demo_app/features/editor/presentation/widgets/offer_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final now = DateTime(2026, 10, 23, 12);

ProjectItem offer({int hours = 60, List<String> skills = const ['Reels'], DateTime? posted, DateTime? deadlineAt}) => ProjectItem(
    id: 'p', title: 'Brand reel', clientName: 'C', editorPayout: 12000, legacyClientBudget: 99999,
    deadlineStr: '', deadlineHoursLeft: hours, deadlineAt: deadlineAt, postedAt: posted,
    description: 'Cut a 30s reel', requiredSkills: skills, status: ProjectStatus.open);

Future<void> pump(WidgetTester t, ProjectItem p, {VoidCallback? onLong, VoidCallback? onTap}) => t.pumpWidget(MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: ListView(children: [OfferCard(project: p, now: now, onTap: onTap, onLongPress: onLong ?? () {})]))));

Color? colorOf(WidgetTester t, String label) {
  final rich = t.widget<RichText>(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains(label)));
  Color? found;
  rich.text.visitChildren((s) {
    if (s is TextSpan && s.text == label) found = s.style?.color;
    return true;
  });
  return found;
}

void main() {
  test('helpers', () {
    expect(groupedTaka(1200000), '৳1,200,000');
    expect(offerDueLabel(60), '2d left');
    expect(offerDueLabel(5), '5h left');
    expect(offerDueLabel(0), '<1h left');
    expect(offerDueLabel(-3), 'Overdue');
    expect(isNewOffer(offer(posted: now.subtract(const Duration(hours: 2))), now), isTrue);
    expect(isNewOffer(offer(), now), isFalse);
  });

  testWidgets('compact: title + payout, then deadline · skill; no brief, avatar or chip; no client price', (t) async {
    await pump(t, offer());
    expect(find.text('Brand reel'), findsOneWidget);
    expect(find.textContaining('12,000', findRichText: true), findsOneWidget);
    expect(find.textContaining('2d left  ·  Reels', findRichText: true), findsOneWidget);
    expect(find.text('Cut a 30s reel'), findsNothing);
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.textContaining('99', findRichText: true), findsNothing);
    expect(find.byKey(const ValueKey('offer_new')), findsNothing);
  });

  testWidgets('height stays within 72-84dp', (t) async {
    await pump(t, offer(posted: now));
    final h = t.getSize(find.byKey(const ValueKey('offer_p'))).height;
    expect(h, inInclusiveRange(72, 84));
  });

  testWidgets('new dot, no skill hides separator, amber <24h, error when past', (t) async {
    final colors = AppTheme.dark.extension<AppColors>()!;
    await pump(t, offer(skills: const [], hours: 99, deadlineAt: now.add(const Duration(hours: 5)), posted: now));
    expect(find.byKey(const ValueKey('offer_new')), findsOneWidget);
    expect(find.textContaining('·', findRichText: true), findsNothing);
    expect(colorOf(t, '5h left'), colors.warning);
    await pump(t, offer(hours: -2));
    expect(colorOf(t, 'Overdue'), colors.error);
  });

  testWidgets('long-press claims; tap opens detail with brief', (t) async {
    var claimed = 0;
    late BuildContext ctx;
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark, home: Scaffold(body: Builder(builder: (c) {
      ctx = c;
      return ListView(children: [OfferCard(project: offer(), now: now, onLongPress: () => claimed++, onTap: () => showOfferDetail(ctx, offer(), onClaim: () => claimed += 10, now: now))]);
    }))));
    await t.longPress(find.byKey(const ValueKey('offer_p')));
    expect(claimed, 1);
    await t.tap(find.byKey(const ValueKey('offer_p')));
    await t.pumpAndSettle();
    expect(find.text('Cut a 30s reel'), findsOneWidget);
    expect(find.byKey(const ValueKey('offer_detail')), findsOneWidget);
    expect(find.textContaining('99', findRichText: true), findsNothing);
    await t.tap(find.byKey(const ValueKey('offer_detail_claim')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('offer_detail')), findsNothing);
    expect(claimed, 11);
  });

  testWidgets('detail shows deadline, posted, agency, skills, revision notes; close X and outside tap dismiss', (t) async {
    final p = offer(hours: 99, deadlineAt: now.add(const Duration(hours: 5)), posted: now.subtract(const Duration(hours: 3)))
        .copyWith(revisionNotes: 'Tighten intro');
    var claims = 0;
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark, home: Scaffold(body: Builder(builder: (c) =>
        TextButton(onPressed: () => showOfferDetail(c, p, agencyName: 'Studio Alpha', now: now, onClaim: () => claims++), child: const Text('open'))))));
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('5h left'), findsOneWidget);
    expect(find.text('Due Oct 23, 5:00 PM'), findsOneWidget);
    expect(find.text('Posted 3h ago  ·  Studio Alpha'), findsOneWidget);
    expect(find.text('Reels'), findsOneWidget);
    expect(find.text('Tighten intro'), findsOneWidget);
    expect(find.textContaining('99', findRichText: true), findsNothing);
    await t.tap(find.byKey(const ValueKey('offer_detail_close')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('offer_detail')), findsNothing);
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.tapAt(const Offset(5, 5));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('offer_detail')), findsNothing);
    expect(claims, 0);
  });

  testWidgets('skeleton matches compact height', (t) async {
    await t.pumpWidget(MaterialApp(theme: AppTheme.dark, home: const Scaffold(body: Column(children: [OfferCardSkeleton()]))));
    expect(t.getSize(find.byType(OfferCardSkeleton)).height, 80);
  });
}
