import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'motion.dart';

/// One-shot particle celebrations drawn by a single CustomPainter in an
/// OverlayEntry inside a RepaintBoundary. The entry owns a short-lived
/// controller and removes and disposes itself when it finishes. Nothing is
/// shown under reduce-motion.
class Celebration {
  Celebration._();

  static const Color gold = Color(0xFFE8C26A);
  static const List<Color> _confetti = [gold, Color(0xFF7AA2F7), Color(0xFF9ECE6A), Color(0xFFF7768E), Color(0xFFBB9AF7)];

  /// Small gold sparkle burst at [origin] (global), or screen centre.
  static void sparkle(BuildContext context, {Offset? origin}) =>
      _show(context, origin: origin, confetti: false);

  /// Full-screen confetti fall, used once for an agency's first project.
  static void confetti(BuildContext context) => _show(context, confetti: true);

  static void _show(BuildContext context, {Offset? origin, required bool confetti}) {
    if (Motion.reduced(context)) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    final size = MediaQuery.sizeOf(context);
    final at = origin ?? size.center(Offset.zero);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Burst(
        origin: at,
        confetti: confetti,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  /// Centre of the widget that owns [context], for anchoring a sparkle.
  static Offset? centerOf(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }
}

class _Particle {
  final Offset velocity;
  final double size;
  final double spin;
  final Color color;
  _Particle(this.velocity, this.size, this.spin, this.color);
}

class _Burst extends StatefulWidget {
  final Offset origin;
  final bool confetti;
  final VoidCallback onDone;
  const _Burst({required this.origin, required this.confetti, required this.onDone});

  @override
  State<_Burst> createState() => _BurstState();
}

class _BurstState extends State<_Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.confetti ? 1800 : 700),
  );
  late final List<_Particle> _particles = _make();

  List<_Particle> _make() {
    final r = math.Random();
    if (widget.confetti) {
      return List.generate(70, (_) {
        return _Particle(
          Offset((r.nextDouble() - 0.5) * 2, 0.6 + r.nextDouble() * 0.6),
          5 + r.nextDouble() * 5,
          (r.nextDouble() - 0.5) * 12,
          Celebration._confetti[r.nextInt(Celebration._confetti.length)],
        );
      });
    }
    return List.generate(18, (i) {
      final a = i / 18 * 2 * math.pi + r.nextDouble() * 0.3;
      final speed = 50 + r.nextDouble() * 40;
      return _Particle(Offset(math.cos(a), math.sin(a)) * speed, 2 + r.nextDouble() * 3, 0, Celebration.gold);
    });
  }

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _BurstPainter(_c, _particles, widget.origin, widget.confetti),
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final Animation<double> t;
  final List<_Particle> particles;
  final Offset origin;
  final bool confetti;
  _BurstPainter(this.t, this.particles, this.origin, this.confetti) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final paint = Paint();
    if (confetti) {
      for (var i = 0; i < particles.length; i++) {
        final p = particles[i];
        final x = size.width * (i / particles.length) + p.velocity.dx * 40 * v;
        final y = -20 + (size.height + 40) * v * p.velocity.dy;
        paint.color = p.color.withValues(alpha: (1 - v * v).clamp(0, 1));
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(p.spin * v);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), paint);
        canvas.restore();
      }
      return;
    }
    final e = Curves.easeOutCubic.transform(v);
    for (final p in particles) {
      final pos = origin + p.velocity * e;
      paint.color = p.color.withValues(alpha: 1 - v);
      final s = p.size * (1 - v * 0.6);
      // Four-point sparkle.
      final path = Path()
        ..moveTo(pos.dx, pos.dy - s * 2)
        ..quadraticBezierTo(pos.dx, pos.dy, pos.dx + s * 2, pos.dy)
        ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy + s * 2)
        ..quadraticBezierTo(pos.dx, pos.dy, pos.dx - s * 2, pos.dy)
        ..quadraticBezierTo(pos.dx, pos.dy, pos.dx, pos.dy - s * 2)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => false;
}

/// Once-per-agency flag for the first-project confetti.
class FirstProjectFlag {
  FirstProjectFlag._();
  static String key(String agencyId) => 'first_project_confetti_$agencyId';
}
