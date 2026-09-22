import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color card;
  final Color primary;
  final Color text;
  final Color muted;
  final Color border;
  final Color warningRed;
  final bool isDark;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.card,
    required this.primary,
    required this.text,
    required this.muted,
    required this.border,
    required this.warningRed,
    required this.isDark,
  });

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? card,
    Color? primary,
    Color? text,
    Color? muted,
    Color? border,
    Color? warningRed,
    bool? isDark,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      primary: primary ?? this.primary,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      warningRed: warningRed ?? this.warningRed,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t) ?? bg,
      surface: Color.lerp(surface, other.surface, t) ?? surface,
      card: Color.lerp(card, other.card, t) ?? card,
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      text: Color.lerp(text, other.text, t) ?? text,
      muted: Color.lerp(muted, other.muted, t) ?? muted,
      border: Color.lerp(border, other.border, t) ?? border,
      warningRed: Color.lerp(warningRed, other.warningRed, t) ?? warningRed,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }

  static const dark = AppColors(
    bg: Color(0xFF0A0A0A),
    surface: Color(0xFF161616),
    card: Color(0xFF1E1E1E),
    primary: Color(0xFFFFFFFF),
    text: Color(0xFFF0F0F0),
    muted: Color(0xFF888888),
    border: Color(0xFF2C2C2C),
    warningRed: Color(0xFFFF4D4D),
    isDark: true,
  );

  static const light = AppColors(
    bg: Color(0xFFF8F9FA),
    surface: Color(0xFFECEFF1),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF111111),
    text: Color(0xFF111111),
    muted: Color(0xFF6C757D),
    border: Color(0xFFDDE2E5),
    warningRed: Color(0xFFDC2626),
    isDark: false,
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ??
        (Theme.of(context).brightness == Brightness.dark ? dark : light);
  }
}

extension ThemeContextExtension on BuildContext {
  AppColors get colors => AppColors.of(this);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    extensions: const [AppColors.dark],
    scaffoldBackgroundColor: AppColors.dark.bg,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFFFFF),
      secondary: Color(0xFFAAAAAA),
      surface: Color(0xFF161616),
      onPrimary: Colors.black,
      onSurface: Color(0xFFF0F0F0),
      outline: Color(0xFF2C2C2C),
    ),
    cardColor: AppColors.dark.card,
    useMaterial3: true,
    textTheme: const TextTheme(
      displayLarge:   TextStyle(color: Color(0xFFF0F0F0), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
      headlineMedium: TextStyle(color: Color(0xFFF0F0F0), fontSize: 22, fontWeight: FontWeight.bold),
      headlineSmall:  TextStyle(color: Color(0xFFF0F0F0), fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge:      TextStyle(color: Color(0xFFF0F0F0), fontSize: 16),
      bodyMedium:     TextStyle(color: Color(0xFF888888), fontSize: 14),
      labelSmall:     TextStyle(color: Color(0xFF888888), fontSize: 11, letterSpacing: 0.5),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.dark.surface,
      indicatorColor: const Color(0x33FFFFFF),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: Color(0xFFFFFFFF), fontSize: 11, fontWeight: FontWeight.w600);
        }
        return const TextStyle(color: Color(0xFF888888), fontSize: 11);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFFFFFFFF), size: 22);
        }
        return const IconThemeData(color: Color(0xFF888888), size: 22);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.dark.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      hintStyle: const TextStyle(color: Color(0xFF888888)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
    ),
  );

  static ThemeData get light => ThemeData(
    brightness: Brightness.light,
    extensions: const [AppColors.light],
    scaffoldBackgroundColor: AppColors.light.bg,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF111111),
      secondary: Color(0xFF555555),
      surface: Color(0xFFECEFF1),
      onPrimary: Colors.white,
      onSurface: Color(0xFF111111),
      outline: Color(0xFFDDE2E5),
    ),
    cardColor: AppColors.light.card,
    useMaterial3: true,
    textTheme: const TextTheme(
      displayLarge:   TextStyle(color: Color(0xFF111111), fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
      headlineMedium: TextStyle(color: Color(0xFF111111), fontSize: 22, fontWeight: FontWeight.bold),
      headlineSmall:  TextStyle(color: Color(0xFF111111), fontSize: 18, fontWeight: FontWeight.w600),
      bodyLarge:      TextStyle(color: Color(0xFF111111), fontSize: 16),
      bodyMedium:     TextStyle(color: Color(0xFF6C757D), fontSize: 14),
      labelSmall:     TextStyle(color: Color(0xFF6C757D), fontSize: 11, letterSpacing: 0.5),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.light.surface,
      indicatorColor: const Color(0x1A000000),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: Color(0xFF111111), fontSize: 11, fontWeight: FontWeight.w600);
        }
        return const TextStyle(color: Color(0xFF6C757D), fontSize: 11);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Color(0xFF111111), size: 22);
        }
        return const IconThemeData(color: Color(0xFF6C757D), size: 22);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.light.card,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFDDE2E5))),
      hintStyle: const TextStyle(color: Color(0xFF6C757D)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        elevation: 0,
      ),
    ),
  );
}
