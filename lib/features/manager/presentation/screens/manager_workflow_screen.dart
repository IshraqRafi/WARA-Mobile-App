import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../projects/domain/project_provider.dart';
import '../../../notifications/presentation/widgets/notification_center_modal.dart';
import '../widgets/rate_editor_dialog.dart';

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
            Icon(Icons.warning_amber_rounded, color: colors.warningRed, size: 24),
            const SizedBox(width: 10),
            Text('Delete Project Offer?', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  color: colors.isDark ? Colors.black : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.warningRed.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: colors.warningRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Currently assigned to ${project.claimedByEditorName}. Deleting will remove it from their workspace.',
                        style: TextStyle(color: colors.warningRed, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'This action will permanently remove the offer from Cloud Firestore across all devices and cannot be undone.',
              style: TextStyle(color: colors.muted, fontSize: 11),
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
              WaraToast.show(
                context,
                message: '🗑️ Offer "${project.title}" permanently deleted.',
                icon: Icons.delete_forever_rounded,
              );
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
            label: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.warningRed,
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
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(2))),
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
                  decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: colors.muted, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This offer has been claimed by ${project.claimedByEditorName ?? 'an Editor'}. Variables (payout & deadline) cannot be modified after acceptance.',
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
                          Text('Payment / Payout', style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
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
                          Text('Real-Time Deadline', style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
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
                        icon: Icon(Icons.delete_outline_rounded, size: 16, color: colors.warningRed),
                        label: Text('Delete Offer', style: TextStyle(color: colors.warningRed, fontSize: 13, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: colors.warningRed.withValues(alpha: 0.5)),
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
                          foregroundColor: colors.isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Close', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
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
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: colors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text('Edit Open Project Variables', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Client: ${project.clientName} • Unclaimed Open Offer', style: TextStyle(color: colors.muted, fontSize: 12)),
              const SizedBox(height: 20),

              Text('Project Title', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
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

              Text('Project Brief & Instructions', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
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
                    final ok = ref.read(projectsProvider.notifier).updateOpenProject(
                          projectId: project.id,
                          title: titleCtrl.text.trim(),
                          editorPayout: double.tryParse(payoutCtrl.text) ?? project.editorPayout,
                          deadlineDays: int.tryParse(deadlineCtrl.text) ?? daysLeft,
                          description: descCtrl.text.trim(),
                        );

                    Navigator.pop(ctx);
                    if (ok) {
                      WaraToast.show(
                        context,
                        message: '✏️ Project offer variables updated successfully!',
                        icon: Icons.check_circle_rounded,
                      );
                    }
                  },
                  icon: Icon(Icons.save_rounded, size: 16, color: colors.isDark ? Colors.black : Colors.white),
                  label: Text('Save Changes to Offer', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
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
                  icon: Icon(Icons.delete_outline_rounded, size: 16, color: colors.warningRed),
                  label: Text('Delete Project Offer', style: TextStyle(color: colors.warningRed, fontSize: 13, fontWeight: FontWeight.bold)),
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
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: colors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text('Post New Project Offer to Editors', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Publish an offer to the Editor Marketplace Pool', style: TextStyle(color: colors.muted, fontSize: 12)),
              const SizedBox(height: 20),

              Text('Project Title', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: colors.text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter project title...',
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

              Text('Project Brief & Instructions', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                style: TextStyle(color: colors.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Enter project brief and instructions...',
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
                    ref.read(projectsProvider.notifier).createNewProject(
                          title: titleCtrl.text.trim(),
                          clientName: clientCtrl.text.trim().isEmpty ? 'LuxeLiving Apparel' : clientCtrl.text.trim(),
                          clientBudget: payout * 2.2,
                          editorPayout: payout,
                          deadlineDays: int.tryParse(deadlineCtrl.text) ?? 5,
                          description: descCtrl.text.trim(),
                          skills: ['Video Editing', 'Color Grading', 'Sound Design'],
                        );
                    Navigator.pop(ctx);
                    WaraToast.show(
                      context,
                      message: '🚀 New offer published! Now live in Editor Marketplace.',
                      icon: Icons.rocket_launch_rounded,
                    );
                  },
                  icon: Icon(Icons.send_rounded, size: 16, color: colors.isDark ? Colors.black : Colors.white),
                  label: Text('Publish Offer to Pool', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.isDark ? Colors.black : Colors.white,
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
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('Assign Project to Editor', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(project.title, style: TextStyle(color: colors.muted, fontSize: 12)),
            const SizedBox(height: 20),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.read(firestoreServiceProvider).streamEditors(),
              builder: (context, snapshot) {
                final cloudEditors = snapshot.data ?? [];

                // Filter complete profiles or combine with fallback
                final activeEditors = cloudEditors.where((e) => e['name'] != null && (e['name'] as String).isNotEmpty).toList();

                if (activeEditors.isEmpty) {
                  return Column(
                    children: [
                      ListTile(
                        onTap: () {
                          ref.read(projectsProvider.notifier).assignProject(project.id, 'editor_1', 'Walid Islam');
                          Navigator.pop(ctx);
                          WaraToast.show(ctx, message: 'Assigned project to Walid Islam.', icon: Icons.person_add_rounded);
                        },
                        leading: const WaraAvatar(name: 'Walid Islam', radius: 18),
                        title: Text('Walid Islam', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
                        subtitle: Text('Skills: Video Editing, Color Grading, Sound Design', style: TextStyle(color: colors.muted, fontSize: 11)),
                        trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.muted, size: 14),
                      ),
                      Divider(color: colors.border),
                      ListTile(
                        onTap: () {
                          ref.read(projectsProvider.notifier).assignProject(project.id, 'editor_2', 'Ishraq Rafi');
                          Navigator.pop(ctx);
                          WaraToast.show(ctx, message: 'Assigned project to Ishraq Rafi.', icon: Icons.person_add_rounded);
                        },
                        leading: const WaraAvatar(name: 'Ishraq Rafi', radius: 18),
                        title: Text('Ishraq Rafi', style: TextStyle(color: colors.text, fontWeight: FontWeight.bold)),
                        subtitle: Text('Skills: 3D Motion, VFX, Animation', style: TextStyle(color: colors.muted, fontSize: 11)),
                        trailing: Icon(Icons.arrow_forward_ios_rounded, color: colors.muted, size: 14),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: colors.muted, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'When new editors sign up and complete profile setup, they will appear here live.',
                                style: TextStyle(color: colors.muted, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    for (int i = 0; i < activeEditors.length; i++) ...[
                      if (i > 0) Divider(color: colors.border),
                      ListTile(
                        onTap: () {
                          final eId = activeEditors[i]['uid'] as String? ?? 'editor_${i + 1}';
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
                                color: colors.isDark ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Online',
                                style: TextStyle(
                                  color: colors.isDark ? Colors.greenAccent : const Color(0xFF15803D),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${activeEditors[i]['specialization'] ?? 'Video Editor'} • Skills: ${(activeEditors[i]['skills'] as List?)?.join(', ') ?? 'Editing'}',
                          style: TextStyle(color: colors.muted, fontSize: 11),
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
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.muted, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.trending_up_rounded, color: colors.primary, size: 22),
                const SizedBox(width: 10),
                Text('Re-list & Increase Editor Payout', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
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
                  WaraToast.show(
                    context,
                    message: '🔥 Project re-listed to pool with increased payout (৳$newPayout)!',
                    icon: Icons.bolt_rounded,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Re-list to Pool with New Payout', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final projects = ref.watch(projectsProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with logo & Post New Offer Button
              Row(
                children: [
                  const WaraLogo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text('wara.io', style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                              child: Text('Manager Control', style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Overseeing all agency projects & editor allocations',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const NotificationBellButton(),
                  const SizedBox(width: 8),

                  ElevatedButton.icon(
                    onPressed: () => _showCreateOfferModal(context, ref),
                    icon: Icon(Icons.add_rounded, size: 16, color: colors.isDark ? Colors.black : Colors.white),
                    label: Text('Post Offer', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Stats
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Open & Pool', style: TextStyle(color: colors.muted, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('${projects.where((p) => p.status == ProjectStatus.open).length}', style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('In Production', style: TextStyle(color: colors.muted, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('${projects.where((p) => p.status == ProjectStatus.claimed).length}', style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Submitted', style: TextStyle(color: colors.muted, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('${projects.where((p) => p.status == ProjectStatus.submitted).length}', style: TextStyle(color: colors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'ALL AGENCY PROJECTS PIPELINE',
                      style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Tap card to inspect / edit', style: TextStyle(color: colors.muted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),

              // All Projects Feed
              Expanded(
                child: ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return GestureDetector(
                      onTap: () => _showEditOfferModal(context, ref, project),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: project.isOverdue ? colors.warningRed.withValues(alpha: 0.6) : colors.border,
                            width: project.isOverdue ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Overdue Red Warning Banner
                            if (project.isOverdue) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colors.isDark ? Colors.black : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: colors.warningRed, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, color: colors.warningRed, size: 16),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '⚠️ OVERDUE - Editor Failed to Deliver Before Deadline',
                                        style: TextStyle(color: colors.warningRed, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                                  child: Text(project.clientName, style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                                    child: Text(
                                      project.claimedByEditorName != null ? 'Assigned: ${project.claimedByEditorName}' : 'Unassigned Pool',
                                      style: TextStyle(color: project.claimedByEditorName != null ? colors.text : colors.muted, fontSize: 11, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Text(project.title, style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(project.description, style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4)),
                            const SizedBox(height: 12),

                            if (project.submissionLink != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.video_library_rounded, color: colors.primary, size: 16),
                                        const SizedBox(width: 6),
                                        Text('Editor Submission Link:', style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(project.submissionLink!, style: TextStyle(color: colors.muted, fontSize: 11), overflow: TextOverflow.ellipsis),
                                    if (project.submissionNote != null) ...[
                                      const SizedBox(height: 4),
                                      Text('Note: ${project.submissionNote!}', style: TextStyle(color: colors.text, fontSize: 11)),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Deadline: ${project.deadlineStr}', style: TextStyle(color: colors.muted, fontSize: 11)),
                                    Text('Editor Payout: ৳${project.editorPayout.toInt()}', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.bold)),
                                  ],
                                ),

                                if (project.isOverdue)
                                  ElevatedButton.icon(
                                    onPressed: () => _showIncreasePayoutModal(context, ref, project),
                                    icon: Icon(Icons.bolt_rounded, size: 14, color: colors.isDark ? Colors.black : Colors.white),
                                    label: Text('Re-list & Increase Payout', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: colors.isDark ? Colors.black : Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                  )
                                else if (project.status == ProjectStatus.submitted)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          ref.read(projectsProvider.notifier).requestRevision(project.id, 'Please adjust sound levels and speed ramp transition.');
                                          WaraToast.show(
                                            context,
                                            message: '📝 Revision request sent back to Editor.',
                                            icon: Icons.edit_note_rounded,
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          side: BorderSide(color: colors.border),
                                          backgroundColor: colors.surface,
                                        ),
                                        child: Text('Revision', style: TextStyle(color: colors.text, fontSize: 11)),
                                      ),
                                      const SizedBox(width: 6),
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
                                            WaraToast.show(
                                              context,
                                              message: '✅ Deliverable validated & payout approved!',
                                              icon: Icons.check_circle_rounded,
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colors.primary,
                                          foregroundColor: colors.isDark ? Colors.black : Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        ),
                                        child: Text('Approve & Pay', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  )
                                else if (project.status == ProjectStatus.open)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => _showEditOfferModal(context, ref, project),
                                        icon: Icon(Icons.edit_outlined, size: 14, color: colors.primary),
                                        label: Text('Edit Offer', style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colors.isDark ? Colors.black : colors.surface,
                                          foregroundColor: colors.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          side: BorderSide(color: colors.border.withValues(alpha: 0.8), width: 1.2),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      ElevatedButton.icon(
                                        onPressed: () => _showAssignModal(context, ref, project),
                                        icon: Icon(Icons.person_add_rounded, size: 14, color: colors.isDark ? Colors.black : Colors.white),
                                        label: Text('Assign', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colors.primary,
                                          foregroundColor: colors.isDark ? Colors.black : Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          elevation: 0,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
        Text(label, style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.w600)),
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
