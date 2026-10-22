import 'package:flutter/material.dart';
import '../../../../shared/widgets/availability_badge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_empty_state.dart';
import '../../../../shared/widgets/wara_page_header.dart';
import '../../../../shared/widgets/wara_section_header.dart';
import '../../../../shared/widgets/wara_theme_toggle.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../leaderboard/presentation/widgets/agency_leaderboard_sheet.dart';
import '../../../projects/domain/project_provider.dart';
import '../widgets/rate_editor_dialog.dart';
import '../widgets/studio_card.dart';

class ManagerSettingsScreen extends ConsumerWidget {
  const ManagerSettingsScreen({super.key});

  void _showTeamModal(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.read(authProvider).user;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 36, height: 4, decoration: BoxDecoration(color: colors.muted.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.groups_rounded, color: colors.primary, size: 24),
                  const SizedBox(width: 10),
                  Text('Agency Creative Team', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Editors connected to ${user?.agencyName ?? "your agency room"} • Ranked by performance',
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
              const SizedBox(height: 14),

              // Join Key Quick-Copy Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.vpn_key_rounded, color: colors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Join Key: ${user?.agencyJoinKey ?? "—"}',
                        style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final key = user?.agencyJoinKey ?? '';
                        if (key.isEmpty) return;
                        Clipboard.setData(ClipboardData(text: key));
                        WaraToast.show(context, message: 'Join key copied', icon: Icons.copy_rounded);
                      },
                      child: Text('COPY', style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: Consumer(
  builder: (context, ref, _) {
  final snapshot = asSnapshot(ref.watch(editorsProvider(user?.agencyId)));
                    final activeEditors = snapshot.data ?? [];

                    if (activeEditors.isEmpty) {
                      return ListView(
                        controller: scrollController,
                        children: [
                          const WaraEmptyState(
                            compact: true,
                            icon: Icons.people_outline_rounded,
                            title: 'No editors',
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: activeEditors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final e = activeEditors[index];
                        final editorId = e['id'] as String? ?? e['uid'] as String? ?? '';
                        final editorName = e['name'] as String? ?? 'Editor';
                        final photoUrl = e['photoUrl'] as String?;
                        final rating = (e['rating'] as num?)?.toDouble() ?? 0.0;
                        final ratingCount = (e['ratingCount'] as num?)?.toInt() ?? 0;
                        final completedProjects = (e['completedProjects'] as num?)?.toInt() ?? 0;

                        return _EditorCard(
                          rank: index + 1,
                          name: editorName,
                          photoUrl: photoUrl,
                          specialization: e['specialization'] as String? ?? 'Video Editor',
                          skills: List<String>.from(e['skills'] ?? ['Video Editing']),
                          hoursPerWeek: (e['hoursPerWeek'] as num?)?.toInt() ?? 35,
                          activeDays: List<String>.from(e['activeDays'] ?? ['Mon', 'Tue', 'Wed']),
                          portfolioLink: e['portfolioLink'] as String?,
                          email: e['email'] as String?,
                          rating: rating,
                          ratingCount: ratingCount,
                          completedProjects: completedProjects,
                          availability: e['availability'],
                          onRate: () {
                            showRateEditorSheet(
                              context: context,
                              ref: ref,
                              editorId: editorId,
                              editorName: editorName,
                              editorPhotoUrl: photoUrl,
                            );
                          },
                        );
                      },
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final user = ref.watch(authProvider.select((s) => s.user));

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(AppSpacing.screenMargin(context), AppSpacing.lg, AppSpacing.screenMargin(context), AppSpacing.bottomInset(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WaraPageHeader(
                title: 'Settings',
                subtitle: (user?.agencyName ?? '').isNotEmpty ? user!.agencyName : null,
                trailing: const WaraThemeToggle(),
              ),
              const SizedBox(height: 24),

              // Manager Profile Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    WaraAvatar(
                      name: user?.name,
                      photoUrl: user?.photoUrl,
                      radius: 26,
                      fontSize: 16,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.name ?? '', style: TextStyle(color: colors.text, fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(user?.email ?? '', style: TextStyle(color: colors.muted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                            child: Text('Agency Director • Admin', style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const StudioCard(),
              const SizedBox(height: 24),

              WaraSectionCard(
                title: 'Agency',
                children: [
                  ListTile(
                    leading: const Icon(Icons.people_outline_rounded),
                    title: const Text('Team'),
                    subtitle: const Text('Editors registered in your agency'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showTeamModal(context, ref),
                  ),
                  ListTile(
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: const Text('Leaderboard'),
                    subtitle: const Text('Editor rankings, ratings and output'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => showAgencyLeaderboardModal(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              WaraSectionCard(
                title: 'Account',
                children: [
                  ListTile(
                    leading: Icon(Icons.logout_rounded, color: colors.error),
                    title: Text('Log out', style: TextStyle(color: colors.error, fontWeight: FontWeight.w600)),
                    onTap: () => ref.read(authProvider.notifier).logout(),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  final int rank;
  final String name;
  final String? photoUrl;
  final String specialization;
  final List<String> skills;
  final int hoursPerWeek;
  final List<String> activeDays;
  final String? portfolioLink;
  final String? email;
  final double rating;
  final int ratingCount;
  final int completedProjects;
  final Object? availability;
  final VoidCallback? onRate;

  const _EditorCard({
    required this.rank,
    required this.name,
    this.photoUrl,
    required this.specialization,
    required this.skills,
    required this.hoursPerWeek,
    required this.activeDays,
    this.portfolioLink,
    this.email,
    required this.rating,
    required this.ratingCount,
    required this.completedProjects,
    this.availability,
    this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget buildRankBadge() {
      if (rank == 1) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.star.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.star.withValues(alpha: 0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🥇', style: TextStyle(fontSize: 12)),
              SizedBox(width: 4),
              Text('#1 Leader', style: TextStyle(color: AppColors.star, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }
      if (rank == 2) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.medalSilver.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.medalSilver.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🥈', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text('#2 Top', style: TextStyle(color: AppColors.medalSilver, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }
      if (rank == 3) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.medalBronze.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.medalBronze.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🥉', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text('#3 Rising', style: TextStyle(color: AppColors.medalBronze, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Text('#$rank', style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile & Rank Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WaraAvatar(
                name: name,
                photoUrl: photoUrl,
                radius: 22,
                fontSize: 14,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(
                          name,
                          style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AvailabilityBadge(availability),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                      specialization,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email != null && email!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email!,
                        style: TextStyle(color: colors.muted.withValues(alpha: 0.8), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              buildRankBadge(),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Metrics Wrap (Star rating, completed deliverables, capacity)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Rating pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.star.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.star.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(color: AppColors.star, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ' ($ratingCount)',
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Deliverables count pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.video_library_outlined, color: colors.muted, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '$completedProjects cuts',
                      style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // Availability hours pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, color: colors.muted, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '$hoursPerWeek hrs/wk',
                      style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Working Days & Portfolio Row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Days:', style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
              ...activeDays.map((d) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: colors.border),
                ),
                child: Text(d, style: TextStyle(color: colors.text, fontSize: 12)),
              )),
            ],
          ),

          // 4. Skills Wrap
          if (skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: skills.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.border),
                ),
                child: Text(s, style: TextStyle(color: colors.text, fontSize: 12)),
              )).toList(),
            ),
          ],

          // 5. Portfolio Link (Safe overflow)
          if (portfolioLink != null && portfolioLink!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.link_rounded, color: colors.muted, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    portfolioLink!,
                    style: TextStyle(color: colors.primary, fontSize: 12, decoration: TextDecoration.underline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // 6. Action Button Bar
          if (onRate != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRate,
                icon: const Icon(Icons.star_rounded, color: AppColors.star, size: 16),
                label: Text(
                  'Rate & Review Editor',
                  style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: AppColors.star.withValues(alpha: 0.4)),
                  backgroundColor: colors.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

