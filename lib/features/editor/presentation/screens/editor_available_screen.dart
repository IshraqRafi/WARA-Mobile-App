import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../shared/widgets/wara_error_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_section_header.dart';
import '../../../../shared/widgets/wara_page_header.dart';
import '../../domain/editor_earnings.dart';
import '../widgets/earnings_header.dart';
import '../widgets/today_strip.dart';
import '../widgets/offer_card.dart';
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
  /// Claims waiting out the undo window; written when the timer fires.
  final Map<String, Timer> _pending = {};
  static const undoWindow = Duration(seconds: 5);

  void _claim(ProjectItem project, UserSession? user) {
    if (_pending.containsKey(project.id)) return;
    Haptics.medium();
    final notifier = ref.read(projectsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    Future<void> commit() async {
      _pending.remove(project.id);
      try {
        await notifier.claimProject(project.id, user?.id ?? 'editor_1', '${user?.name ?? ''} (You)');
      } catch (e) {
        if (!mounted) return;
        setState(() {});
        WaraToast.show(context, message: friendlyErrorMessage(e), icon: Icons.error_outline_rounded);
      }
    }
    setState(() => _pending[project.id] = Timer(undoWindow, () {
          if (mounted) setState(() {});
          commit();
        }));
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text('Claimed ${project.title}'),
      duration: undoWindow,
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          _pending.remove(project.id)?.cancel();
          if (mounted) setState(() {});
        },
      ),
    ));
    _commits[project.id] = commit;
  }

  final Map<String, Future<void> Function()> _commits = {};

  @override
  void dispose() {
    // Leaving the screen inside the undo window still claims.
    for (final id in _pending.keys.toList()) {
      _pending[id]!.cancel();
      _commits[id]?.call();
    }
    super.dispose();
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
        decoration: BoxDecoration(color: claim ? c.primary.withValues(alpha: 0.12) : c.surface, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwipeIcon(
              progress: progress,
              child: Icon(claim ? Icons.check_rounded : Icons.visibility_off_outlined, size: 22, color: claim ? c.primary : c.muted),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(claim ? 'Claim' : 'Hide', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: claim ? c.primary : c.muted)),
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
    final today = nextDeadline(projects.where((p) => isClaimedBy(p, user?.id)), DateTime.now());

    // Filter only open offers in the marketplace
    final hidden = ref.watch(hiddenOffersProvider);
    final loaded = ref.watch(projectsLoadedProvider);
    final availableProjects = projects
        .where((p) => p.status == ProjectStatus.open && !hidden.contains(p.id) && !_pending.containsKey(p.id))
        .toList();

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        // Refresh spans the page so the spinner enters from the top edge.
        child: WaraRefresh(
          onRefresh: () => ref.read(projectsProvider.notifier).refresh(),
          child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.screenMargin(context), AppSpacing.lg, AppSpacing.screenMargin(context), 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WaraPageHeader(
                title: 'Offers',
                subtitle: (user?.agencyName ?? '').isNotEmpty ? user!.agencyName : null,
                trailing: const NotificationBellButton(),
              ),
              if (today != null) ...[
                const SizedBox(height: AppSpacing.lg),
                TodayStrip(
                  key: ValueKey('today_${today.id}'),
                  project: today,
                  onTap: () {
                    ref.read(expandedCardProvider('workspace').notifier).state = today.id;
                    context.go('/editor/workspace');
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              EarningsHeader(earnings: ref.watch(editorEarningsProvider)),
              const SizedBox(height: AppSpacing.xl),

              WaraSectionHeader(
                title: 'Open offers',
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
              ),
              Expanded(
                child: !loaded && availableProjects.isEmpty
                    ? const SkeletonList(item: OfferCardSkeleton())
                    : availableProjects.isEmpty
                    ? const WaraEmptyState(
                        icon: Icons.check_circle_outline_rounded,
                        title: 'No open offers',
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: AppSpacing.bottomInset(context)),
                        itemCount: availableProjects.length,
                        itemBuilder: (context, index) {
                          final project = availableProjects[index];
                          return StaggerIn(
                            key: ValueKey(project.id),
                            screen: 'marketplace',
                            index: index,
                            child: SwipeFeedback(
                              builder: (context, progress, onUpdate) => Dismissible(
                                key: ValueKey('swipe_${project.id}'),
                                background: _swipeBg(colors, progress, claim: true),
                                secondaryBackground: _swipeBg(colors, progress, claim: false),
                                onUpdate: onUpdate,
                                onDismissed: (dir) => dir == DismissDirection.endToStart
                                    ? _hide(project)
                                    : _claim(project, user),
                                child: OfferCard(project: project, onTap: () => showOfferDetail(context, project, agencyName: user?.agencyName, onClaim: () => _claim(project, user)), onLongPress: () => _claim(project, user)),
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
      ),
    );
  }
}
