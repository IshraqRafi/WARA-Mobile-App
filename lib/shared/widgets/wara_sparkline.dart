import 'package:flutter/material.dart';
import '../motion/motion.dart';

/// Thin trend line. Draws in once (skipped under reduce-motion); a flat or
/// empty series renders as a faint baseline.
class WaraSparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double width;
  final double height;
  const WaraSparkline({super.key, required this.values, required this.color, this.width = 64, this.height = 20});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.of(context, const Duration(milliseconds: 600)),
      curve: Motion.curve,
      builder: (_, t, _) => CustomPaint(size: Size(width, height), painter: _SparkPainter(values, color, t)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double t;
  _SparkPainter(this.values, this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final max = values.fold<double>(0, (a, b) => b > a ? b : a);
    if (values.length < 2 || max <= 0) {
      canvas.drawLine(Offset(0, size.height - 1), Offset(size.width * t, size.height - 1),
          paint..color = color.withValues(alpha: 0.35));
      return;
    }
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = (size.height - 2) * (1 - values[i] / max) + 1;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * t), paint);
      final end = m.getTangentForOffset(m.length * t)?.position;
      if (end != null && t == 1) canvas.drawCircle(end, 2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.t != t || o.color != color || o.values != values;
}
