import '../../../../shared/motion/motion.dart';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/wara_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../../shared/widgets/wara_project_card.dart';
import '../../../notifications/presentation/widgets/notification_center_modal.dart';
import '../../../projects/domain/project_provider.dart';
import '../widgets/rate_editor_dialog.dart';

class ManagerPendingScreen extends ConsumerStatefulWidget {
  const ManagerPendingScreen({super.key});

  @override
  ConsumerState<ManagerPendingScreen> createState() => _ManagerPendingScreenState();
}

class _ManagerPendingScreenState extends ConsumerState<ManagerPendingScreen> {
  String _sortBy = 'time'; // 'time' or 'money'

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final projects = ref.watch(projectsProvider);
    final projectsError = ref.watch(projectsErrorProvider);
    if (projectsError != null && projects.isEmpty) {
      return ProjectsLoadError(error: projectsError);
    }

    // Filter pending works (claimed or submitted)
    final pendingProjects = projects.where((p) => p.status != ProjectStatus.approved).toList();

    // Sort based on selection
    if (_sortBy == 'time') {
      pendingProjects.sort((a, b) => a.deadlineHoursLeft.compareTo(b.deadlineHoursLeft));
    } else {
      pendingProjects.sort((a, b) => b.clientBudget.compareTo(a.clientBudget));
    }

    final margin = AppSpacing.screenMargin(context);
    final text = Theme.of(context).textTheme;
    final pipelineValue = pendingProjects.fold<double>(0, (sum, p) => sum + p.clientBudget);
    final toReview = pendingProjects.where((p) => p.status == ProjectStatus.submitted).length;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(margin, AppSpacing.lg, margin, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const WaraLogo(),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text('Pending', style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const NotificationBellButton(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('PIPELINE VALUE', style: text.labelMedium?.copyWith(letterSpacing: 0.8)),
                  const SizedBox(height: AppSpacing.xs),
                  RollingCounter(prefix: '৳', value: pipelineValue.toInt(), style: text.displaySmall?.copyWith(fontWeight: FontWeight.w700, color: colors.text)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('${pendingProjects.length} open deliverables · $toReview to review', style: text.bodyMedium?.copyWith(color: colors.muted)),
                  const SizedBox(height: AppSpacing.lg),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'time', icon: Icon(Icons.timer_outlined, size: 18), label: Text('Deadline')),
                      ButtonSegment(value: 'money', icon: Icon(Icons.account_balance_wallet_outlined, size: 18), label: Text('Value')),
                    ],
                    selected: {_sortBy},
                    onSelectionChanged: (v) => setState(() => _sortBy = v.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: pendingProjects.isEmpty
                  ? const WaraEmptyState(
                      icon: Icons.verified_outlined,
                      title: 'Nothing pending',
                    )
                  : WaraRefresh(
                        onRefresh: () => ref.read(projectsProvider.notifier).refresh(),
                        child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(margin, 0, margin, AppSpacing.bottomInset(context)),
                      itemCount: pendingProjects.length,
                      itemBuilder: (context, index) {
                        final item = pendingProjects[index];
                        return WaraProjectCard(
                          project: item,
                          listId: 'pending',
                          showAssignee: true,
                          amount: item.clientBudget,
                          payoutLabel: 'Client value',
                          actions: [
                            if (item.status == ProjectStatus.submitted)
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (item.claimedByEditorId != null) {
                                    showRateEditorSheet(
                                      context: context,
                                      ref: ref,
                                      editorId: item.claimedByEditorId!,
                                      editorName: item.claimedByEditorName ?? 'Editor',
                                      projectId: item.id,
                                      projectTitle: item.title,
                                      isProjectApproval: true,
                                    );
                                  } else {
                                    ref.read(projectsProvider.notifier).approveProject(item.id);
                                  }
                                },
                                style: waraCompactButton(),
                                icon: const Icon(Icons.star_rounded, size: 18),
                                label: const Text('Approve & rate'),
                              ),
                          ],
                        );
                      },
                    ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
