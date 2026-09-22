import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';

class WaraThemeToggle extends ConsumerStatefulWidget {
  final bool compact;

  const WaraThemeToggle({
    super.key,
    this.compact = false,
  });

  @override
  ConsumerState<WaraThemeToggle> createState() => _WaraThemeToggleState();
}

class _WaraThemeToggleState extends ConsumerState<WaraThemeToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curvedAnimation;

  @override
  void initState() {
    super.initState();
    final isDark = ref.read(themeNotifierProvider) == ThemeMode.dark;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      value: isDark ? 1.0 : 0.0,
    );

    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onToggle() {
    HapticFeedback.lightImpact();
    ref.read(themeNotifierProvider.notifier).toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to theme changes to trigger smooth animation
    ref.listen<ThemeMode>(themeNotifierProvider, (prev, next) {
      final isDark = next == ThemeMode.dark;
      if (isDark && _controller.value < 0.5) {
        _controller.animateTo(1.0, curve: Curves.easeInOutCubic);
      } else if (!isDark && _controller.value > 0.5) {
        _controller.animateTo(0.0, curve: Curves.easeInOutCubic);
      }
    });

    final compact = widget.compact;
    final trackWidth = compact ? 70.0 : 78.0;
    final trackHeight = compact ? 34.0 : 38.0;
    final thumbSize = compact ? 26.0 : 30.0;
    final padding = compact ? 3.0 : 4.0;
    final maxTravel = trackWidth - thumbSize - (padding * 2);

    return Semantics(
      label: _controller.value > 0.5 ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      button: true,
      child: GestureDetector(
        onTap: _onToggle,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _curvedAnimation,
          builder: (context, _) {
            final t = _curvedAnimation.value; // 0.0 = Sun (Light), 1.0 = Moon (Dark)

            // Dynamic background and border colors
            final trackBg = Color.lerp(
              const Color(0xFFE2E8F0),
              const Color(0xFF131722),
              t,
            )!;
            final trackBorder = Color.lerp(
              const Color(0xFFCBD5E1),
              const Color(0xFF2E384D),
              t,
            )!;

            // Fluid stretch during transition (expands in middle of flight)
            final stretch = math.sin(t * math.pi) * (compact ? 6.0 : 8.0);
            final currentThumbWidth = thumbSize + stretch;
            final thumbLeft = padding + (t * (maxTravel - stretch));

            // Thumb colors & glow
            final thumbColor1 = Color.lerp(
              const Color(0xFFFFB300),
              const Color(0xFFE0E7FF),
              t,
            )!;
            final thumbColor2 = Color.lerp(
              const Color(0xFFF57C00),
              const Color(0xFF94A3B8),
              t,
            )!;
            final sunGlowAlpha = ((1.0 - t) * 0.45).clamp(0.0, 1.0);
            final moonGlowAlpha = (t * 0.4).clamp(0.0, 1.0);

            return Container(
              width: trackWidth,
              height: trackHeight,
              decoration: BoxDecoration(
                color: trackBg,
                borderRadius: BorderRadius.circular(trackHeight / 2),
                border: Border.all(color: trackBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: lerpDouble(0.06, 0.35, t)!),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // ── Little Night Stars (Right Side) ──────────────────────
                  Positioned(
                    right: compact ? 10 : 12,
                    top: compact ? 7 : 8,
                    child: Opacity(
                      opacity: (t * 0.9).clamp(0.0, 1.0),
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0E7FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: compact ? 18 : 22,
                    bottom: compact ? 7 : 9,
                    child: Opacity(
                      opacity: (t * 0.65).clamp(0.0, 1.0),
                      child: Container(
                        width: 2,
                        height: 2,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC7D2FE),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: compact ? 7 : 8,
                    bottom: compact ? 9 : 11,
                    child: Opacity(
                      opacity: (t * 0.75).clamp(0.0, 1.0),
                      child: Container(
                        width: 2.5,
                        height: 2.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0E7FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),

                  // ── Soft Daytime Hint (Left Side) ────────────────────────
                  Positioned(
                    left: compact ? 10 : 12,
                    bottom: compact ? 6 : 7,
                    child: Opacity(
                      opacity: ((1.0 - t) * 0.45).clamp(0.0, 1.0),
                      child: Container(
                        width: compact ? 10 : 14,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // ── Animated Moving Thumb ────────────────────────────────
                  Positioned(
                    left: thumbLeft,
                    top: padding,
                    bottom: padding,
                    child: Container(
                      width: currentThumbWidth,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [thumbColor1, thumbColor2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(thumbSize / 2),
                        boxShadow: [
                          if (sunGlowAlpha > 0.01)
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: sunGlowAlpha),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          if (moonGlowAlpha > 0.01)
                            BoxShadow(
                              color: const Color(0xFF818CF8).withValues(alpha: moonGlowAlpha),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Sun Icon (Left Slot) ──────────────────────────────────
                  Positioned(
                    left: padding,
                    width: thumbSize,
                    height: thumbSize,
                    child: Center(
                      child: Transform.rotate(
                        angle: t * math.pi, // Smooth 180° rotation
                        child: Transform.scale(
                          scale: lerpDouble(1.08, 0.75, t)!,
                          child: Icon(
                            Icons.wb_sunny_rounded,
                            size: compact ? 15 : 17,
                            color: Color.lerp(
                              Colors.white,
                              const Color(0xFF64748B).withValues(alpha: 0.55),
                              t,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Moon Icon (Right Slot) ─────────────────────────────────
                  Positioned(
                    right: padding,
                    width: thumbSize,
                    height: thumbSize,
                    child: Center(
                      child: Transform.rotate(
                        angle: (1.0 - t) * (-0.25 * math.pi), // Tilts gracefully into view
                        child: Transform.scale(
                          scale: lerpDouble(0.75, 1.08, t)!,
                          child: Icon(
                            Icons.nightlight_round,
                            size: compact ? 15 : 17,
                            color: Color.lerp(
                              const Color(0xFF94A3B8).withValues(alpha: 0.55),
                              const Color(0xFF0F172A),
                              t,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
