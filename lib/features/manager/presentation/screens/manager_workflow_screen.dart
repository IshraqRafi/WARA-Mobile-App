import 'package:flutter/material.dart';
import '../../../../shared/motion/motion.dart';
import '../../../../shared/widgets/wara_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_logo.dart';
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

              Row(
                children: [
                  Expanded(
                    child: _NumberStepperField(
                      controller: payoutCtrl,
                      label: r'Editor Payout (৳)',
                      hintText: '0৳',
                      step: 50.0,
                      isCurrency: true,
                      minVal: 50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberStepperField(
                      controller: deadlineCtrl,
                      label: 'Deadline (Days)',
                      hintText: 'e.g. 5',
                      step: 1.0,
                      isCurrency: false,
                      minVal: 1,
                    ),
                  ),
                ],
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

  void _showCreateOfferModal(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final titleCtrl = TextEditingController(text: '');
    final clientCtrl = TextEditingController(text: '');
    final payoutCtrl = TextEditingController(text: '');
    final deadlineCtrl = TextEditingController(text: '');
    final descCtrl = TextEditingController(text: '');

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
                  Icon(Icons.add_circle_outline_rounded, color: colors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'New project',
                    style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Project Title',
                style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: colors.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                  fillColor: colors.surface,
                  filled: true,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _NumberStepperField(
                      controller: payoutCtrl,
                      label: r'Editor Payout (৳)',
                      hintText: '0৳',
                      step: 50.0,
                      isCurrency: true,
                      minVal: 50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NumberStepperField(
                      controller: deadlineCtrl,
                      label: 'Deadline (Days)',
                      hintText: 'e.g. 5',
                      step: 1.0,
                      isCurrency: false,
                      minVal: 1,
                    ),
                  ),
                ],
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
                    final payout = double.tryParse(payoutCtrl.text) ?? 1400;
                    ref
                        .read(projectsProvider.notifier)
                        .createNewProject(
                          title: titleCtrl.text.trim(),
                          clientName: clientCtrl.text.trim().isEmpty ? 'LuxeLiving Apparel' : clientCtrl.text.trim(),
                          clientBudget: payout * 2.2,
                          editorPayout: payout,
                          deadlineDays: int.tryParse(deadlineCtrl.text) ?? 5,
                          description: descCtrl.text.trim(),
                          skills: ['Video Editing', 'Color Grading', 'Sound Design'],
                        );
                    Navigator.pop(ctx);
                    WaraToast.show(context, message: 'Project published', icon: Icons.rocket_launch_rounded);
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
                            Text(
                              activeEditors[i]['name'] as String? ?? 'Editor',
                              style: TextStyle(color: colors.text, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colors.successTint,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Online',
                                style: TextStyle(color: colors.success, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
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
    final text = Theme.of(context).textTheme;
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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(margin, AppSpacing.lg, margin, 0),
              sliver: SliverList.list(
                children: [
                  // Header with logo
                  Row(
                    children: [
                      const WaraLogo(),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'wara.io',
                              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const NotificationBellButton(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
                        onAction: () => _showCreateOfferModal(context, ref),
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
      floatingActionButton: Pressable(child: FloatingActionButton.extended(
        onPressed: () => _showCreateOfferModal(context, ref),
        backgroundColor: colors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New project'),
      )),
    );
  }
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
