import 'package:flutter/widgets.dart';

export 'claim_button.dart';
export 'collapse_out.dart';
export 'container_transform.dart';
export 'glow_pulse.dart';
export 'haptics.dart';
export 'launch_reveal.dart';
export 'page_transitions.dart';
export 'pop_badge.dart';
export 'pressable.dart';
export 'rolling_counter.dart';
export 'shared_axis.dart';
export 'shimmer.dart';
export 'stagger_in.dart';
export 'swipe_feedback.dart';
export 'wara_refresh.dart';

/// Shared motion tokens. Every animation in the app goes through [Motion.of]
/// so the OS reduce-motion setting zeroes durations everywhere.
class Motion {
  Motion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeOutCubic;

  /// True when the platform asks for reduced / disabled animations.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], or zero when animations are disabled.
  static Duration of(BuildContext context, [Duration d = medium]) =>
      reduced(context) ? Duration.zero : d;
}
