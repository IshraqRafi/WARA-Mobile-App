import 'package:flutter/material.dart';
import '../../../../shared/widgets/wara_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_project_card.dart';
import '../../../../shared/widgets/wara_section_header.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../projects/domain/project_provider.dart';
import '../../../notifications/presentation/widgets/notification_center_modal.dart';

class EditorAvailableScreen extends ConsumerWidget {
  const EditorAvailableScreen({super.key});

  void _showProjectDetailsModal(BuildContext context, WidgetRef ref, ProjectItem project, UserSession? user) {
    final colors = context.colors;
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
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.muted.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                    child: Text(project.clientName, style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, color: colors.muted, size: 12),
                        const SizedBox(width: 4),
                        Text(project.deadlineStr, style: TextStyle(color: colors.muted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(project.title, style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Payout Banner
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
                        'Guaranteed Payout upon Approval',
                        style: TextStyle(color: colors.muted, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('৳${project.editorPayout.toInt()}', style: TextStyle(color: colors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text('PROJECT BRIEF & DELIVERABLE SPECIFICATIONS', style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(project.description, style: TextStyle(color: colors.text, fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),

              Text('REQUIRED CREATIVE SKILLS', style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: project.requiredSkills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
                    child: Text(skill, style: TextStyle(color: colors.text, fontSize: 12)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(projectsProvider.notifier).claimProject(
                          project.id,
                          user?.id ?? 'editor_1',
                          '${user?.name ?? ''} (You)',
                        );
                    Navigator.pop(ctx);
                    WaraToast.show(
                      context,
                      message: 'Project claimed',
                      icon: Icons.check_circle_rounded,
                    );
                  },
                  icon: Icon(Icons.touch_app_rounded, size: 18, color: colors.onPrimary),
                  label: Text('Accept Offer & Claim Project', style: TextStyle(color: colors.onPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
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
    final user = ref.watch(authProvider).user;

    // Filter only open offers in the marketplace
    final availableProjects = projects.where((p) => p.status == ProjectStatus.open).toList();

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.screenMargin(context), AppSpacing.lg, AppSpacing.screenMargin(context), 0),
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
                          'Available project offers marketplace',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const NotificationBellButton(),
                ],
              ),
              const SizedBox(height: 20),

              // Welcome banner card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    WaraAvatar(
                      name: user?.name,
                      photoUrl: user?.photoUrl,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back, ${user?.name ?? ''}', style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              WaraSectionHeader(
                title: 'Open offers',
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
              ),
              Expanded(
                child: availableProjects.isEmpty
                    ? const WaraEmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'No open offers',
                      )
                    : ListView.builder(
                        padding: EdgeInsets.only(bottom: AppSpacing.bottomInset(context)),
                        itemCount: availableProjects.length,
                        itemBuilder: (context, index) {
                          final project = availableProjects[index];
                          return WaraProjectCard(
                            project: project,
                            showStatus: false,
                            showSkills: true,
                            payoutLabel: 'Offer payout',
                            onTap: () => _showProjectDetailsModal(context, ref, project, user),
                            actions: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref.read(projectsProvider.notifier).claimProject(
                                        project.id,
                                        user?.id ?? 'editor_1',
                                        '${user?.name ?? ''} (You)',
                                      );
                                  WaraToast.show(
                                    context,
                                    message: 'Project claimed',
                                    icon: Icons.check_circle_rounded,
                                  );
                                },
                                style: waraCompactButton(),
                                icon: const Icon(Icons.touch_app_rounded, size: 18),
                                label: const Text('Accept offer'),
                              ),
                            ],
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
