import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/payout.dart';

/// Small outlined 'TEST' marker for simulated transactions.
class TestBadge extends StatelessWidget {
  const TestBadge({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(4)),
      child: Text('TEST', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}

/// 'bKash · BK… [TEST]' line for a paid item.
class PayoutMethodLine extends StatelessWidget {
  final PayoutRecord record;
  const PayoutMethodLine({super.key, required this.record});
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(
        child: Text('${record.methodLabel} · ${record.trxId}',
            key: ValueKey('trx_${record.projectId}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c.muted, fontFeatures: const [FontFeature.tabularFigures()])),
      ),
      if (record.isTest) ...[const SizedBox(width: 6), const TestBadge()],
    ]);
  }
}

/// Editor side: recent payouts with TrxID, newest first.
class RecentPayouts extends ConsumerWidget {
  final int max;
  const RecentPayouts({super.key, this.max = 3});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = (ref.watch(payoutsProvider).valueOrNull?.values.toList() ?? [])
      ..sort((a, b) => (b.paidAt ?? DateTime(0)).compareTo(a.paidAt ?? DateTime(0)));
    if (list.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Column(key: const ValueKey('recent_payouts'), crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Payouts', style: t.labelMedium?.copyWith(color: c.muted)),
      const SizedBox(height: 6),
      for (final r in list.take(max))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.projectTitle.isEmpty ? 'Payout' : r.projectTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(color: c.text)),
                PayoutMethodLine(record: r),
              ]),
            ),
            Text('৳${r.amount.round()}', style: t.labelLarge?.copyWith(color: c.success, fontWeight: FontWeight.w600)),
          ]),
        ),
    ]);
  }
}
