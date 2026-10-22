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
import '../widgets/submit_sheet.dart';
import '../widgets/revision_checklist.dart';

class EditorWorkspaceScreen extends ConsumerWidget {
  const EditorWorkspaceScreen({super.key});

  void _showSubmitModal(BuildContext context, WidgetRef ref, ProjectItem project) {
    showSubmitSheet(context, project, openChecks: openRevisionItems(project), onSubmit: (link, note) {
      ref.read(projectsProvider.notifier).submitWork(project.id, link, note);
      WaraToast.show(context, message: 'Submitted v${project.submissionVersion + 1}', icon: Icons.check_circle_rounded);
    });
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
        // Refresh spans the page so the spinner enters from the top edge.
        child: WaraRefresh(
          onRefresh: () => ref.read(projectsProvider.notifier).refresh(),
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
                    RollingCounter(
                      prefix: 'Earned: ৳',
                      value: workspace.earned,
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
                        physics: const AlwaysScrollableScrollPhysics(),
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
                              notice: revisionItems(project).isEmpty
                                  ? null
                                  : RevisionChecklist(
                                      items: revisionItems(project),
                                      checked: project.revisionChecks,
                                      onToggle: (i) => ref.read(projectsProvider.notifier).toggleRevisionCheck(project.id, i),
                                    ),
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
      ),
    );
  }
}
