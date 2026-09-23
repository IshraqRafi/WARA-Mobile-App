import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
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
                    child: Text(project.clientName, style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
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
                        Text(project.deadlineStr, style: TextStyle(color: colors.muted, fontSize: 11)),
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

              Text('PROJECT BRIEF & DELIVERABLE SPECIFICATIONS', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(project.description, style: TextStyle(color: colors.text, fontSize: 13, height: 1.5)),
              const SizedBox(height: 20),

              Text('REQUIRED CREATIVE SKILLS', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: project.requiredSkills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: colors.border)),
                    child: Text(skill, style: TextStyle(color: colors.text, fontSize: 11)),
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
                          user?.name ?? 'Walid Islam (You)',
                        );
                    Navigator.pop(ctx);
                    WaraToast.show(
                      context,
                      message: '🎉 Offer accepted! Project claimed & transferred to "My Workspace".',
                      icon: Icons.check_circle_rounded,
                    );
                  },
                  icon: Icon(Icons.touch_app_rounded, size: 18, color: colors.isDark ? Colors.black : Colors.white),
                  label: Text('Accept Offer & Claim Project', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final projects = ref.watch(projectsProvider);
    final user = ref.watch(authProvider).user;

    // Filter only open offers in the marketplace
    final availableProjects = projects.where((p) => p.status == ProjectStatus.open).toList();

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
                          Text('Welcome back, ${user?.name ?? 'Walid Islam'}', style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Claim available offers below. Tap any card for details.', style: TextStyle(color: colors.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('OPEN PROJECT OFFERS', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                  Text('${availableProjects.length} Offers Available', style: TextStyle(color: colors.muted, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),

              // Available Projects List
              Expanded(
                child: availableProjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline_rounded, color: colors.muted, size: 48),
                            const SizedBox(height: 12),
                            Text('All offers are claimed!', style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Check back later for new agency project drops.', style: TextStyle(color: colors.muted, fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: availableProjects.length,
                        itemBuilder: (context, index) {
                          final project = availableProjects[index];
                          return GestureDetector(
                            onTap: () => _showProjectDetailsModal(context, ref, project, user),
                            child: Container(
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
                                      const Spacer(),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.timer_outlined, color: colors.muted, size: 12),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  project.deadlineStr,
                                                  style: TextStyle(color: colors.muted, fontSize: 11),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(project.title, style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text(project.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4)),
                                  const SizedBox(height: 14),

                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: project.requiredSkills.map((skill) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                                        child: Text(skill, style: TextStyle(color: colors.text, fontSize: 10)),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('OFFER PAYOUT', style: TextStyle(color: colors.muted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                                          Text('৳${project.editorPayout.toInt()}', style: TextStyle(color: colors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ref.read(projectsProvider.notifier).claimProject(
                                                project.id,
                                                user?.id ?? 'editor_1',
                                                user?.name ?? 'Walid Islam (You)',
                                              );

                                          WaraToast.show(
                                            context,
                                            message: '🎉 Offer accepted! Project claimed & transferred to "My Workspace".',
                                            icon: Icons.check_circle_rounded,
                                          );
                                        },
                                        icon: Icon(Icons.touch_app_rounded, size: 16, color: colors.isDark ? Colors.black : Colors.white),
                                        label: Text('Accept Offer', style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colors.primary,
                                          foregroundColor: colors.isDark ? Colors.black : Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          elevation: 0,
                                        ),
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
