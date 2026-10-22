import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'motion.dart';

/// Offer -> Workspace hand-off: a ghost of the claimed card shrinks and
/// arcs into the bottom tab at [tabIndex] of [tabCount], then [onArrive]
/// fires (used to pop the tab badge). Reduce-motion skips the flight.
class ClaimHandoff {
  ClaimHandoff._();

  static const duration = Duration(milliseconds: 520);

  static void fly(BuildContext context,
      {required Rect from, required String label, int tabIndex = 1, int tabCount = 4, VoidCallback? onArrive}) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (Motion.reduced(context) || overlay == null) {
      onArrive?.call();
      return;
    }
    final mq = MediaQuery.of(context);
    final w = mq.size.width / tabCount;
    final to = Offset(w * tabIndex + w / 2, mq.size.height - mq.padding.bottom - 44);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Flight(from: from, to: to, label: label, onDone: () {
        entry.remove();
        onArrive?.call();
      }),
    );
    overlay.insert(entry);
  }
}

class _Flight extends StatefulWidget {
  final Rect from;
  final Offset to;
  final String label;
  final VoidCallback onDone;
  const _Flight({required this.from, required this.to, required this.label, required this.onDone});
  @override
  State<_Flight> createState() => _FlightState();
}

class _FlightState extends State<_Flight> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: ClaimHandoff.duration)
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_c.value);
          final start = widget.from.center;
          // Quadratic arc: lift a little before dropping into the tab.
          final ctrl = Offset((start.dx + widget.to.dx) / 2, start.dy - 40);
          final p = Offset(
            (1 - t) * (1 - t) * start.dx + 2 * (1 - t) * t * ctrl.dx + t * t * widget.to.dx,
            (1 - t) * (1 - t) * start.dy + 2 * (1 - t) * t * ctrl.dy + t * t * widget.to.dy,
          );
          final width = widget.from.width + (24 - widget.from.width) * t;
          final height = widget.from.height + (24 - widget.from.height) * t;
          final opacity = t < 0.8 ? 1.0 : (1 - (t - 0.8) / 0.2);
          return Stack(children: [
            Positioned(
              left: p.dx - width / 2,
              top: p.dy - height / 2,
              width: width,
              height: height,
              child: Opacity(
                opacity: opacity.clamp(0, 1),
                child: Container(
                  key: const ValueKey('claim_ghost'),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.12 + 0.6 * t),
                    borderRadius: BorderRadius.circular(8 + 4 * t),
                    border: Border.all(color: c.primary.withValues(alpha: 0.5), width: 0.5),
                  ),
                  child: t < 0.4
                      ? Text(widget.label, maxLines: 1, overflow: TextOverflow.clip, softWrap: false,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(color: c.text))
                      : null,
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
