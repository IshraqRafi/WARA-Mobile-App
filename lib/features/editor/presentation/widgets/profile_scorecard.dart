import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../projects/domain/project_provider.dart' show isClaimedBy;

class EditorScore {
  /// 0..1, null when nothing is approved yet.
  final double? onTime;
  final int done;
  const EditorScore(this.onTime, this.done);

  factory EditorScore.of(Iterable<ProjectItem> projects, String? uid) {
    final approved = projects.where((p) => p.status == ProjectStatus.approved && isClaimedBy(p, uid)).toList();
    if (approved.isEmpty) return const EditorScore(null, 0);
    return EditorScore(approved.where((p) => !p.submittedLate).length / approved.length, approved.length);
  }
}

/// Three figures: on-time rate, average rating, projects done.
class ProfileScorecard extends StatelessWidget {
  final EditorScore score;
  final double rating;
  final int ratingCount;
  const ProfileScorecard({super.key, required this.score, required this.rating, required this.ratingCount});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = Theme.of(context).textTheme;
    Widget cell(String key, String value, String label) => Expanded(
          child: Column(children: [
            Text(value, key: ValueKey(key), style: t.titleLarge?.copyWith(color: c.text, fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()])),
            const SizedBox(height: 2),
            Text(label, style: t.labelSmall?.copyWith(color: c.muted)),
          ]),
        );
    Widget rule() => Container(width: 1, height: 28, color: c.border);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.border)),
      child: Row(children: [
        cell('score_ontime', score.onTime == null ? '—' : '${(score.onTime! * 100).round()}%', 'On time'),
        rule(),
        cell('score_rating', ratingCount == 0 ? '—' : rating.toStringAsFixed(1), 'Rating'),
        rule(),
        cell('score_done', '${score.done}', 'Done'),
      ]),
    );
  }
}
