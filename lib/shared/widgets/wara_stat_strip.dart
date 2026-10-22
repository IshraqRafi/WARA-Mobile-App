import 'package:flutter/material.dart';
import '../motion/rolling_counter.dart';
import '../../core/theme/app_theme.dart';
import 'wara_status_chip.dart';

class WaraStat {
  final String label;
  final int value;
  final WaraTone tone;
  const WaraStat({required this.label, required this.value, required this.tone});
}

/// One compact row of equal, tappable metric segments: dot, bold number,
/// one-word label. [selected] highlights a segment; tapping it again clears.
class WaraStatStrip extends StatelessWidget {
  final List<WaraStat> stats;
  final int? selected;
  final ValueChanged<int?> onSelect;

  const WaraStatStrip({super.key, required this.stats, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) VerticalDivider(width: 1, thickness: 1, indent: 12, endIndent: 12, color: c.border),
            Expanded(child: _segment(context, c, text, i)),
          ],
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, AppColors c, TextTheme text, int i) {
    final s = stats[i];
    final isSel = selected == i;
    final dot = s.value > 0 ? s.tone.fg(c) : c.muted;
    return Semantics(
      button: true,
      selected: isSel,
      label: '${s.label}: ${s.value}',
      excludeSemantics: true,
      child: Material(
        color: isSel ? s.tone.bg(c) : Colors.transparent,
        child: InkWell(
          key: ValueKey('stat_${s.label}'),
          onTap: () => onSelect(isSel ? null : i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RollingCounter(value: s.value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.1)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(s.label, style: text.labelMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
