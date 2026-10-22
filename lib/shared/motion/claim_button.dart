import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'motion.dart';

enum _ClaimPhase { idle, busy, done }

/// Primary action that morphs: label → spinner (while [onPressed] runs) →
/// drawn checkmark on success, then calls [onCompleted]. On failure it
/// returns to the label and [onError] gets the error.
class ClaimButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Future<void> Function() onPressed;
  final VoidCallback? onCompleted;
  final ValueChanged<Object>? onError;

  const ClaimButton({super.key, required this.label, required this.onPressed, this.icon, this.onCompleted, this.onError});

  @override
  State<ClaimButton> createState() => _ClaimButtonState();
}

class _ClaimButtonState extends State<ClaimButton> with SingleTickerProviderStateMixin {
  _ClaimPhase _phase = _ClaimPhase.idle;
  late final AnimationController _check = AnimationController(vsync: this, duration: Motion.slow);

  Future<void> _run() async {
    setState(() => _phase = _ClaimPhase.busy);
    try {
      await widget.onPressed();
    } catch (e) {
      if (!mounted) return;
      setState(() => _phase = _ClaimPhase.idle);
      widget.onError?.call(e);
      return;
    }
    if (!mounted) return;
    setState(() => _phase = _ClaimPhase.done);
    final reduced = Motion.reduced(context);
    _check.duration = reduced ? Duration.zero : Motion.slow;
    await _check.forward();
    // Hold the tick briefly so it reads.
    await Future<void>.delayed(reduced ? Duration.zero : const Duration(milliseconds: 250));
    if (mounted) widget.onCompleted?.call();
  }

  @override
  void dispose() {
    _check.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = c.onPrimary;
    final compact = _phase != _ClaimPhase.idle;
    final Widget content = switch (_phase) {
      _ClaimPhase.idle => Row(
          key: const ValueKey('idle'),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: fg), const SizedBox(width: AppSpacing.sm)],
            Text(widget.label, maxLines: 1, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg)),
          ],
        ),
      _ClaimPhase.busy => SizedBox.square(key: const ValueKey('busy'), dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg)),
      _ClaimPhase.done => SizedBox.square(
          key: const ValueKey('done'),
          dimension: 22,
          child: CustomPaint(painter: CheckmarkPainter(progress: _check, color: fg)),
        ),
    };
    return Semantics(
      button: true,
      label: switch (_phase) { _ClaimPhase.idle => widget.label, _ClaimPhase.busy => 'Working', _ClaimPhase.done => 'Done' },
      excludeSemantics: true,
      child: Pressable(
        enabled: _phase == _ClaimPhase.idle,
        child: GestureDetector(
          onTap: _phase == _ClaimPhase.idle ? _run : null,
          child: AnimatedContainer(
            duration: Motion.of(context),
            curve: Motion.curve,
            height: 40,
            constraints: BoxConstraints(minWidth: 40, maxWidth: compact ? 40 : 320),
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : AppSpacing.lg),
            decoration: BoxDecoration(
              color: _phase == _ClaimPhase.done ? c.success : c.primary,
              borderRadius: BorderRadius.circular(compact ? 20 : AppRadius.md),
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(duration: Motion.of(context, Motion.fast), child: content),
          ),
        ),
      ),
    );
  }
}

/// Draws a checkmark stroke from 0 to [progress].
class CheckmarkPainter extends CustomPainter {
  final Animation<double> progress;
  final Color color;
  CheckmarkPainter({required this.progress, required this.color}) : super(repaint: progress);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.42, size.height * 0.75)
      ..lineTo(size.width * 0.84, size.height * 0.28);
    final t = Curves.easeOutCubic.transform(progress.value.clamp(0.0, 1.0));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.5, size.width * 0.12)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * t), paint);
    }
  }

  @override
  bool shouldRepaint(CheckmarkPainter old) => old.color != color || old.progress != progress;
}
