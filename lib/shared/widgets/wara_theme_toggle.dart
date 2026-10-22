import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../motion/motion.dart';

/// Compact pill switch in theme colours: surface track with a hairline
/// outline, primary thumb carrying one sun/moon glyph that rotates and
/// crossfades as it slides. 250ms easeOutCubic; instant under reduced motion.
class WaraThemeToggle extends ConsumerWidget {
  final bool compact;
  const WaraThemeToggle({super.key, this.compact = false});

  static const duration = Duration(milliseconds: 250);

  void _onToggle(BuildContext context, WidgetRef ref) {
    Haptics.light();
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize ? box.localToGlobal(box.size.center(Offset.zero)) : Offset.zero;
    ThemeReveal.run(context, origin, () => ref.read(themeNotifierProvider.notifier).toggleTheme());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final dark = ref.watch(themeNotifierProvider) == ThemeMode.dark;
    final d = Motion.of(context, duration);
    final w = compact ? 52.0 : 59.0;
    final h = compact ? 30.0 : 33.0;
    const pad = 3.5;
    final thumb = h - pad * 2;

    return Semantics(
      button: true,
      toggled: dark,
      label: 'Dark mode',
      child: GestureDetector(
        key: const ValueKey('theme_toggle'),
        onTap: () => _onToggle(context, ref),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: d,
          curve: Curves.easeOutCubic,
          width: w,
          height: h,
          padding: const EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(h / 2),
            border: Border.all(color: c.border),
          ),
          child: AnimatedAlign(
            key: const ValueKey('theme_thumb'),
            duration: d,
            curve: Curves.easeOutCubic,
            alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: thumb,
              height: thumb,
              decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: d,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: AnimatedBuilder(
                    animation: a,
                    builder: (_, ch) => Transform.rotate(angle: (1 - a.value) * -math.pi / 2, child: ch),
                    child: child,
                  ),
                ),
                child: Icon(
                  dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  key: ValueKey(dark),
                  size: thumb * 0.62,
                  color: c.bg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
