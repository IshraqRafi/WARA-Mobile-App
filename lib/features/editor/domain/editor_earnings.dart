import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../projects/domain/project_provider.dart';

/// Editor earnings from payout data only (never client price).
/// Earned = approved payouts, dated by approvedAt (legacy: claimedAt).
/// Pending = claimed or submitted payouts, dated by claimedAt.
class EditorEarnings {
  final int thisMonth;
  final int pending;
  /// Oldest first, [months] long, the last entry is the current month.
  final List<double> earnedSeries;
  final List<double> pendingSeries;
  const EditorEarnings(this.thisMonth, this.pending, this.earnedSeries, this.pendingSeries);

  static const months = 6;

  factory EditorEarnings.of(Iterable<ProjectItem> projects, String? uid, {DateTime? now}) {
    final n = now ?? DateTime.now();
    int idx(DateTime? d) {
      if (d == null) return -1;
      final back = (n.year - d.year) * 12 + n.month - d.month;
      return back < 0 || back >= months ? -1 : months - 1 - back;
    }

    final earned = List<double>.filled(months, 0);
    final pend = List<double>.filled(months, 0);
    var pending = 0.0;
    for (final p in projects) {
      if (!isClaimedBy(p, uid)) continue;
      if (p.status == ProjectStatus.approved) {
        final i = idx(p.approvedAt ?? p.claimedAt);
        if (i >= 0) earned[i] += p.editorPayout;
      } else if (p.status == ProjectStatus.claimed || p.status == ProjectStatus.submitted) {
        pending += p.editorPayout;
        final i = idx(p.claimedAt);
        pend[i >= 0 ? i : months - 1] += p.editorPayout;
      }
    }
    return EditorEarnings(earned.last.round(), pending.round(), earned, pend);
  }
}

final editorEarningsProvider = Provider<EditorEarnings>(
  (ref) => EditorEarnings.of(ref.watch(projectsProvider), ref.watch(currentUserIdProvider)),
);
