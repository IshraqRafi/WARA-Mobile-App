import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../projects/domain/project_provider.dart';

class EditorWorkspaceScreen extends ConsumerWidget {
  const EditorWorkspaceScreen({super.key});

  void _showSubmitModal(BuildContext context, WidgetRef ref, ProjectItem project) {
    final colors = context.colors;
    final linkCtrl = TextEditingController(text: project.submissionLink ?? '');
    final noteCtrl = TextEditingController(text: project.submissionNote ?? '');

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: colors.muted.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.upload_file_rounded, color: colors.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Submit Deliverable for Validation',
                    style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Submit final files, Google Drive, or Frame.io links for manager validation.',
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
            const SizedBox(height: 20),

            Text('Asset Link (Required)', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: linkCtrl,
              style: TextStyle(color: colors.text, fontSize: 14),
              decoration: InputDecoration(
                fillColor: colors.surface,
                filled: true,
                hintText: 'https://drive.google.com/... or Vimeo/Frame link',
                hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                prefixIcon: Icon(Icons.link_rounded, color: colors.muted, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            Text('Production Notes (Optional)', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: TextStyle(color: colors.text, fontSize: 14),
              decoration: InputDecoration(
                fillColor: colors.surface,
                filled: true,
                hintText: 'Any comments, revision changes, or render notes for the manager...',
                hintStyle: TextStyle(color: colors.muted, fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel', style: TextStyle(color: colors.muted, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final link = linkCtrl.text.trim();
                      if (link.isEmpty) {
                        WaraToast.show(context, message: 'Please provide a valid deliverable asset link.', icon: Icons.warning_amber_rounded);
                        return;
                      }

                      ref.read(projectsProvider.notifier).submitWork(
                            project.id,
                            link,
                            noteCtrl.text.trim(),
                          );

                      Navigator.pop(ctx);
                      WaraToast.show(
                        context,
                        message: '🚀 Work submitted! Manager has been notified for final validation.',
                        icon: Icons.check_circle_rounded,
                      );
                    },
                    icon: Icon(Icons.send_rounded, size: 18, color: colors.isDark ? Colors.black : Colors.white),
                    label: Text(
                      project.status == ProjectStatus.submitted ? 'Update Submission' : 'Submit for Approval',
                      style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
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

    // Projects claimed by this editor
    final myProjects = projects.where((p) => p.claimedByEditorId != null).toList();

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const WaraLogo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('wara.io', style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                        Text(
                          'My pending workspace & submissions',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Active projects count card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${myProjects.length} Projects in Your Workspace',
                        style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Earned: ৳${myProjects.where((p) => p.status == ProjectStatus.approved).fold<double>(0, (sum, item) => sum + item.editorPayout).toInt()}',
                      style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Projects List
              Expanded(
                child: myProjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open_outlined, color: colors.muted, size: 48),
                            const SizedBox(height: 12),
                            Text('Your workspace is empty', style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Go to "Available Marketplace" to claim client projects!', style: TextStyle(color: colors.muted, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: myProjects.length,
                        itemBuilder: (context, index) {
                          final project = myProjects[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                                      child: Text(project.clientName, style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: _StatusBadge(status: project.status),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(project.title, style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(project.description, style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4)),
                                const SizedBox(height: 14),

                                // Return Rules & Grace Period Banner
                                if (project.status == ProjectStatus.claimed) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: colors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          project.canReturn ? Icons.published_with_changes_rounded : Icons.lock_clock_outlined,
                                          size: 14,
                                          color: project.canReturn ? colors.primary : colors.muted,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            project.canReturn
                                                ? 'Return Rule: Can return to pool (-1 day deadline deducted).'
                                                : 'Return Disabled: Cannot return project (<= 3 days remaining).',
                                            style: TextStyle(
                                              color: project.canReturn ? colors.text : colors.muted,
                                              fontSize: 11,
                                              fontWeight: project.canReturn ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                if (project.submissionLink != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.link_rounded, color: colors.primary, size: 16),
                                            const SizedBox(width: 6),
                                            Text('Submitted Asset Link', style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(project.submissionLink!, style: TextStyle(color: colors.muted, fontSize: 11), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                // Action Buttons Row (Return & Submit)
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    Text('Payout: ৳${project.editorPayout.toInt()}', style: TextStyle(color: colors.primary, fontSize: 15, fontWeight: FontWeight.bold)),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (project.status == ProjectStatus.claimed) ...[
                                          OutlinedButton.icon(
                                            onPressed: project.canReturn
                                                ? () {
                                                    final ok = ref.read(projectsProvider.notifier).returnProject(project.id);
                                                    if (ok) {
                                                      WaraToast.show(
                                                        context,
                                                        message: '↩️ Project returned to pool! Deadline reduced by 1 day.',
                                                        icon: Icons.replay_rounded,
                                                      );
                                                    }
                                                  }
                                                : null,
                                            icon: Icon(Icons.undo_rounded, size: 14, color: project.canReturn ? colors.text : colors.muted),
                                            label: Text(
                                              project.canReturn ? 'Return' : 'Locked (<=3d)',
                                              style: TextStyle(fontSize: 11, color: project.canReturn ? colors.text : colors.muted),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              side: BorderSide(color: project.canReturn ? colors.border : Colors.transparent),
                                              backgroundColor: project.canReturn ? colors.surface : colors.surface.withValues(alpha: 0.3),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],

                                        if (project.status != ProjectStatus.approved)
                                          ElevatedButton.icon(
                                            onPressed: () => _showSubmitModal(context, ref, project),
                                            icon: Icon(Icons.upload_file_rounded, size: 14, color: colors.isDark ? Colors.black : Colors.white),
                                            label: Text(
                                              project.status == ProjectStatus.submitted ? 'Update' : 'Submit Link',
                                              style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: colors.primary,
                                              foregroundColor: colors.isDark ? Colors.black : Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          )
                                        else
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle_rounded, color: colors.primary, size: 16),
                                              const SizedBox(width: 4),
                                              Text('Validated & Paid', style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
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

class _StatusBadge extends StatelessWidget {
  final ProjectStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    String label;
    Color color;

    switch (status) {
      case ProjectStatus.open:
        label = 'Open';
        color = colors.muted;
        break;
      case ProjectStatus.claimed:
        label = 'In Progress';
        color = colors.text;
        break;
      case ProjectStatus.submitted:
        label = 'Submitted • Pending Validation';
        color = colors.primary;
        break;
      case ProjectStatus.approved:
        label = 'Approved & Validated';
        color = colors.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
