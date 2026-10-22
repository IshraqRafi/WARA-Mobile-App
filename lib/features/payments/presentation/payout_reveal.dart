import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/motion/motion.dart';

/// First number in a '৳1,200 · TrxID …' body, or null.
double? amountFromBody(String body) {
  final m = RegExp(r'৳\s?([\d,]+(?:\.\d+)?)').firstMatch(body);
  return m == null ? null : double.tryParse(m[1]!.replaceAll(',', ''));
}

String? trxFromBody(String body) => RegExp(r'BK[A-Z0-9]{10}').firstMatch(body)?[0];

/// Centered payout card: the amount counts up, a soft burst and a success
/// haptic. Reduce-motion shows the final value at once, without the burst.
Future<void> showPayoutReveal(BuildContext context, {required double amount, String title = 'Payment received', String? detail}) {
  Haptics.success();
  final reduced = Motion.reduced(context);
  final future = showDialog<void>(
    context: context,
    builder: (ctx) => PayoutRevealDialog(amount: amount, title: title, detail: detail, animate: !reduced),
  );
  if (!reduced) {
    Future.delayed(const Duration(milliseconds: 380), () {
      if (context.mounted) Celebration.sparkle(context);
    });
  }
  return future;
}

class PayoutRevealDialog extends StatelessWidget {
  final double amount;
  final String title;
  final String? detail;
  final bool animate;
  const PayoutRevealDialog({super.key, required this.amount, required this.title, this.detail, this.animate = true});

  static String _fmt(int v) => v.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    return Dialog(
      key: const ValueKey('payout_reveal'),
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.border, width: 0.5)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_rounded, color: c.success, size: 36),
          const SizedBox(height: 10),
          Text(title, style: t.titleMedium?.copyWith(color: c.text, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: animate ? 0 : amount, end: amount),
            duration: animate ? const Duration(milliseconds: 900) : Duration.zero,
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text('৳${_fmt(v.round())}',
                key: const ValueKey('payout_reveal_amount'),
                style: t.displaySmall?.copyWith(color: c.text, fontWeight: FontWeight.w700, letterSpacing: -0.8, fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(detail!, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.muted)),
          ],
          const SizedBox(height: 16),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Nice')),
        ]),
      ),
    );
  }
}
