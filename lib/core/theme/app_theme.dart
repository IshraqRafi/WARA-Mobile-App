import 'package:flutter/material.dart';
import 'app_tokens.dart';

export 'app_tokens.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color card;
  final Color primary;
  final Color text;
  final Color muted;
  final Color border;
  final Color error;
  final Color success;
  final Color warning;
  final Color info;
  final bool isDark;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.card,
    required this.primary,
    required this.text,
    required this.muted,
    required this.border,
    required this.error,
    required this.success,
    required this.warning,
    required this.info,
    required this.isDark,
  });

  /// 12% tints for status backgrounds (chips, banners, stat cards).
  Color get errorTint => error.withValues(alpha: 0.12);
  Color get successTint => success.withValues(alpha: 0.12);
  Color get warningTint => warning.withValues(alpha: 0.12);
  Color get infoTint => info.withValues(alpha: 0.12);
  Color get primaryTint => primary.withValues(alpha: 0.12);
  /// Foreground on top of [primary] (black on the dark theme's light primary).
  Color get onPrimary => isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);

  /// Fixed brand surface behind the logo (dark in both themes).
  static const Color brandInk = Color(0xFF141414);
  static const Color brandInkBorder = Color(0xFF2C2C2C);

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? card,
    Color? primary,
    Color? text,
    Color? muted,
    Color? border,
    Color? error,
    Color? success,
    Color? warning,
    Color? info,
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
      error: error ?? this.error,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
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
      error: Color.lerp(error, other.error, t) ?? error,
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      info: Color.lerp(info, other.info, t) ?? info,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }

  static const dark = AppColors(
    bg: Color(0xFF0A0A0A),
    surface: Color(0xFF161616),
    card: Color(0xFF1E1E1E),
    primary: Color(0xFFFFFFFF),
    text: Color(0xFFF0F0F0),
    muted: Color(0xFFA3A3A3),
    border: Color(0xFF2C2C2C),
    error: Color(0xFFFF5C5C),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    info: Color(0xFF60A5FA),
    isDark: true,
  );

  static const light = AppColors(
    bg: Color(0xFFF8F9FA),
    surface: Color(0xFFECEFF1),
    card: Color(0xFFFFFFFF),
    primary: Color(0xFF111111),
    text: Color(0xFF111111),
    muted: Color(0xFF5F6B76),
    border: Color(0xFFDDE2E5),
    error: Color(0xFFDC2626),
    success: Color(0xFF15803D),
    warning: Color(0xFFB45309),
    info: Color(0xFF1D4ED8),
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
  static ThemeData get dark => _build(AppColors.dark);
  static ThemeData get light => _build(AppColors.light);

  static TextTheme _textTheme(AppColors c) => TextTheme(
        displayLarge: TextStyle(color: c.text, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1, height: 1.2),
        displayMedium: TextStyle(color: c.text, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2),
        displaySmall: TextStyle(color: c.text, fontSize: 28, fontWeight: FontWeight.w700, height: 1.25),
        headlineLarge: TextStyle(color: c.text, fontSize: 28, fontWeight: FontWeight.w700, height: 1.25),
        headlineMedium: TextStyle(color: c.text, fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
        headlineSmall: TextStyle(color: c.text, fontSize: 24, fontWeight: FontWeight.w700, height: 1.3),
        titleLarge: TextStyle(color: c.text, fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
        titleMedium: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
        titleSmall: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
        bodyLarge: TextStyle(color: c.text, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
        bodySmall: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),
        labelLarge: TextStyle(color: c.text, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        labelMedium: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        labelSmall: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.4),
      );

  static ThemeData _build(AppColors c) {
    final onPrimary = c.onPrimary;
    final scheme = (c.isDark ? const ColorScheme.dark() : const ColorScheme.light()).copyWith(
      primary: c.primary,
      onPrimary: onPrimary,
      secondary: c.muted,
      onSecondary: onPrimary,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.muted,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.card,
      surfaceContainer: c.card,
      surfaceContainerHigh: c.card,
      surfaceContainerHighest: c.surface,
      outline: c.border,
      outlineVariant: c.border,
      error: c.error,
      onError: Colors.white,
    );
    final text = _textTheme(c);
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.brMd);
    const buttonMin = Size(64, 48);
    final buttonPad = const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md);

    return ThemeData(
      useMaterial3: true,
      brightness: c.isDark ? Brightness.dark : Brightness.light,
      extensions: [c],
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      cardColor: c.card,
      dividerColor: c.border,
      textTheme: text,
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: c.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg, side: BorderSide(color: c.border)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: onPrimary,
          disabledBackgroundColor: c.primary.withValues(alpha: 0.38),
          disabledForegroundColor: onPrimary.withValues(alpha: 0.7),
          minimumSize: buttonMin,
          padding: buttonPad,
          shape: buttonShape,
          textStyle: text.labelLarge,
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: onPrimary,
          minimumSize: buttonMin,
          padding: buttonPad,
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.text,
          minimumSize: buttonMin,
          padding: buttonPad,
          shape: buttonShape,
          side: BorderSide(color: c.border, width: 1.2),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: text.labelLarge,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surface,
        selectedColor: c.primaryTint,
        side: BorderSide(color: c.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brPill),
        labelStyle: text.labelMedium?.copyWith(color: c.text),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        hintStyle: text.bodyMedium?.copyWith(color: c.muted),
        labelStyle: text.bodyMedium?.copyWith(color: c.muted),
        floatingLabelStyle: text.labelMedium?.copyWith(color: c.text),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: c.error),
        prefixIconColor: c.muted,
        suffixIconColor: c.muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
        border: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: c.border)),
        enabledBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: c.border)),
        focusedBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: c.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: c.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: AppRadius.brMd, borderSide: BorderSide(color: c.error, width: 1.5)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: AppRadius.brMd)),
          side: WidgetStatePropertyAll(BorderSide(color: c.border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.primary : c.card,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? onPrimary : c.text,
          ),
          iconColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? onPrimary : c.muted,
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: c.muted,
        textColor: c.text,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall,
        minVerticalPadding: AppSpacing.md,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? onPrimary : c.muted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.primary : c.surface),
        trackOutlineColor: WidgetStatePropertyAll(c.border),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXl),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.text,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.bg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.primaryTint,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected)
            ? text.labelMedium!.copyWith(color: c.primary, fontWeight: FontWeight.w700)
            : text.labelMedium!.copyWith(color: c.muted)),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? c.primary : c.muted,
              size: 24,
            )),
      ),
    );
  }
}
