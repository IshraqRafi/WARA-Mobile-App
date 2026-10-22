import 'package:flutter/widgets.dart';

/// 4pt-based spacing scale. Use these instead of raw numbers.
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Width at which layouts switch to tablet margins.
  static const double wideBreakpoint = 600;

  /// Horizontal screen margin: 16, or 24 on screens >= 600dp.
  static double screenMargin(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideBreakpoint ? xl : lg;

  /// Horizontal screen padding using [screenMargin].
  static EdgeInsets screenH(BuildContext context) =>
      EdgeInsets.symmetric(horizontal: screenMargin(context));

  /// Bottom padding for scrollables: safe-area inset plus [extra].
  static double bottomInset(BuildContext context, {double extra = lg}) =>
      MediaQuery.viewPaddingOf(context).bottom + extra;
}

/// Corner radius scale.
class AppRadius {
  AppRadius._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius brXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius brPill = BorderRadius.all(Radius.circular(pill));
}
