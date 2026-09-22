import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WaraAvatar extends StatefulWidget {
  final String? name;
  final String? photoUrl;
  final double radius;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;

  const WaraAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 20,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
  });

  /// Extracts two initials: First letter of surname (last name) + First letter of first name.
  /// E.g. "Walid Islam" -> "IW" (Surname 'I' + First name 'W')
  /// E.g. "Ishraq Rafi" -> "RI" (Surname 'R' + First name 'I')
  /// If only one word, returns first letter.
  static String computeInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    final firstName = parts.first;
    final surname = parts.last;
    final surnameChar = surname.isNotEmpty ? surname[0].toUpperCase() : '';
    final firstNameChar = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    return '$surnameChar$firstNameChar';
  }

  @override
  State<WaraAvatar> createState() => _WaraAvatarState();
}

class _WaraAvatarState extends State<WaraAvatar> {
  bool _imageLoadFailed = false;

  @override
  void didUpdateWidget(covariant WaraAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoUrl != widget.photoUrl) {
      _imageLoadFailed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initials = WaraAvatar.computeInitials(widget.name);
    final hasPhoto = widget.photoUrl != null &&
        widget.photoUrl!.trim().isNotEmpty &&
        !_imageLoadFailed;

    final effectiveRadius = widget.radius;
    final effectiveFontSize = widget.fontSize ?? (effectiveRadius * 0.7);
    final effectiveBg = widget.backgroundColor ?? (colors.isDark ? colors.card : colors.surface);
    final effectiveTextColor = widget.textColor ?? colors.primary;

    if (hasPhoto) {
      return CircleAvatar(
        radius: effectiveRadius,
        backgroundColor: effectiveBg,
        backgroundImage: NetworkImage(widget.photoUrl!.trim()),
        onBackgroundImageError: (exception, stackTrace) {
          if (mounted) {
            setState(() => _imageLoadFailed = true);
          }
        },
      );
    }

    return CircleAvatar(
      radius: effectiveRadius,
      backgroundColor: effectiveBg,
      child: Text(
        initials,
        style: TextStyle(
          color: effectiveTextColor,
          fontSize: effectiveFontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
