import 'package:flutter/material.dart';
import '../../../../shared/widgets/wara_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../../shared/widgets/wara_project_card.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../projects/domain/project_provider.dart';

class ManagerFinanceScreen extends ConsumerWidget {
  const ManagerFinanceScreen({super.key});

  String _formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(authProvider).user;
    final projects = ref.watch(projectsProvider);
    final projectsError = ref.watch(projectsErrorProvider);
    if (projectsError != null && projects.isEmpty) {
      return Scaffold(
        backgroundColor: colors.bg,
        body: SafeArea(
          child: WaraErrorState(
            title: 'Couldn\'t load projects',
            message: friendlyErrorMessage(projectsError),
            onRetry: () => ref.read(projectsProvider.notifier).retry(),
          ),
        ),
      );
    }

    // ── Live Calculated Financial Metrics from Firestore ──────────────────
    final totalPipelineVolume = projects.fold<double>(0.0, (sum, p) => sum + p.clientBudget);
    final approvedProjects = projects.where((p) => p.status == ProjectStatus.approved).toList();
    final approvedRevenue = approvedProjects.fold<double>(0.0, (sum, p) => sum + p.clientBudget);

    final claimedOrDoneProjects = projects.where((p) => p.status != ProjectStatus.open).toList();
    final totalEditorPayouts = claimedOrDoneProjects.fold<double>(0.0, (sum, p) => sum + p.editorPayout);
    final approvedEditorPayouts = approvedProjects.fold<double>(0.0, (sum, p) => sum + p.editorPayout);
    final inProductionPayouts = projects
        .where((p) => p.status == ProjectStatus.claimed || p.status == ProjectStatus.submitted)
        .fold<double>(0.0, (sum, p) => sum + p.editorPayout);

    final netMargin = totalPipelineVolume - totalEditorPayouts;
    final marginPercent = totalPipelineVolume > 0 ? ((netMargin / totalPipelineVolume) * 100).toInt() : 0;

    // Aggregate real editor payouts from claimed/approved projects
    final editorEarningsMap = <String, ({double earned, double inProduction, int completed, int active})>{};
    for (final p in projects) {
      final edName = p.claimedByEditorName?.trim();
      if (edName != null && edName.isNotEmpty) {
        final current = editorEarningsMap[edName] ?? (earned: 0.0, inProduction: 0.0, completed: 0, active: 0);
        if (p.status == ProjectStatus.approved) {
          editorEarningsMap[edName] = (
            earned: current.earned + p.editorPayout,
            inProduction: current.inProduction,
            completed: current.completed + 1,
            active: current.active,
          );
        } else {
          editorEarningsMap[edName] = (
            earned: current.earned,
            inProduction: current.inProduction + p.editorPayout,
            completed: current.completed,
            active: current.active + 1,
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpacing.screenMargin(context), AppSpacing.lg, AppSpacing.screenMargin(context), AppSpacing.bottomInset(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              Row(
                children: [
                  const WaraLogo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Agency Project Finances', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          '${(user?.agencyName ?? '').isNotEmpty ? user!.agencyName : "Your agency"} • Live Production Ledger',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Primary Financial Pipeline Card ────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: colors.text.withValues(alpha: 0.03),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL PROJECT PIPELINE VALUE',
                          style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                        ),
                        Icon(Icons.account_balance_wallet_outlined, color: colors.primary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '৳${_formatCurrency(totalPipelineVolume)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(color: colors.text, fontWeight: FontWeight.w700, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 14),

                    // Net Margin Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up_rounded, color: colors.success, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Agency Net Margin: ৳${_formatCurrency(netMargin)} ($marginPercent%)',
                              style: TextStyle(color: colors.success, fontSize: 12, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sub-Metrics Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SETTLED REVENUE', style: TextStyle(color: colors.muted, fontSize: 10, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  '৳${_formatCurrency(approvedRevenue)}',
                                  style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                Text('${approvedProjects.length} approved cuts', style: TextStyle(color: colors.muted, fontSize: 10)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('COMMITTED PAYOUTS', style: TextStyle(color: colors.muted, fontSize: 10, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  '৳${_formatCurrency(totalEditorPayouts)}',
                                  style: TextStyle(color: colors.primary, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                Text('৳${_formatCurrency(approvedEditorPayouts)} settled • ৳${_formatCurrency(inProductionPayouts)} in escrow', style: TextStyle(color: colors.muted, fontSize: 9.5)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Project Financial Allocation Ledger ─────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROJECT FINANCIAL LEDGER',
                    style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                  ),
                  Text(
                    '${projects.length} Live Projects',
                    style: TextStyle(color: colors.muted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (projects.isEmpty)
                const WaraEmptyState(
                  compact: true,
                  icon: Icons.receipt_long_outlined,
                  title: 'No projects in the ledger',
                  message: 'Post project offers from the Workflow tab to track client budgets and editor payouts.',
                )
              else
                Column(
                  children: [
                    for (final p in projects)
                      WaraProjectCard(
                        project: p,
                        showAssignee: true,
                        descriptionMaxLines: 1,
                        amount: p.clientBudget,
                        payoutLabel: 'Client value',
                        actions: [
                          Text('Editor ৳${p.editorPayout.toInt()}', style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 28),

              // ── Active Editor Payouts Ledger ─────────────────────────────
              Text(
                'EDITOR PAYOUTS & DISBURSEMENTS',
                style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),

              if (editorEarningsMap.isEmpty)
                const WaraEmptyState(
                  compact: true,
                  icon: Icons.groups_outlined,
                  title: 'No editor payouts yet',
                  message: 'As editors claim and complete projects, their earnings and escrow balances appear here.',
                )
              else
                Column(
                  children: editorEarningsMap.entries.map((entry) {
                    final editorName = entry.key;
                    final stats = entry.value;
                    final totalEarnedAndActive = stats.earned + stats.inProduction;
                    final share = totalPipelineVolume > 0 ? (totalEarnedAndActive / totalPipelineVolume).clamp(0.0, 1.0) : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              WaraAvatar(
                                name: editorName,
                                radius: 18,
                                fontSize: 12,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      editorName,
                                      style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${stats.completed} Completed • ${stats.active} Active Cuts',
                                      style: TextStyle(color: colors.muted, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '৳${stats.earned.toInt()}',
                                    style: TextStyle(color: colors.primary, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  if (stats.inProduction > 0)
                                    Text(
                                      '+৳${stats.inProduction.toInt()} in escrow',
                                      style: TextStyle(color: colors.muted, fontSize: 10),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: share,
                              backgroundColor: colors.surface,
                              valueColor: AlwaysStoppedAnimation(colors.primary),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
