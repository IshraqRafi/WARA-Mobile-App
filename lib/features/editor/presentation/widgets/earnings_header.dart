import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';
import '../../../../shared/widgets/wara_sparkline.dart';
import '../../domain/editor_earnings.dart';

/// Editor home: big "This month" earned, smaller "Pending", each with a
/// six-month sparkline.
class EarningsHeader extends StatelessWidget {
  final EditorEarnings earnings;
  const EarningsHeader({super.key, required this.earnings});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('This month', style: text.labelMedium?.copyWith(color: c.muted)),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedCount(
              key: const ValueKey('earned_month'),
              format: takaFormat,
              value: earnings.thisMonth,
              style: text.displaySmall?.copyWith(color: c.text, fontWeight: FontWeight.w700, letterSpacing: -0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          WaraSparkline(key: const ValueKey('earned_spark'), values: earnings.earnedSeries, color: c.primary, width: 96),
        ]),
      ),
      const SizedBox(width: AppSpacing.lg),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('Pending', style: text.labelMedium?.copyWith(color: c.muted)),
        const SizedBox(height: AppSpacing.xs),
        AnimatedCount(
          key: const ValueKey('earned_pending'),
          format: takaFormat,
          value: earnings.pending,
          style: text.titleMedium?.copyWith(color: c.text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        WaraSparkline(key: const ValueKey('pending_spark'), values: earnings.pendingSeries, color: c.muted, width: 56, height: 16),
      ]),
    ]);
  }
}
