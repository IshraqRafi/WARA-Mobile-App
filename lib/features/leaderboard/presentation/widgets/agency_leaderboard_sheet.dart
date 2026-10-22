import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../manager/presentation/widgets/rate_editor_dialog.dart';
import '../../../projects/domain/project_provider.dart';

/// Shows the full Agency Creative Leaderboard as a draggable modal
Future<void> showAgencyLeaderboardModal(BuildContext context, WidgetRef ref) {
  final colors = context.colors;
  final currentUser = ref.read(authProvider).user;
  final isManager = currentUser?.role == UserRole.manager;

  return showModalBottomSheet(
    context: context,
    backgroundColor: colors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
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
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.muted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Modal Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.star.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: AppColors.star, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agency Creative Leaderboard',
                        style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${currentUser?.agencyName ?? "Agency Room"} • Real-Time Rankings',
                        style: TextStyle(color: colors.muted, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Leaderboard Stream
            Expanded(
              child: Consumer(
  builder: (context, ref, _) {
  final snapshot = asSnapshot(ref.watch(editorsProvider(currentUser?.agencyId)));
                  final editors = snapshot.data ?? [];

                  if (editors.isEmpty) {
                    return ListView(
                      controller: scrollController,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.military_tech_outlined, color: colors.muted, size: 42),
                              const SizedBox(height: 12),
                              Text(
                                'No ranked editors yet',
                                style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Editors will be ranked on this leaderboard as they complete projects and receive ratings from the manager.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Find user rank
                  int? userRank;
                  for (int i = 0; i < editors.length; i++) {
                    final e = editors[i];
                    if (e['id'] == currentUser?.id || (currentUser?.email != null && e['email'] == currentUser!.email)) {
                      userRank = i + 1;
                      break;
                    }
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: editors.length + (userRank != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Top highlight card for current editor
                      if (userRank != null && index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.primary.withValues(alpha: 0.12),
                                colors.surface,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.workspace_premium_rounded, color: colors.primary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Your Agency Position: Rank #$userRank',
                                  style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'YOU',
                                  style: TextStyle(
                                    color: colors.onPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final editorIndex = userRank != null ? index - 1 : index;
                      final e = editors[editorIndex];
                      final rank = editorIndex + 1;
                      final name = e['name'] as String? ?? 'Editor';
                      final photoUrl = e['photoUrl'] as String?;
                      final rating = (e['rating'] as num?)?.toDouble() ?? 0.0;
                      final completedProjects = (e['completedProjects'] as num?)?.toInt() ?? 0;
                      final specialization = e['specialization'] as String? ?? 'Creative Editor';
                      final editorId = e['id'] as String? ?? e['uid'] as String? ?? '';
                      final isCurrentUser = editorId == currentUser?.id || (currentUser?.email != null && e['email'] == currentUser!.email);

                      return _LeaderboardRow(
                        rank: rank,
                        name: name,
                        photoUrl: photoUrl,
                        specialization: specialization,
                        rating: rating,
                        completedProjects: completedProjects,
                        isCurrentUser: isCurrentUser,
                        isManager: isManager,
                        onRatePressed: isManager
                            ? () {
                                showRateEditorSheet(
                                  context: context,
                                  ref: ref,
                                  editorId: editorId,
                                  editorName: name,
                                  editorPhotoUrl: photoUrl,
                                );
                              }
                            : null,
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

/// Leaderboard Row Component
class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String name;
  final String? photoUrl;
  final String specialization;
  final double rating;
  final int completedProjects;
  final bool isCurrentUser;
  final bool isManager;
  final VoidCallback? onRatePressed;

  const _LeaderboardRow({
    required this.rank,
    required this.name,
    this.photoUrl,
    required this.specialization,
    required this.rating,
    required this.completedProjects,
    required this.isCurrentUser,
    required this.isManager,
    this.onRatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    Widget buildMedal() {
      if (rank == 1) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.star.withValues(alpha: 0.2),
            border: Border.all(color: AppColors.star, width: 1.5),
          ),
          child: const Center(
            child: Text('🥇', style: TextStyle(fontSize: 16)),
          ),
        );
      }
      if (rank == 2) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.medalSilver.withValues(alpha: 0.2),
            border: Border.all(color: AppColors.medalSilver, width: 1.5),
          ),
          child: const Center(
            child: Text('🥈', style: TextStyle(fontSize: 16)),
          ),
        );
      }
      if (rank == 3) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.medalBronze.withValues(alpha: 0.2),
            border: Border.all(color: AppColors.medalBronze, width: 1.5),
          ),
          child: const Center(
            child: Text('🥉', style: TextStyle(fontSize: 16)),
          ),
        );
      }
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.surface,
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: Text(
            '#$rank',
            style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrentUser ? colors.primary.withValues(alpha: 0.06) : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? colors.primary.withValues(alpha: 0.4) : colors.border,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          buildMedal(),
          const SizedBox(width: 12),
          WaraAvatar(
            name: name,
            photoUrl: photoUrl,
            radius: 19,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'YOU',
                          style: TextStyle(
                            color: colors.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$specialization • $completedProjects cuts completed',
                  style: TextStyle(color: colors.muted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Rating badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.star.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.star.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.star, size: 14),
                const SizedBox(width: 3),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(color: AppColors.star, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Manager Rate Button
          if (isManager && onRatePressed != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onRatePressed,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  'Rate',
                  style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Embedded Agency Creative Leaderboard Card for Editor Profile Tab
class AgencyLeaderboardCard extends ConsumerWidget {
  const AgencyLeaderboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentUser = ref.watch(authProvider.select((s) => s.user));

    return Consumer(
  builder: (context, ref, _) {
  final snapshot = asSnapshot(ref.watch(editorsProvider(currentUser?.agencyId)));
        final editors = snapshot.data ?? [];

        // Determine user rank & metrics
        int? myRank;
        double myRating = 5.0;
        int myCompleted = 0;

        for (int i = 0; i < editors.length; i++) {
          final e = editors[i];
          if (e['id'] == currentUser?.id || (currentUser?.email != null && e['email'] == currentUser!.email)) {
            myRank = i + 1;
            myRating = (e['rating'] as num?)?.toDouble() ?? 0.0;
            myCompleted = (e['completedProjects'] as num?)?.toInt() ?? 0;
            break;
          }
        }

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.star.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: AppColors.star, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agency Leaderboard',
                          style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Performance ranking inside your agency',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showAgencyLeaderboardModal(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Text('View All', style: TextStyle(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, color: colors.primary, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Personal Standing Highlight
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          myRank != null ? '#$myRank' : 'Unranked',
                          style: TextStyle(
                            color: myRank == 1
                                ? AppColors.star
                                : (myRank == 2 ? AppColors.medalSilver : (myRank == 3 ? AppColors.medalBronze : colors.text)),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('Your Rank', style: TextStyle(color: colors.muted, fontSize: 12)),
                      ],
                    ),
                    Container(width: 1, height: 28, color: colors.border),
                    Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.star, size: 16),
                            const SizedBox(width: 3),
                            Text(
                              myRating.toStringAsFixed(1),
                              style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('Avg Rating', style: TextStyle(color: colors.muted, fontSize: 12)),
                      ],
                    ),
                    Container(width: 1, height: 28, color: colors.border),
                    Column(
                      children: [
                        Text(
                          '$myCompleted',
                          style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text('Completed', style: TextStyle(color: colors.muted, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              // Top 3 preview if editors exist
              if (editors.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('TOP EDITORS', style: TextStyle(color: colors.muted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
                const SizedBox(height: 8),
                Column(
                  children: editors.take(3).toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ed = entry.value;
                    final r = idx + 1;
                    final n = ed['name'] as String? ?? 'Editor';
                    final rat = (ed['rating'] as num?)?.toDouble() ?? 0.0;
                    final cp = (ed['completedProjects'] as num?)?.toInt() ?? 0;
                    final isMe = ed['id'] == currentUser?.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text(
                            r == 1 ? '🥇' : (r == 2 ? '🥈' : '🥉'),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              n + (isMe ? ' (You)' : ''),
                              style: TextStyle(
                                color: isMe ? colors.primary : colors.text,
                                fontSize: 12,
                                fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.star, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                rat.toStringAsFixed(1),
                                style: const TextStyle(color: AppColors.star, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Text('$cp cuts', style: TextStyle(color: colors.muted, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
