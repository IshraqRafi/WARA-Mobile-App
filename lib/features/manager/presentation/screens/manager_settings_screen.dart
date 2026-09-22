import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../../shared/widgets/wara_theme_toggle.dart';
import '../../../../shared/widgets/wara_toast.dart';
import '../../../auth/domain/auth_provider.dart';
import '../../../projects/domain/project_provider.dart';

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
        initialChildSize: 0.7,
        maxChildSize: 0.9,
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
                'Editors connected to ${user?.agencyName ?? "your agency room"}',
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
                    Text(
                      'Join Key: ${user?.agencyJoinKey ?? "WARA-7742"}',
                      style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        final key = user?.agencyJoinKey ?? 'WARA-7742';
                        Clipboard.setData(ClipboardData(text: key));
                        WaraToast.show(context, message: 'Copied Join Key "$key" to clipboard!', icon: Icons.copy_rounded);
                      },
                      child: Text('COPY', style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ref.read(firestoreServiceProvider).streamEditors(agencyId: user?.agencyId),
                  builder: (context, snapshot) {
                    final cloudEditors = snapshot.data ?? [];
                    final activeEditors = cloudEditors.where((e) => e['name'] != null && (e['name'] as String).isNotEmpty).toList();

                    if (activeEditors.isEmpty) {
                      return ListView(
                        controller: scrollController,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.people_outline_rounded, color: colors.muted, size: 36),
                                const SizedBox(height: 12),
                                Text(
                                  'No editors in this room yet',
                                  style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Share your Agency Join Key with editors. Once they enter your room, their live profiles will appear here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4),
                                ),
                              ],
                            ),
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
                        return _EditorCard(
                          name: e['name'] as String? ?? 'Editor',
                          photoUrl: e['photoUrl'] as String?,
                          specialization: e['specialization'] as String? ?? 'Video Editor',
                          skills: List<String>.from(e['skills'] ?? ['Video Editing']),
                          hoursPerWeek: (e['hoursPerWeek'] as num?)?.toInt() ?? 35,
                          activeDays: List<String>.from(e['activeDays'] ?? ['Mon', 'Tue', 'Wed']),
                          portfolioLink: e['portfolioLink'] as String?,
                          email: e['email'] as String?,
                          isDemo: false,
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
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Sun/Moon Theme Toggle
              Row(
                children: [
                  const WaraLogo(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Agency OS Settings', style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(
                          '${user?.agencyName ?? "Wara Media Group"} • Manager Controls',
                          style: TextStyle(color: colors.muted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const WaraThemeToggle(),
                ],
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
                          Text(user?.name ?? 'Ishraq Rafi', style: TextStyle(color: colors.text, fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(user?.email ?? 'abdullahishraqrafi@gmail.com', style: TextStyle(color: colors.muted, fontSize: 12)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(6), border: Border.all(color: colors.border)),
                            child: Text('Agency Director • Admin', style: TextStyle(color: colors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Agency Workspace & Join Key Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.meeting_room_rounded, color: colors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.agencyName ?? 'Agency Workspace',
                                style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Private Team Workspace & Room',
                                style: TextStyle(color: colors.muted, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              const Text('Active Room', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Join Key Box with 1-Tap Copy & Regenerate
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.vpn_key_rounded, color: colors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AGENCY JOIN KEY', style: TextStyle(color: colors.muted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
                                const SizedBox(height: 2),
                                Text(
                                  user?.agencyJoinKey ?? 'WARA-7742',
                                  style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                              ],
                            ),
                          ),
                          // Copy Button
                          InkWell(
                            onTap: () {
                              final key = user?.agencyJoinKey ?? 'WARA-7742';
                              Clipboard.setData(ClipboardData(text: key));
                              WaraToast.show(context, message: 'Copied Join Key "$key" to clipboard!', icon: Icons.copy_rounded);
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.copy_rounded, color: colors.isDark ? Colors.black : Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Copy',
                                    style: TextStyle(
                                      color: colors.isDark ? Colors.black : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Regenerate Key Action + Subtitle
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Share this key with editors so they can enter your agency room.',
                            style: TextStyle(color: colors.muted, fontSize: 11, height: 1.3),
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: colors.surface,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                title: Text('Regenerate Join Key?', style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                                content: Text(
                                  'This will generate a new join key for your agency. Existing editors stay connected, but new editors will need the updated key.',
                                  style: TextStyle(color: colors.muted, fontSize: 13),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text('Cancel', style: TextStyle(color: colors.muted)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colors.primary,
                                      foregroundColor: colors.isDark ? Colors.black : Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Regenerate'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final newKey = await ref.read(authProvider.notifier).regenerateAgencyKey();
                              if (context.mounted && newKey != null) {
                                WaraToast.show(context, message: 'New Agency Key generated: $newKey', icon: Icons.refresh_rounded);
                              }
                            }
                          },
                          icon: Icon(Icons.refresh_rounded, color: colors.muted, size: 14),
                          label: Text('Regenerate', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('AGENCY MANAGEMENT OPTIONS', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.people_outline_rounded,
                title: 'Editor & Staff Team Seats',
                subtitle: 'View live registered creative editors in Firestore',
                onTap: () => _showTeamModal(context, ref),
              ),
              _SettingsTile(
                icon: Icons.domain_rounded,
                title: 'Agency Profile & Branding',
                subtitle: '${user?.agencyName ?? "Wara Media Group"} (wara.io)',
                onTap: () {},
              ),
              _SettingsTile(icon: Icons.integration_instructions_outlined, title: 'Ad Channel Integrations', subtitle: 'Meta, Google Ads, TikTok Connected', onTap: () {}),
              _SettingsTile(icon: Icons.credit_card_outlined, title: 'Agency Subscription', subtitle: r'wara.io Scale Plan (৳29,900/mo)', onTap: () {}),
              _SettingsTile(icon: Icons.security_rounded, title: 'Security & SSO Audit', subtitle: 'Cloud Auth & Role Whitelist Enforced', onTap: () {}),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                  icon: Icon(Icons.logout_rounded, color: colors.muted, size: 18),
                  label: Text('Sign Out of Manager Dashboard', style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: colors.border),
                    backgroundColor: colors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
          child: Icon(icon, color: colors.text, size: 20),
        ),
        title: Text(title, style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: colors.muted, fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, color: colors.muted, size: 20),
      ),
    );
  }
}

class _EditorCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final String specialization;
  final List<String> skills;
  final int hoursPerWeek;
  final List<String> activeDays;
  final String? portfolioLink;
  final String? email;
  final bool isDemo;

  const _EditorCard({
    required this.name,
    this.photoUrl,
    required this.specialization,
    required this.skills,
    required this.hoursPerWeek,
    required this.activeDays,
    this.portfolioLink,
    this.email,
    required this.isDemo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WaraAvatar(
                name: name,
                photoUrl: photoUrl,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDemo ? colors.muted.withValues(alpha: 0.15) : Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDemo ? 'Demo' : 'Online',
                            style: TextStyle(
                              color: isDemo ? colors.muted : Colors.greenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(specialization, style: TextStyle(color: colors.muted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          if (email != null) ...[
            const SizedBox(height: 8),
            Text('Contact: $email', style: TextStyle(color: colors.muted, fontSize: 11)),
          ],
          const SizedBox(height: 12),
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
              child: Text(s, style: TextStyle(color: colors.text, fontSize: 10)),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$hoursPerWeek hrs/wk availability', style: TextStyle(color: colors.muted, fontSize: 11)),
              Text('Days: ${activeDays.join(', ')}', style: TextStyle(color: colors.muted, fontSize: 11)),
            ],
          ),
          if (portfolioLink != null && portfolioLink!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Portfolio: $portfolioLink', style: TextStyle(color: colors.muted, fontSize: 11, decoration: TextDecoration.underline)),
          ],
        ],
      ),
    );
  }
}
