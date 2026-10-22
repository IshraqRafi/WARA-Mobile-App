import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/wara_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_project_card.dart';
import '../../../../shared/widgets/wara_section_header.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../projects/domain/project_provider.dart';
import '../../../notifications/presentation/widgets/notification_center_modal.dart';

class EditorAvailableScreen extends ConsumerStatefulWidget {
  const EditorAvailableScreen({super.key});

  @override
  ConsumerState<EditorAvailableScreen> createState() => _EditorAvailableScreenState();
}

class _EditorAvailableScreenState extends ConsumerState<EditorAvailableScreen> {
  /// Claimed offers kept on screen until their exit animation finishes.
  final Set<String> _settling = {};
  final Set<String> _leaving = {};

  Future<void> _claim(ProjectItem project, UserSession? user) {
    setState(() => _settling.add(project.id));
    return ref
        .read(projectsProvider.notifier)
        .claimProject(project.id, user?.id ?? 'editor_1', '${user?.name ?? ''} (You)')
        .catchError((Object e) {
      if (mounted) setState(() => _settling.remove(project.id));
      throw e;
    });
  }

  void _showClaimError(Object e) {
    WaraToast.show(context, message: friendlyErrorMessage(e), icon: Icons.error_outline_rounded);
  }

  void _hide(ProjectItem project) {
    final hidden = ref.read(hiddenOffersProvider.notifier);
    hidden.state = {...hidden.state, project.id};
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: const Text('Offer hidden'),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () => hidden.state = {...hidden.state}..remove(project.id),
      ),
    ));
  }

  Widget _swipeBg(AppColors c, ValueListenable<double> progress, {required bool claim}) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        alignment: claim ? Alignment.centerLeft : Alignment.centerRight,
        decoration: BoxDecoration(color: claim ? c.successTint : c.surface, borderRadius: AppRadius.brLg),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwipeIcon(
              progress: progress,
              child: Icon(claim ? Icons.touch_app_rounded : Icons.visibility_off_outlined, size: 20, color: claim ? c.success : c.muted),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(claim ? 'Claim' : 'Hide', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: claim ? c.success : c.muted)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final projects = ref.watch(projectsProvider);
    final projectsError = ref.watch(projectsErrorProvider);
    if (projectsError != null && projects.isEmpty) {
      return ProjectsLoadError(error: projectsError);
    }
    final user = ref.watch(authProvider.select((s) => s.user));

    // Filter only open offers in the marketplace
    final hidden = ref.watch(hiddenOffersProvider);
    final loaded = ref.watch(projectsLoadedProvider);
    final availableProjects = projects
        .where((p) => (p.status == ProjectStatus.open || _settling.contains(p.id)) && !hidden.contains(p.id))
        .toList();

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
                child: !loaded && availableProjects.isEmpty
                    ? const SkeletonList(item: ProjectCardSkeleton())
                    : availableProjects.isEmpty
                    ? const WaraEmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'No open offers',
                      )
                    : WaraRefresh(
                        onRefresh: () => ref.read(projectsProvider.notifier).refresh(),
                        child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: AppSpacing.bottomInset(context)),
                        itemCount: availableProjects.length,
                        itemBuilder: (context, index) {
                          final project = availableProjects[index];
                          final card = WaraProjectCard(
                            project: project,
                            listId: 'marketplace',
                            showStatus: false,
                            showSkills: true,
                            payoutLabel: 'Offer payout',
                            actions: [
                              ClaimButton(
                                key: ValueKey('claim_${project.id}'),
                                label: 'Claim',
                                icon: Icons.touch_app_rounded,
                                onPressed: () => _claim(project, user),
                                onError: _showClaimError,
                                onCompleted: () => setState(() => _leaving.add(project.id)),
                              ),
                            ],
                          );
                          return StaggerIn(
                            key: ValueKey(project.id),
                            screen: 'marketplace',
                            index: index,
                            child: CollapseOut(
                              out: _leaving.contains(project.id),
                              onEnd: () => setState(() {
                                _leaving.remove(project.id);
                                _settling.remove(project.id);
                              }),
                              child: _settling.contains(project.id)
                                  ? card
                                  : SwipeFeedback(
                                      builder: (context, progress, onUpdate) => Dismissible(
                                      key: ValueKey('swipe_${project.id}'),
                                      background: _swipeBg(colors, progress, claim: true),
                                      onUpdate: onUpdate,
                                      secondaryBackground: _swipeBg(colors, progress, claim: false),
                                      confirmDismiss: (dir) async {
                                        if (dir == DismissDirection.endToStart) return true;
                                        try {
                                          await _claim(project, user);
                                          return true;
                                        } catch (e) {
                                          _showClaimError(e);
                                          return false;
                                        }
                                      },
                                      onDismissed: (dir) {
                                        if (dir == DismissDirection.endToStart) {
                                          _hide(project);
                                        } else {
                                          setState(() => _settling.remove(project.id));
                                          WaraToast.show(context, message: 'Claimed', icon: Icons.check_circle_rounded);
                                        }
                                      },
                                      child: card,
                                    )),
                            ),
                          );
                        },
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
