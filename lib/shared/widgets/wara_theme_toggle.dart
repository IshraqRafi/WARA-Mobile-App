import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../motion/motion.dart';

/// Day/night switch. One thumb slides across a sky that shifts from day to
/// night; the sun's disc is eaten by a sliding shadow into a crescent moon,
/// its rays retract and stars fade in. 400ms easeOutCubic, haptic tick, and
/// it snaps instantly under reduced motion.
class WaraThemeToggle extends ConsumerStatefulWidget {
  final bool compact;
  const WaraThemeToggle({super.key, this.compact = false});

  @override
  ConsumerState<WaraThemeToggle> createState() => _WaraThemeToggleState();
}

class _WaraThemeToggleState extends ConsumerState<WaraThemeToggle> with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 400);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _duration,
    value: ref.read(themeNotifierProvider) == ThemeMode.dark ? 1 : 0,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _sync(bool dark) {
    final target = dark ? 1.0 : 0.0;
    if (_c.value == target && !_c.isAnimating) return;
    if (Motion.reduced(context)) {
      _c.value = target;
    } else {
      _c.animateTo(target, duration: _duration, curve: Curves.easeOutCubic);
    }
  }

  void _onToggle() {
    Haptics.light();
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize ? box.localToGlobal(box.size.center(Offset.zero)) : Offset.zero;
    ThemeReveal.run(context, origin, () => ref.read(themeNotifierProvider.notifier).toggleTheme());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ThemeMode>(themeNotifierProvider, (_, next) => _sync(next == ThemeMode.dark));
    final dark = ref.watch(themeNotifierProvider) == ThemeMode.dark;
    final w = widget.compact ? 56.0 : 64.0;
    final h = widget.compact ? 30.0 : 34.0;
    return Semantics(
      button: true,
      toggled: dark,
      label: 'Dark mode',
      child: GestureDetector(
        key: const ValueKey('theme_toggle'),
        onTap: _onToggle,
        behavior: HitTestBehavior.opaque,
        child: RepaintBoundary(
          child: CustomPaint(size: Size(w, h), painter: _DayNightPainter(_c)),
        ),
      ),
    );
  }
}

class _DayNightPainter extends CustomPainter {
  final Animation<double> t;
  _DayNightPainter(this.t) : super(repaint: t);

  static const _stars = [Offset(0.20, 0.30), Offset(0.34, 0.66), Offset(0.12, 0.62), Offset(0.42, 0.28)];

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value.clamp(0.0, 1.0);
    final r = size.height / 2;
    final track = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r));

    // Sky.
    final sky = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(const Color(0xFF7DD3FC), const Color(0xFF0B1026), v)!,
        Color.lerp(const Color(0xFF38BDF8), const Color(0xFF26215C), v)!,
      ],
    );
    canvas.drawRRect(track, Paint()..shader = sky.createShader(Offset.zero & size));
    canvas.drawRRect(
      track.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.10 + 0.06 * v),
    );

    canvas.save();
    canvas.clipRRect(track);

    // Stars fade in on the left as the thumb leaves it (last 60% of travel).
    final starA = ((v - 0.4) / 0.6).clamp(0.0, 1.0);
    if (starA > 0) {
      for (var i = 0; i < _stars.length; i++) {
        final p = Offset(_stars[i].dx * size.width, _stars[i].dy * size.height);
        canvas.drawCircle(p, i.isEven ? 1.1 : 0.8, Paint()..color = Colors.white.withValues(alpha: starA * (i.isEven ? 0.95 : 0.6)));
      }
    }

    // Soft cloud on the right in daytime.
    final cloudA = (1 - v * 1.6).clamp(0.0, 1.0);
    if (cloudA > 0) {
      final cp = Paint()..color = Colors.white.withValues(alpha: 0.55 * cloudA);
      final cy = size.height * 0.68 + v * 6;
      canvas.drawCircle(Offset(size.width * 0.66, cy), r * 0.26, cp);
      canvas.drawCircle(Offset(size.width * 0.76, cy - 2), r * 0.32, cp);
      canvas.drawCircle(Offset(size.width * 0.86, cy), r * 0.24, cp);
    }

    // Thumb.
    const pad = 3.0;
    final tr = r - pad;
    final cx = pad + tr + (size.width - 2 * (pad + tr)) * v;
    final c = Offset(cx, r);

    canvas.drawCircle(c + const Offset(0, 1), tr, Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // Sun rays retract as it turns.
    final rayA = (1 - v * 2).clamp(0.0, 1.0);
    if (rayA > 0) {
      final rp = Paint()
        ..color = const Color(0xFFFFE08A).withValues(alpha: 0.5 * rayA)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + v * math.pi / 2;
        final d = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(c + d * (tr * 0.62), c + d * (tr * (0.80 - 0.15 * v)), rp);
      }
    }

    // Disc: sun -> moon colour, with a shadow disc sliding in to carve a
    // crescent (drawn via saveLayer + clear blend so the sky shows through).
    final disc = Color.lerp(const Color(0xFFFFC53D), const Color(0xFFE8ECF7), v)!;
    final discR = tr * (0.62 + 0.38 * v);
    canvas.saveLayer(Rect.fromCircle(center: c, radius: tr + 1), Paint());
    canvas.drawCircle(c, discR, Paint()..color = disc);
    if (v > 0) {
      final bite = Offset(cx + discR * (1.25 - 0.70 * v), r - discR * 0.35 * v);
      canvas.drawCircle(bite, discR * 0.82, Paint()..blendMode = BlendMode.clear);
    }
    canvas.restore();

    // Moon craters fade in.
    if (v > 0.6) {
      final ca = ((v - 0.6) / 0.4);
      final cp = Paint()..color = const Color(0xFFB8C0D6).withValues(alpha: 0.7 * ca);
      canvas.drawCircle(c + Offset(-discR * 0.35, discR * 0.15), discR * 0.14, cp);
      canvas.drawCircle(c + Offset(-discR * 0.05, discR * 0.48), discR * 0.09, cp);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_DayNightPainter old) => old.t != t;
}
