import 'package:flutter/material.dart';
import '../../../../shared/widgets/availability_badge.dart';
import '../../../../shared/motion/motion.dart';
import '../../../../shared/widgets/wara_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_project_card.dart';
import '../../../../shared/widgets/wara_section_header.dart';
import '../../../../shared/widgets/wara_stat_strip.dart';
import '../../../../shared/widgets/wara_status_chip.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../projects/domain/project_provider.dart';
import '../../../notifications/presentation/widgets/notification_center_modal.dart';
import '../widgets/rate_editor_dialog.dart';

/// Index of the active stat filter on the workflow screen (null = all).
final _workflowFilterProvider = StateProvider.autoDispose<int?>((ref) => null);

final List<bool Function(ProjectItem)> _filterTests = [
  (p) => p.status == ProjectStatus.open,
  (p) => p.status == ProjectStatus.claimed,
  (p) => p.status == ProjectStatus.submitted,
  (p) => p.isOverdue,
];

/// Filtered list, recomputed only when projects or the filter change.
final _visibleProjectsProvider = Provider.autoDispose<List<ProjectItem>>((ref) {
  final projects = ref.watch(projectsProvider);
  final filter = ref.watch(_workflowFilterProvider);
  return filter == null ? projects : projects.where(_filterTests[filter]).toList(growable: false);
});

