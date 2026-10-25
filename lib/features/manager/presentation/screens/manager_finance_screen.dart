import 'package:flutter/material.dart';
import '../../../payments/domain/payout.dart';
import '../../../payments/presentation/payout_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_error_state.dart';
import '../../../../shared/widgets/wara_status_chip.dart';
import '../../../projects/domain/project_provider.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../notifications/presentation/widgets/notification_center_modal.dart';
import '../../../../shared/widgets/wara_page_header.dart';

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

    // ── Live metrics from the manager-only client prices ─────────────────
    final finance = ref.watch(projectFinanceProvider).valueOrNull ?? const <String, ProjectFinance>{};
    final s = FinanceSummary.of(projects, finance);
    final totalPipelineVolume = s.pipeline;
    final claimedOrDoneProjects = projects.where((p) => p.status != ProjectStatus.open).toList();

    final m = AppSpacing.screenMargin(context);
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(m, AppSpacing.lg, m, AppSpacing.bottomInset(context)),
          children: [
            WaraPageHeader(
              title: 'Finance',
              subtitle: ref.watch(authProvider.select((s) => s.user?.agencyName)),
              trailing: const NotificationBellButton(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Hero total ──────────────────────────────────────────────
            Text('Pipeline', style: text.labelMedium?.copyWith(color: colors.muted)),
            const SizedBox(height: AppSpacing.xs),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: AnimatedCount(
                key: const ValueKey('finance_pipeline'),
                format: takaFormat,
                value: totalPipelineVolume,
                style: text.displaySmall?.copyWith(color: colors.text, fontWeight: FontWeight.w700, letterSpacing: -0.5),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Secondary metrics strip ─────────────────────────────────
            FinanceMetricStrip(metrics: [
              FinanceMetric('Revenue', s.revenue == null ? '—' : '৳${formatTaka(s.revenue!)}', amount: s.revenue),
              FinanceMetric('Paid', '৳${formatTaka(s.paid)}', amount: s.paid),
              FinanceMetric('Committed', '৳${formatTaka(s.committed)}', amount: s.committed, color: colors.primary),
              FinanceMetric('Margin', s.marginPercent == null ? '—' : '${s.marginPercent!.toStringAsFixed(0)}%',
                  amount: s.marginPercent, format: (v) => '${v.toStringAsFixed(0)}%', color: colors.success),
            ]),
            const SizedBox(height: AppSpacing.xl),

            // ── Ledger ──────────────────────────────────────────────────
            Text('Ledger', style: text.labelMedium?.copyWith(color: colors.muted)),
            const SizedBox(height: AppSpacing.sm),
            if (claimedOrDoneProjects.isEmpty && !ref.watch(projectsLoadedProvider))
              const CardSkeletonColumn(height: 56)
            else if (claimedOrDoneProjects.isEmpty)
              const WaraEmptyState(compact: true, icon: Icons.receipt_long_outlined, title: 'No payouts')
            else
              for (final p in claimedOrDoneProjects) _LedgerRow(project: p),
          ],
        ),
      ),
    );
  }
}

/// Finance totals. Only projects with a known client price count toward
/// revenue and margin, so a missing price never fakes a margin.
class FinanceSummary {
  final double pipeline; // client value of all priced projects
  final double? revenue; // client value of approved, priced projects
  final double paid; // editor payouts on approved projects
  final double committed; // editor payouts on claimed/submitted/approved
  final double? marginPercent; // over priced, non-open projects
  const FinanceSummary(this.pipeline, this.revenue, this.paid, this.committed, this.marginPercent);

  factory FinanceSummary.of(List<ProjectItem> projects, Map<String, ProjectFinance> finance) {
    double pipeline = 0, revenue = 0, paid = 0, committed = 0, pricedValue = 0, pricedCuts = 0;
    var anyApprovedPriced = false;
    for (final p in projects) {
      final price = clientPriceOf(p, finance);
      if (price != null) pipeline += price;
      if (p.status == ProjectStatus.open) continue;
      committed += p.editorPayout;
      if (price != null) {
        pricedValue += price;
        pricedCuts += p.editorPayout;
      }
      if (p.status == ProjectStatus.approved) {
        paid += p.editorPayout;
        if (price != null) {
          revenue += price;
          anyApprovedPriced = true;
        }
      }
    }
    return FinanceSummary(pipeline, anyApprovedPriced ? revenue : null, paid, committed,
        pricedValue > 0 ? (pricedValue - pricedCuts) / pricedValue * 100 : null);
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

  /// When set, the value tweens to this number, formatted with [format]
  /// (taka by default).
  final num? amount;
  final String Function(num v) format;
  const FinanceMetric(this.label, this.value, {this.color, this.amount, this.format = takaFormat});
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
                      child: metrics[i].amount == null
                          ? Text(metrics[i].value,
                              maxLines: 1,
                              softWrap: false,
                              style: text.titleSmall?.copyWith(color: metrics[i].color ?? colors.text, fontWeight: FontWeight.w700))
                          : AnimatedCount(
                              key: ValueKey('metric_count_${metrics[i].label}'),
                              value: metrics[i].amount!,
                              format: metrics[i].format,
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

class _LedgerRow extends ConsumerWidget {
  final ProjectItem project;
  const _LedgerRow({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payout = ref.watch(payoutsProvider.select((v) => v.valueOrNull?[project.id]));
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
                if (payout != null) ...[const SizedBox(height: 2), PayoutMethodLine(record: payout)],
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
