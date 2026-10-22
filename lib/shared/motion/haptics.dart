import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';

/// One place for the app's haptic vocabulary, so feedback stays consistent
/// and subtle. Haptics are not motion, so reduce-motion does not mute them.
class Haptics {
  Haptics._();

  static void tick() => HapticFeedback.selectionClick();
  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  /// Payment / payout confirmed.
  static void success() => HapticFeedback.heavyImpact();

  /// Paired with every project status change: a light tick for routine
  /// moves, a firmer tap for the milestones (submitted, approved).
  static void statusChange(ProjectStatus to) {
    switch (to) {
      case ProjectStatus.approved:
      case ProjectStatus.submitted:
        HapticFeedback.mediumImpact();
      default:
        HapticFeedback.lightImpact();
    }
  }
}