class ManagerWorkflowScreen extends ConsumerWidget {
  const ManagerWorkflowScreen({super.key});

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, ProjectItem project) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.border),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colors.error, size: 24),
            const SizedBox(width: 10),
            Text(
              'Delete Project Offer?',
              style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete "${project.title}"?',
              style: TextStyle(color: colors.text, fontSize: 13, height: 1.4),
            ),
            if (project.claimedByEditorName != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.errorTint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.error.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: colors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Assigned to ${project.claimedByEditorName}. Deleting removes it from their workspace.',
                        style: TextStyle(color: colors.error, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'This action will permanently remove the offer from Cloud Firestore across all devices and cannot be undone.',
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.muted, fontSize: 14)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(projectsProvider.notifier).deleteProject(project.id);
              Navigator.pop(ctx);
              WaraToast.show(context, message: 'Project deleted', icon: Icons.delete_forever_rounded);
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
            label: const Text(
              'Delete Permanently',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditOfferModal(BuildContext context, WidgetRef ref, ProjectItem project) {
    final colors = context.colors;
    if (project.status != ProjectStatus.open) {
      // Offer is claimed or locked
      final payoutCtrl = TextEditingController(text: '৳${project.editorPayout.toInt()}');
      final deadlineCtrl = TextEditingController(text: project.deadlineStr);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: colors.card,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.lock_rounded, color: colors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        project.title,
                        style: TextStyle(color: colors.text, fontSize: 17, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: colors.muted, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Claimed by ${project.claimedByEditorName ?? 'an editor'}. Payout and deadline are locked.',
                          style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment / Payout',
                            style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: payoutCtrl,
                            readOnly: true,
                            style: TextStyle(color: colors.primary, fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(fillColor: colors.surface, filled: true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Real-Time Deadline',
                            style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: deadlineCtrl,
                            readOnly: true,
                            style: TextStyle(color: colors.text, fontSize: 14),
                            decoration: InputDecoration(fillColor: colors.surface, filled: true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showDeleteConfirmation(context, ref, project);
                        },
                        icon: Icon(Icons.delete_outline_rounded, size: 16, color: colors.error),
                        label: Text(
                          'Delete Offer',
                          style: TextStyle(color: colors.error, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(color: colors.onPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // Offer is OPEN and can be edited!
    final titleCtrl = TextEditingController(text: project.title);
    final payoutCtrl = TextEditingController(text: project.editorPayout.toInt().toString());
    final knownPrice = clientPriceOf(project, ref.read(projectFinanceProvider).valueOrNull ?? const {});
    final clientPriceCtrl = TextEditingController(text: knownPrice?.toInt().toString() ?? '');
    final daysLeft = (project.deadlineHoursLeft / 24).ceil().clamp(1, 90);
    final deadlineCtrl = TextEditingController(text: daysLeft.toString());
    final descCtrl = TextEditingController(text: project.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: colors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Edit project',
                    style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(project.clientName, style: TextStyle(color: colors.muted, fontSize: 12)),
              const SizedBox(height: 20),

              Text(
                'Project Title',
                style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: colors.text, fontSize: 14),
                decoration: InputDecoration(fillColor: colors.surface, filled: true),
              ),
              const SizedBox(height: 14),

              _PricingFields(clientPriceCtrl: clientPriceCtrl, payoutCtrl: payoutCtrl),
              const SizedBox(height: 14),
              _NumberStepperField(
                controller: deadlineCtrl,
                label: 'Deadline (Days)',
                hintText: 'e.g. 5',
                step: 1.0,
                isCurrency: false,
                minVal: 1,
              ),
              const SizedBox(height: 14),

              Text(
                'Project Brief & Instructions',
                style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                style: TextStyle(color: colors.text, fontSize: 13),
                decoration: InputDecoration(fillColor: colors.surface, filled: true),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final ok = ref
                        .read(projectsProvider.notifier)
                        .updateOpenProject(
                          projectId: project.id,
                          title: titleCtrl.text.trim(),
                          editorPayout: double.tryParse(payoutCtrl.text) ?? project.editorPayout,
                          deadlineDays: int.tryParse(deadlineCtrl.text) ?? daysLeft,
                          description: descCtrl.text.trim(),
                          clientPrice: double.tryParse(clientPriceCtrl.text),
                          updatedBy: ref.read(authProvider).user?.id,
                        );

                    Navigator.pop(ctx);
                    if (ok) {
                      WaraToast.show(context, message: 'Project updated', icon: Icons.check_circle_rounded);
                    }
                  },
                  icon: Icon(Icons.save_rounded, size: 16, color: colors.onPrimary),
                  label: Text(
                    'Save Changes to Offer',
                    style: TextStyle(color: colors.onPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showDeleteConfirmation(context, ref, project);
                  },
                  icon: Icon(Icons.delete_outline_rounded, size: 16, color: colors.error),
                  label: Text(
                    'Delete Project Offer',
                    style: TextStyle(color: colors.error, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreate(BuildContext from) {
    Haptics.light();
    showModalBottomSheet<void>(
      context: from,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      sheetAnimationStyle: Motion.reduced(from)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: Duration(milliseconds: 380),
              reverseDuration: Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            ),
      builder: (ctx) => _CreateProjectSheet(toastContext: from),
    );
  }

  void _showAssignModal(BuildContext context, WidgetRef ref, ProjectItem project) {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Assign Project to Editor',
              style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(project.title, style: TextStyle(color: colors.muted, fontSize: 12)),
            const SizedBox(height: 20),

            Consumer(
  builder: (context, ref, _) {
  final snapshot = asSnapshot(ref.watch(editorsProvider(ref.read(authProvider).user?.agencyId)));
                final cloudEditors = snapshot.data ?? [];

                // Filter complete profiles or combine with fallback
                final activeEditors = cloudEditors
                    .where((e) => e['name'] != null && (e['name'] as String).isNotEmpty)
                    .toList();

                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (activeEditors.isEmpty) {
                  final joinKey = ref.read(authProvider).user?.agencyJoinKey ?? '';
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.group_add_rounded, color: colors.muted, size: 28),
                        const SizedBox(height: 10),
                        Text(
                          'No editors yet',
                          style: TextStyle(color: colors.text, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          joinKey.isEmpty
                              ? 'Invite editors with your agency join key from Settings.'
                              : 'Share your join key $joinKey with editors. They appear here once they finish profile setup.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    for (int i = 0; i < activeEditors.length; i++) ...[
                      if (i > 0) Divider(color: colors.border),
                      ListTile(
                        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                        onTap: () {
                          final eId = activeEditors[i]['uid'] as String;
                          final eName = activeEditors[i]['name'] as String? ?? 'Editor';
                          ref.read(projectsProvider.notifier).assignProject(project.id, eId, eName);
                          Navigator.pop(ctx);
                          WaraToast.show(ctx, message: 'Assigned project to $eName.', icon: Icons.person_add_rounded);
                        },
                        leading: WaraAvatar(
                          name: activeEditors[i]['name'] as String?,
                          photoUrl: activeEditors[i]['photoUrl'] as String?,
                          radius: 18,
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                activeEditors[i]['name'] as String? ?? 'Editor',
                                style: TextStyle(color: colors.text, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AvailabilityBadge(activeEditors[i]['availability']),
                          ],
                        ),
                        subtitle: Text(
                          '${activeEditors[i]['specialization'] ?? 'Video Editor'} • Skills: ${(activeEditors[i]['skills'] as List?)?.join(', ') ?? 'Editing'}',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.muted, size: 14),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showIncreasePayoutModal(BuildContext context, WidgetRef ref, ProjectItem project) {
    final colors = context.colors;
    final payoutCtrl = TextEditingController(text: (project.editorPayout + 300).toInt().toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.trending_up_rounded, color: colors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Re-list & Increase Editor Payout',
                  style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Project: ${project.title}', style: TextStyle(color: colors.muted, fontSize: 12)),
            const SizedBox(height: 20),

            _NumberStepperField(
              controller: payoutCtrl,
              label: r'New Increased Editor Payout (৳)',
              hintText: '0৳',
              step: 50.0,
              isCurrency: true,
              minVal: 50,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final newPayout = double.tryParse(payoutCtrl.text) ?? (project.editorPayout + 300);
                  ref.read(projectsProvider.notifier).relistOverdueProject(project.id, increasedPayout: newPayout);
                  Navigator.pop(ctx);
                  WaraToast.show(context, message: 'Re-listed at ৳$newPayout', icon: Icons.bolt_rounded);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Re-list to Pool with New Payout',
                  style: TextStyle(color: colors.onPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _cardActions(BuildContext context, WidgetRef ref, ProjectItem project) {
    if (project.isOverdue) {
      return [
        ElevatedButton.icon(
          onPressed: () => _showIncreasePayoutModal(context, ref, project),
          style: waraCompactButton(),
          icon: const Icon(Icons.bolt_rounded, size: 18),
          label: const Text('Re-list & increase payout'),
        ),
      ];
    }
    switch (project.status) {
      case ProjectStatus.submitted:
        return [
          OutlinedButton(
            onPressed: () {
              ref
                  .read(projectsProvider.notifier)
                  .requestRevision(project.id, 'Please adjust sound levels and speed ramp transition.');
              WaraToast.show(context, message: 'Revision requested', icon: Icons.edit_note_rounded);
            },
            style: waraCompactButton(),
            child: const Text('Revision'),
          ),
          ElevatedButton(
            onPressed: () {
              if (project.claimedByEditorId != null) {
                showRateEditorSheet(
                  context: context,
                  ref: ref,
                  editorId: project.claimedByEditorId!,
                  editorName: project.claimedByEditorName ?? 'Editor',
                  projectId: project.id,
                  projectTitle: project.title,
                  isProjectApproval: true,
                );
              } else {
                ref.read(projectsProvider.notifier).approveProject(project.id);
                Celebration.sparkle(context);
                WaraToast.show(context, message: 'Approved', icon: Icons.check_circle_rounded);
              }
            },
            style: waraCompactButton(),
            child: const Text('Approve & pay'),
          ),
        ];
      case ProjectStatus.open:
        return [
          OutlinedButton.icon(
            onPressed: () => _showEditOfferModal(context, ref, project),
            style: waraCompactButton(),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
          ElevatedButton.icon(
            onPressed: () => _showAssignModal(context, ref, project),
            style: waraCompactButton(),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Assign'),
          ),
        ];
      default:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final projects = ref.watch(projectsProvider);
    final projectsError = ref.watch(projectsErrorProvider);
    if (projectsError != null && projects.isEmpty) {
      return ProjectsLoadError(error: projectsError);
    }

    final margin = AppSpacing.screenMargin(context);
    final counts = ref.watch(projectCountsProvider);
    final filter = ref.watch(_workflowFilterProvider);
    final visible = ref.watch(_visibleProjectsProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        bottom: false,
        child: WaraRefresh(
                        onRefresh: () => ref.read(projectsProvider.notifier).refresh(),
                        child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            CollapsingHeader(
              title: 'Workflow',
              subtitle: ref.watch(authProvider.select((s) => s.user?.agencyName)),
              trailing: const NotificationBellButton(),
              background: colors.bg,
              divider: colors.border,
              padding: EdgeInsets.symmetric(horizontal: margin),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(margin, 0, margin, 0),
              sliver: SliverList.list(
                children: [
                  const SizedBox(height: AppSpacing.md),
                  WaraStatStrip(
                    stats: [
                      WaraStat(label: 'Open', value: counts.open, tone: WaraTone.info),
                      WaraStat(label: 'Active', value: counts.claimed, tone: WaraTone.warning),
                      WaraStat(label: 'Review', value: counts.submitted, tone: WaraTone.success),
                      WaraStat(label: 'Overdue', value: counts.overdue, tone: WaraTone.error),
                    ],
                    selected: filter,
                    onSelect: (i) => ref.read(_workflowFilterProvider.notifier).state = i,
                  ),
                  WaraSectionHeader(
                    title: 'Projects',
                    subtitle: filter == null ? null : '${visible.length} of ${projects.length}',
                  ),
                ],
              ),
            ),
            if (visible.isEmpty && filter == null && !ref.watch(projectsLoadedProvider))
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: margin),
                // One shimmer controller/shader for all skeleton rows.
                sliver: const SliverToBoxAdapter(
                  child: Shimmer(
                    child: Column(children: [ProjectCardSkeleton(), ProjectCardSkeleton(), ProjectCardSkeleton(), ProjectCardSkeleton()]),
                  ),
                ),
              )
            else if (visible.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: filter != null
                    ? WaraEmptyState(
                        icon: Icons.filter_alt_off_rounded,
                        title: 'No matches',
                        actionLabel: 'Clear filter',
                        actionIcon: Icons.close_rounded,
                        onAction: () => ref.read(_workflowFilterProvider.notifier).state = null,
                      )
                    : WaraEmptyState(
                        icon: Icons.post_add_rounded,
                        title: 'No projects',
                        actionLabel: 'New project',
                        onAction: () => _openCreate(context),
                      ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(margin, 0, margin, AppSpacing.bottomInset(context, extra: 88)),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final project = visible[index];
                    return StaggerIn(
                      key: ValueKey(project.id),
                      screen: 'workflow',
                      index: index,
                      child: WaraProjectCard(
                        project: project,
                        listId: 'workflow',
                        showAssignee: true,
                        actions: _cardActions(context, ref, project),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
                      ),
      ),
      floatingActionButton: Builder(builder: (fabCtx) => Pressable(child: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => _openCreate(fabCtx),
        backgroundColor: colors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New project'),
      ))),
    );
  }
}

/// Client price (manager-only, never on the project doc) + editor payout,
/// with a live margin line. Payout above the price warns but never blocks.
class _PricingFields extends StatelessWidget {
  final TextEditingController clientPriceCtrl;
  final TextEditingController payoutCtrl;
  const _PricingFields({required this.clientPriceCtrl, required this.payoutCtrl});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberStepperField(
                controller: clientPriceCtrl,
                label: r'Client price (৳)',
                hintText: '0৳',
                step: 100.0,
                isCurrency: true,
                minVal: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _NumberStepperField(
                controller: payoutCtrl,
                label: r'Editor payout (৳)',
                hintText: '0৳',
                step: 50.0,
                isCurrency: true,
                minVal: 50,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: Listenable.merge([clientPriceCtrl, payoutCtrl]),
          builder: (context, _) {
            final price = parseAmount(clientPriceCtrl.text);
            final payout = parseAmount(payoutCtrl.text) ?? 0;
            final m = projectMargin(price, payout);
            if (m == null) {
              return Text('Margin —', key: const ValueKey('margin-line'), style: TextStyle(color: colors.muted, fontSize: 12));
            }
            final negative = m.amount < 0;
            return Row(
              key: const ValueKey('margin-line'),
              children: [
                Icon(negative ? Icons.warning_amber_rounded : Icons.trending_up_rounded,
                    size: 16, color: negative ? colors.warning : colors.success),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    negative
                        ? 'Payout exceeds client price by ৳${(-m.amount).toInt()}'
                        : 'Margin ৳${m.amount.toInt()} · ${m.percent.toStringAsFixed(0)}%',
                    style: TextStyle(color: negative ? colors.warning : colors.success, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Parses "1,400", "৳1400" or "1400" into a number; null when empty.
double? parseAmount(String raw) {
  final clean = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  return clean.isEmpty ? null : double.tryParse(clean);
}

class _NumberStepperField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final double step;
  final bool isCurrency;
  final int minVal;

  const _NumberStepperField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.step = 1.0,
    this.isCurrency = false,
    this.minVal = 1,
  });

  void _increment() {
    final current = double.tryParse(controller.text) ?? 0.0;
    final updated = (current + step).roundToDouble();
    controller.text = updated.toInt().toString();
  }

  void _decrement() {
    final current = double.tryParse(controller.text) ?? 0.0;
    final updated = (current - step).clamp(minVal.toDouble(), 999999.0).roundToDouble();
    controller.text = updated.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: isCurrency ? FontWeight.bold : FontWeight.normal,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                    fillColor: Colors.transparent,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _increment,
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Icon(Icons.arrow_drop_up_rounded, color: colors.primary, size: 20),
                    ),
                  ),
                  InkWell(
                    onTap: _decrement,
                    borderRadius: const BorderRadius.only(bottomRight: Radius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      child: Icon(Icons.arrow_drop_down_rounded, color: colors.muted, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Create flow as a draggable sheet: opens at 60%, drags up to 92%, snaps.
/// Owns and disposes its text controllers.
class _CreateProjectSheet extends ConsumerStatefulWidget {
  final BuildContext? toastContext;
  const _CreateProjectSheet({this.toastContext});

  @override
  ConsumerState<_CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends ConsumerState<_CreateProjectSheet> {
  final _sheet = DraggableScrollableController();

  /// Confetti once per agency, ever (flag stored on device).
  static Future<void> _celebrateFirst(BuildContext host, String? agencyId) async {
    if (agencyId == null || agencyId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final key = FirstProjectFlag.key(agencyId);
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);
    if (host.mounted) Celebration.confetti(host);
  }

  final titleCtrl = TextEditingController();
  final clientCtrl = TextEditingController();
  final payoutCtrl = TextEditingController();
  final clientPriceCtrl = TextEditingController();
  final deadlineCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  @override
  void dispose() {
    titleCtrl.dispose();
    clientCtrl.dispose();
    payoutCtrl.dispose();
    clientPriceCtrl.dispose();
    deadlineCtrl.dispose();
    descCtrl.dispose();
    _sheet.dispose();
    super.dispose();
  }

  /// Typing in a field near the bottom: grow the sheet so it stays visible.
  void _expand() {
    if (!_sheet.isAttached || _sheet.size >= 0.9) return;
    _sheet.animateTo(0.92, duration: Motion.of(context, const Duration(milliseconds: 300)), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: DraggableScrollableSheet(
        controller: _sheet,
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.6],
        snapAnimationDuration: const Duration(milliseconds: 280),
        builder: (context, scroll) => DecoratedBox(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: colors.border)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, -4))],
          ),
          child: ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(24, 10, 24, 24 + (keyboard > 0 ? 0 : MediaQuery.paddingOf(context).bottom)),
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: colors.muted.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'New project',
                      style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close_rounded, color: colors.muted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                'Project Title',
                style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: colors.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                  fillColor: colors.surface,
                  filled: true,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Client',
                style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                key: const ValueKey('create_client'),
                controller: clientCtrl,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: colors.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Client name',
                  hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                  fillColor: colors.surface,
                  filled: true,
                ),
              ),
              const SizedBox(height: 14),

              _PricingFields(clientPriceCtrl: clientPriceCtrl, payoutCtrl: payoutCtrl),
              const SizedBox(height: 14),
              _NumberStepperField(
                controller: deadlineCtrl,
                label: 'Deadline (Days)',
                hintText: 'e.g. 5',
                step: 1.0,
                isCurrency: false,
                minVal: 1,
              ),
              const SizedBox(height: 14),

              Text(
                'Project Brief & Instructions',
                style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                onTap: _expand,
                style: TextStyle(color: colors.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Brief',
                  hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                  fillColor: colors.surface,
                  filled: true,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final firstEver = ref.read(projectsLoadedProvider) && ref.read(projectsProvider).isEmpty;
                    final payout = double.tryParse(payoutCtrl.text) ?? 1400;
                    ref
                        .read(projectsProvider.notifier)
                        .createNewProject(
                          title: titleCtrl.text.trim(),
                          clientName: clientCtrl.text.trim().isEmpty ? 'Direct client' : clientCtrl.text.trim(),
                          clientPrice: double.tryParse(clientPriceCtrl.text),
                          createdBy: ref.read(authProvider).user?.id,
                          editorPayout: payout,
                          deadlineDays: int.tryParse(deadlineCtrl.text) ?? 5,
                          description: descCtrl.text.trim(),
                          skills: ['Video Editing', 'Color Grading', 'Sound Design'],
                        );
                    Navigator.pop(context);
                    final host = widget.toastContext ?? context;
                    WaraToast.show(host, message: 'Project published', icon: Icons.rocket_launch_rounded);
                    if (firstEver) _celebrateFirst(host, ref.read(authProvider).user?.agencyId);
                  },
                  icon: Icon(Icons.send_rounded, size: 16, color: colors.onPrimary),
                  label: Text(
                    'Publish Offer to Pool',
                    style: TextStyle(color: colors.onPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
