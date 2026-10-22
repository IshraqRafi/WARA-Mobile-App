import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The multicolor Google "G", drawn with CustomPaint so no asset or extra
/// dependency is needed. Colors follow Google's sign-in branding guidelines.
class GoogleGLogo extends StatelessWidget {
  final double size;
  const GoogleGLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Google logo',
        child: SizedBox.square(dimension: size, child: const CustomPaint(painter: _GPainter())),
      );
}

class _GPainter extends CustomPainter {
  const _GPainter();

  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.2;
    final r = (s - stroke) / 2;
    final c = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: c, radius: r);
    Paint p(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    double deg(double d) => d * math.pi / 180;

    // Angles measured clockwise from 3 o'clock.
    canvas.drawArc(rect, deg(-40), deg(-50 - 55), false, p(_red)); // top
    canvas.drawArc(rect, deg(-145), deg(-70), false, p(_yellow)); // left
    canvas.drawArc(rect, deg(145), deg(-100), false, p(_green)); // bottom
    canvas.drawArc(rect, deg(45), deg(-45), false, p(_blue)); // lower right
    // Blue crossbar.
    final bar = Paint()..color = _blue;
    canvas.drawRect(Rect.fromLTRB(c.dx, c.dy - stroke / 2, c.dx + r + stroke / 2, c.dy + stroke / 2), bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
