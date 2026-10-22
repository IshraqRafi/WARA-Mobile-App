import 'package:flutter/material.dart';
import '../motion/motion.dart';
import '../../core/theme/app_theme.dart';
import 'wara_status_chip.dart';

class WaraStat {
  final String label;
  final int value;
  final WaraTone tone;
  const WaraStat({required this.label, required this.value, required this.tone});
}

/// One compact row of equal, tappable metric segments. The selected segment
/// sits on a small-radius (8px) neutral highlight that slides between items:
/// low-opacity white on dark, light gray on light. Text never changes
/// colour. Tapping the selected segment again clears. No ink.
class WaraStatStrip extends StatefulWidget {
  final List<WaraStat> stats;
  final int? selected;
  final ValueChanged<int?> onSelect;

  const WaraStatStrip({super.key, required this.stats, required this.selected, required this.onSelect});

  @override
  State<WaraStatStrip> createState() => _WaraStatStripState();
}

class _WaraStatStripState extends State<WaraStatStrip> {
  // Last selected index, so the pill fades out in place instead of jumping.
  int _last = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final n = widget.stats.length;
    final sel = widget.selected;
    if (sel != null) _last = sel;
    final dur = Motion.of(context, const Duration(milliseconds: 320));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);
    final x = n <= 1 ? 0.0 : -1 + 2 * _last / (n - 1);

    return Container(
      height: 64,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: dur,
              curve: Curves.easeOutCubic,
              alignment: Alignment(x, 0),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: AnimatedOpacity(
                  duration: dur,
                  curve: Curves.easeOutCubic,
                  opacity: sel == null ? 0 : 1,
                  child: DecoratedBox(
                    key: const ValueKey('stat_pill'),
                    decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < n; i++) Expanded(child: _segment(context, c, text, i)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, AppColors c, TextTheme text, int i) {
    final s = widget.stats[i];
    final isSel = widget.selected == i;
    final fg = s.tone.fg(c);
    final dot = s.value > 0 ? fg : c.muted;
    final baseNum = text.titleLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.1) ?? const TextStyle();
    return Semantics(
      button: true,
      selected: isSel,
      label: '${s.label}: ${s.value}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('stat_${s.label}'),
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.tick();
          widget.onSelect(isSel ? null : i);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RollingCounter(value: s.value, style: baseNum.copyWith(color: c.text)),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(s.label, style: text.labelMedium?.copyWith(color: c.muted)),
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
