import 'package:flutter/material.dart';
import '../../../../shared/motion/motion.dart';
import '../../../../shared/widgets/wara_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_project_card.dart';
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
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.muted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
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

            Text(
              'Asset Link (Required)',
              style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: linkCtrl,
              style: TextStyle(color: colors.text, fontSize: 14),
              decoration: InputDecoration(
                fillColor: colors.surface,
                filled: true,
                hintText: 'https://',
                hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                prefixIcon: Icon(Icons.link_rounded, color: colors.muted, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Production Notes (Optional)',
              style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: TextStyle(color: colors.text, fontSize: 14),
              decoration: InputDecoration(
                fillColor: colors.surface,
                filled: true,
                hintText: 'Notes (optional)',
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
                        WaraToast.show(context, message: 'Enter a valid link', icon: Icons.warning_amber_rounded);
                        return;
                      }

                      ref.read(projectsProvider.notifier).submitWork(project.id, link, noteCtrl.text.trim());

                      Navigator.pop(ctx);
                      WaraToast.show(context, message: 'Submitted for review', icon: Icons.check_circle_rounded);
                    },
                    icon: Icon(Icons.send_rounded, size: 18, color: colors.onPrimary),
                    label: Text(
                      project.status == ProjectStatus.submitted ? 'Update Submission' : 'Submit for Approval',
                      style: TextStyle(color: colors.onPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
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
    final projectsError = ref.watch(projectsErrorProvider);
    if (projectsError != null && projects.isEmpty) {
      return ProjectsLoadError(error: projectsError);
    }

    // Projects claimed by this editor
    final workspace = ref.watch(workspaceProjectsProvider);
    final myProjects = workspace.items;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenMargin(context),
            AppSpacing.lg,
            AppSpacing.screenMargin(context),
            0,
          ),
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
                        Text(
                          'wara.io',
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
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
                      'Earned: ৳${workspace.earned}',
                      style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: myProjects.isEmpty && !ref.watch(projectsLoadedProvider)
                    ? const SkeletonList(item: ProjectCardSkeleton())
                    : myProjects.isEmpty
                    ? const WaraEmptyState(icon: Icons.folder_open_outlined, title: 'No projects')
                    : ListView.builder(
                        padding: EdgeInsets.only(bottom: AppSpacing.bottomInset(context)),
                        itemCount: myProjects.length,
                        itemBuilder: (context, index) {
                          final project = myProjects[index];
                          return StaggerIn(
                            key: ValueKey(project.id),
                            screen: 'workspace',
                            index: index,
                            child: WaraProjectCard(
                              project: project,
                              listId: 'workspace',
                              payoutLabel: 'Payout',
                              actions: [
                                if (project.status == ProjectStatus.claimed)
                                  Tooltip(
                                    message: project.canReturn
                                        ? 'Return to pool (deadline −1 day)'
                                        : 'Locked: 3 days or less left',
                                    child: OutlinedButton.icon(
                                      onPressed: project.canReturn
                                          ? () {
                                              final ok = ref.read(projectsProvider.notifier).returnProject(project.id);
                                              if (ok) {
                                                WaraToast.show(
                                                  context,
                                                  message: 'Returned to pool',
                                                  icon: Icons.replay_rounded,
                                                );
                                              }
                                            }
                                          : null,
                                      style: waraCompactButton(),
                                      icon: const Icon(Icons.undo_rounded, size: 18),
                                      label: Text(project.canReturn ? 'Return' : 'Locked'),
                                    ),
                                  ),
                                if (project.status != ProjectStatus.approved)
                                  ElevatedButton.icon(
                                    onPressed: () => _showSubmitModal(context, ref, project),
                                    style: waraCompactButton(),
                                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                                    label: Text(project.status == ProjectStatus.submitted ? 'Update' : 'Submit link'),
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
