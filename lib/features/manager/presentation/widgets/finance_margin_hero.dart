import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';
import '../../../projects/domain/project_provider.dart';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String monthLabel(DateTime m) => '${_months[m.month - 1]} ${m.year}';

/// Net margin (client price − editor payout) of approved, priced projects
/// whose `claimedAt` falls in [month]. `claimedAt` is the only per-project
/// date in the data, so it stands in for the booking date.
class MonthlyMargin {
  final double? total; // null: no approved, priced project that month
  final List<double> cumulative; // running margin per day of month
  const MonthlyMargin(this.total, this.cumulative);

  factory MonthlyMargin.of(List<ProjectItem> projects, Map<String, ProjectFinance> finance, DateTime month) {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final daily = List<double>.filled(days, 0);
    var any = false;
    for (final p in projects) {
      final at = p.claimedAt;
      if (p.status != ProjectStatus.approved || at == null) continue;
      if (at.year != month.year || at.month != month.month) continue;
      final price = clientPriceOf(p, finance);
      if (price == null) continue;
      daily[at.day - 1] += price - p.editorPayout;
      any = true;
    }
    var run = 0.0;
    return MonthlyMargin(any ? daily.fold<double>(0, (a, b) => a + b) : null, [for (final d in daily) run += d]);
  }

  /// % change vs [prev]; null when either side is missing or prev is zero.
  double? changeVs(MonthlyMargin prev) {
    final a = total, b = prev.total;
    if (a == null || b == null || b == 0) return null;
    return (a - b) / b.abs() * 100;
  }
}

/// Compact month stepper: ‹ Oct 2026 ›. Never steps past the current month.
class FinanceMonthSwitcher extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final DateTime? now;
  const FinanceMonthSwitcher({super.key, required this.month, required this.onChanged, this.now});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = now ?? DateTime.now();
    final atLatest = month.year == n.year && month.month == n.month;
    Widget chev(IconData i, String key, DateTime? to) => IconButton(
          key: ValueKey(key),
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
          iconSize: 20,
          color: c.text,
          disabledColor: c.muted.withValues(alpha: 0.35),
          onPressed: to == null
              ? null
              : () {
                  Haptics.tick();
                  onChanged(to);
                },
          icon: Icon(i),
        );
    return Row(mainAxisSize: MainAxisSize.min, children: [
      chev(Icons.chevron_left_rounded, 'month_prev', DateTime(month.year, month.month - 1)),
      AnimatedSwitcher(
        duration: Motion.of(context, const Duration(milliseconds: 200)),
        child: Text(
          monthLabel(month),
          key: ValueKey(month),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.text, fontWeight: FontWeight.w600),
        ),
      ),
      chev(Icons.chevron_right_rounded, 'month_next', atLatest ? null : DateTime(month.year, month.month + 1)),
    ]);
  }
}

/// Hero: this month's net margin, counting up from 0 (700ms), a % change vs
/// last month, and a hairline sparkline of the running margin behind it.
class FinanceMarginHero extends StatelessWidget {
  final MonthlyMargin current;
  final MonthlyMargin previous;
  final DateTime month;
  const FinanceMarginHero({super.key, required this.current, required this.previous, required this.month});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final total = current.total;
    final change = current.changeVs(previous);
    final reduce = Motion.reduced(context);
    final figureStyle = text.displaySmall?.copyWith(
      color: c.text,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return SizedBox(
      key: const ValueKey('margin_hero'),
      height: 132,
      child: Stack(children: [
        Positioned.fill(top: 48, child: IgnorePointer(child: _Sparkline(values: current.cumulative, empty: total == null, reduce: reduce))),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Net margin', style: text.labelMedium?.copyWith(color: c.muted)),
          const SizedBox(height: AppSpacing.xs),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: total == null
                    ? Text('—', key: const ValueKey('margin_value'), style: figureStyle)
                    : TweenAnimationBuilder<double>(
                        key: ValueKey(month),
                        tween: Tween(begin: reduce ? total : 0, end: total),
                        duration: reduce ? Duration.zero : const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => Text(
                          '${v < 0 ? '−' : ''}৳${_taka(v.abs())}',
                          key: const ValueKey('margin_value'),
                          style: figureStyle,
                        ),
                      ),
              ),
            ),
            if (change != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _ChangeChip(change),
            ],
          ]),
        ]),
      ]),
    );
  }
}

String _taka(double v) => v.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

class _ChangeChip extends StatelessWidget {
  final double pct;
  const _ChangeChip(this.pct);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final up = pct >= 0;
    final tone = up ? c.success : c.error;
    return Container(
      key: const ValueKey('margin_change'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: tone),
        const SizedBox(width: 2),
        Text('${pct.abs().toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: tone, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;
  final bool empty;
  final bool reduce;
  const _Sparkline({required this.values, required this.empty, required this.reduce});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pts = empty || values.isEmpty ? const [0.0, 0.0] : values;
    final lo = pts.reduce((a, b) => a < b ? a : b);
    final hi = pts.reduce((a, b) => a > b ? a : b);
    final flat = hi == lo;
    final tone = c.primary.withValues(alpha: empty ? 0.25 : 0.55);
    return LineChart(
      key: const ValueKey('margin_chart'),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 400),
      LineChartData(
        minX: 0,
        maxX: (pts.length - 1).toDouble(),
        minY: flat ? lo - 1 : lo,
        maxY: flat ? hi + 1 : hi + (hi - lo) * 0.1,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.all(),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < pts.length; i++) FlSpot(i.toDouble(), pts[i])],
            isCurved: true,
            preventCurveOverShooting: true,
            barWidth: 1.5,
            color: tone,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: !empty, color: c.primary.withValues(alpha: 0.06)),
          ),
        ],
      ),
    );
  }
}
