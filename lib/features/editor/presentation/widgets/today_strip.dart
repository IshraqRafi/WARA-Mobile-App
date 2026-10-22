import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';

/// Time left on [p] at [now]: from deadlineAt when known, else the static
/// deadlineHoursLeft (legacy docs).
Duration timeLeft(ProjectItem p, DateTime now) {
  final at = p.deadlineAt;
  if (at != null) return at.difference(now);
  return p.isOverdue ? const Duration(hours: -1) : Duration(hours: p.deadlineHoursLeft);
}

/// The editor's in-progress project with the nearest deadline, or null.
ProjectItem? nextDeadline(Iterable<ProjectItem> mine, DateTime now) {
  ProjectItem? best;
  for (final p in mine) {
    if (p.status != ProjectStatus.claimed) continue;
    if (best == null || timeLeft(p, now) < timeLeft(best, now)) best = p;
  }
  return best;
}

/// "2d 4h", "5h 12m", "12m 30s"; overdue reads "Overdue 3h".
String countdown(Duration d) {
  String f(Duration x) {
    if (x.inHours >= 48) return '${x.inDays}d ${x.inHours % 24}h';
    if (x.inHours >= 1) return '${x.inHours}h ${x.inMinutes % 60}m';
    return '${x.inMinutes}m ${x.inSeconds % 60}s';
  }
  if (d.isNegative) {
    final o = -d;
    return 'Overdue ${o.inHours >= 1 ? (o.inHours >= 48 ? '${o.inDays}d' : '${o.inHours}h') : '${o.inMinutes}m'}';
  }
  return f(d);
}

/// Pinned strip: next deadline with a live countdown. Amber under 24h,
/// error when overdue.
class TodayStrip extends StatefulWidget {
  final ProjectItem project;
  final VoidCallback onTap;
  /// Test hook; defaults to DateTime.now.
  final DateTime Function() clock;
  const TodayStrip({super.key, required this.project, required this.onTap, this.clock = DateTime.now});

  @override
  State<TodayStrip> createState() => _TodayStripState();
}

class _TodayStripState extends State<TodayStrip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Only deadlineAt can tick; legacy hours are static.
    if (widget.project.deadlineAt != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final left = timeLeft(widget.project, widget.clock());
    final tone = left.isNegative ? c.error : (left.inHours < 24 ? c.warning : c.text);
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: c.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const ValueKey('today_strip'),
        onTap: () {
          Haptics.tick();
          widget.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          child: Row(children: [
            Text('Next', style: text.labelMedium?.copyWith(color: c.muted)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(widget.project.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(color: c.text, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: AppSpacing.sm),
            AnimatedDefaultTextStyle(
              duration: Motion.of(context),
              style: (text.labelLarge ?? const TextStyle()).copyWith(
                color: tone,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              child: Text(countdown(left), key: const ValueKey('today_countdown')),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.muted),
          ]),
        ),
      ),
    );
  }
}
