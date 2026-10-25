import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/motion/motion.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_error_state.dart';
import '../../../../shared/widgets/wara_page_header.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../notifications/presentation/widgets/notification_center_modal.dart';
import '../../../projects/domain/project_provider.dart';
import '../widgets/editor_ledger.dart';
import 'review_queue_screen.dart';
import '../../../payments/presentation/bkash_pay_screen.dart';
import '../../../payments/presentation/pay_flow.dart';

/// Editor ledger: what is owed, how urgent, and to whom. Marking paid uses
/// the existing approve flow (approved = paid).
class ManagerPendingScreen extends ConsumerWidget {
  const ManagerPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final projects = ref.watch(projectsProvider);
    final projectsError = ref.watch(projectsErrorProvider);
    if (projectsError != null && projects.isEmpty) {
      return ProjectsLoadError(error: projectsError);
    }
    final ledger = EditorLedger.of(projects);
    final m = AppSpacing.screenMargin(context);

    Future<void> pay(List<ProjectItem> ps, PayMethod method) async {
      if (method == PayMethod.bkash) {
        final name = ps.first.claimedByEditorName ?? 'Editor';
        await payWithBkashFlow(context, ref, ps, editorName: name);
        return;
      }
      final notifier = ref.read(projectsProvider.notifier);
      for (final p in ps) {
        notifier.approveProject(p.id);
      }
      Celebration.sparkle(context);
    }

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        bottom: false,
        child: WaraRefresh(
          onRefresh: () => ref.read(projectsProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(m, AppSpacing.lg, m, AppSpacing.bottomInset(context)),
            children: [
              WaraPageHeader(
                title: 'Pending',
                subtitle: ref.watch(authProvider.select((s) => s.user?.agencyName)),
                trailing: const NotificationBellButton(),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Owed', style: text.labelMedium?.copyWith(color: colors.muted)),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedCount(
                  key: const ValueKey('owed_total'),
                  format: takaFormat,
                  value: ledger.total.round(),
                  style: text.displaySmall?.copyWith(color: colors.text, fontWeight: FontWeight.w700, letterSpacing: -0.8),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              UrgencyBar(byUrgency: ledger.byUrgency),
              const ReviewQueueButton(),
              const SizedBox(height: AppSpacing.xl),
              if (ledger.editors.isEmpty && !ref.watch(projectsLoadedProvider))
                const CardSkeletonColumn(count: 3, height: 76)
              else if (ledger.editors.isEmpty)
                const WaraEmptyState(compact: true, icon: Icons.check_circle_outline_rounded, title: 'All paid up')
              else ...[
                Text('Editors', style: text.labelMedium?.copyWith(color: colors.muted)),
                const SizedBox(height: AppSpacing.sm),
                for (final e in ledger.editors) EditorOwedCard(key: ValueKey('card_${e.id}'), editor: e, onPay: pay),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
