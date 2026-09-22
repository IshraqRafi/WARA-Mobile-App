import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Universal WARA brand logo badge.
///
/// Ensures the white eye line-art emblem always rests on an iconic dark/black
/// background in both Dark and Light theme modes, preserving contrast and branding.
class WaraLogo extends StatelessWidget {
  final double size;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;
  final Color borderColor;
  final List<BoxShadow>? boxShadow;

  const WaraLogo({
    super.key,
    this.size = 42,
    this.borderRadius,
    this.padding,
    this.backgroundColor = const Color(0xFF141414),
    this.borderColor = const Color(0xFF2C2C2C),
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = borderRadius ?? (size >= 60 ? 22.0 : 12.0);
    final pad = padding ?? EdgeInsets.all(size * 0.19);

    final effectiveShadow = boxShadow ??
        (!colors.isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]);

    return Container(
      width: size,
      height: size,
      padding: pad,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: effectiveShadow,
      ),
      child: Image.asset(
        AppInfo.logoPath,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(
          child: Text(
            'W',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.44,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
