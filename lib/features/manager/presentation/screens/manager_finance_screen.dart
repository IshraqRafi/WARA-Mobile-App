import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/rolling_counter.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_error_state.dart';
import '../../../../shared/widgets/wara_status_chip.dart';
import '../../../projects/domain/project_provider.dart';

class ManagerFinanceScreen extends ConsumerWidget {
  const ManagerFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final projects = ref.watch(projectsProvider);
    final projectsError = ref.watch(projectsErrorProvider);
    if (projectsError != null && projects.isEmpty) {
      return ProjectsLoadError(error: projectsError);
    }

    // ── Live metrics (unchanged calculations) ─────────────────────────────
    final totalPipelineVolume = projects.fold<double>(0.0, (sum, p) => sum + p.clientBudget);
    final approvedProjects = projects.where((p) => p.status == ProjectStatus.approved).toList();
    final approvedRevenue = approvedProjects.fold<double>(0.0, (sum, p) => sum + p.clientBudget);
    final claimedOrDoneProjects = projects.where((p) => p.status != ProjectStatus.open).toList();
    final totalEditorPayouts = claimedOrDoneProjects.fold<double>(0.0, (sum, p) => sum + p.editorPayout);
    final approvedEditorPayouts = approvedProjects.fold<double>(0.0, (sum, p) => sum + p.editorPayout);
    final netMargin = totalPipelineVolume - totalEditorPayouts;
    final marginPercent = totalPipelineVolume > 0 ? ((netMargin / totalPipelineVolume) * 100).toInt() : 0;

    final m = AppSpacing.screenMargin(context);
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(m, AppSpacing.lg, m, AppSpacing.bottomInset(context)),
          children: [
            Text('Finance', style: text.titleLarge?.copyWith(color: colors.text, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.lg),

            // ── Hero total ──────────────────────────────────────────────
            Text('Pipeline', style: text.labelMedium?.copyWith(color: colors.muted)),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: RollingCounter(
                prefix: '৳',
                grouped: true,
                value: totalPipelineVolume.toInt(),
                style: text.displaySmall?.copyWith(color: colors.text, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Secondary metrics strip ─────────────────────────────────
            FinanceMetricStrip(metrics: [
              FinanceMetric('Revenue', '৳${formatTaka(approvedRevenue)}'),
              FinanceMetric('Paid', '৳${formatTaka(approvedEditorPayouts)}'),
              FinanceMetric('Committed', '৳${formatTaka(totalEditorPayouts)}', color: colors.primary),
              FinanceMetric('Margin', '$marginPercent%', color: colors.success),
            ]),
            const SizedBox(height: AppSpacing.xl),

            // ── Ledger ──────────────────────────────────────────────────
            Text('Ledger', style: text.labelMedium?.copyWith(color: colors.muted)),
            const SizedBox(height: AppSpacing.sm),
            if (claimedOrDoneProjects.isEmpty)
              const WaraEmptyState(compact: true, icon: Icons.receipt_long_outlined, title: 'No payouts')
            else
              for (final p in claimedOrDoneProjects) _LedgerRow(project: p),
          ],
        ),
      ),
    );
  }
}

String formatTaka(double amount) => amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

String _shortDate(DateTime? d) {
  if (d == null) return '';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]}';
}

class FinanceMetric {
  final String label;
  final String value;
  final Color? color;
  const FinanceMetric(this.label, this.value, {this.color});
}

/// Single row of equal-height metric tiles. Labels and values never wrap.
class FinanceMetricStrip extends StatelessWidget {
  final List<FinanceMetric> metrics;
  const FinanceMetricStrip({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Container(
                key: ValueKey('metric-${metrics[i].label}'),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(metrics[i].label,
                          maxLines: 1, softWrap: false, style: text.labelSmall?.copyWith(color: colors.muted)),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(metrics[i].value,
                          maxLines: 1,
                          softWrap: false,
                          style: text.titleSmall?.copyWith(color: metrics[i].color ?? colors.text, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final ProjectItem project;
  const _LedgerRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final p = project;
    final (tone, statusLabel) = projectStatusTone(p);
    final sub = [p.claimedByEditorName ?? 'Unassigned', _shortDate(p.claimedAt)].where((s) => s.isNotEmpty).join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(color: c.card, borderRadius: AppRadius.brMd, border: Border.all(color: c.border)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(color: c.text, fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: c.muted)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('৳${formatTaka(p.editorPayout)}',
              maxLines: 1, style: text.titleSmall?.copyWith(color: c.text, fontWeight: FontWeight.w700)),
          const SizedBox(width: AppSpacing.sm),
          Tooltip(
            message: statusLabel,
            child: Semantics(
              label: statusLabel,
              child: Container(width: 8, height: 8, decoration: BoxDecoration(color: tone.fg(c), shape: BoxShape.circle)),
            ),
          ),
        ],
      ),
    );
  }
}
