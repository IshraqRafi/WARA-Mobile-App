import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_avatar.dart';
import '../../../auth/domain/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Agency Workspace',
                style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
              ),
              const SizedBox(height: 2),
              Text(
                'wara.io OS Settings & Team Controls',
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // User & Agency Info Card
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
                      radius: 28,
                      fontSize: 20,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Alex Vance',
                            style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'director@wara.io',
                            style: TextStyle(color: colors.muted, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: colors.border),
                            ),
                            child: Text(
                              user?.role.name ?? 'Agency Director',
                              style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'WORKSPACE CONFIGURATION',
                style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),

              _SettingsTile(
                icon: Icons.domain_rounded,
                title: 'Agency Identity',
                subtitle: 'Wara Media Group • wara.io domain',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.people_outline_rounded,
                title: 'Team Seats & Permissions',
                subtitle: '8 active seats (2 Directors, 6 Managers)',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.integration_instructions_outlined,
                title: 'Ad Channel Integrations',
                subtitle: 'Meta, Google Ads, TikTok Connected',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.credit_card_outlined,
                title: 'Billing & Enterprise Plan',
                subtitle: r'wara.io Agency Scale (৳29,900/mo)',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.security_rounded,
                title: 'Security & SSO Audit',
                subtitle: '2FA Enforced for all managers',
                onTap: () {},
              ),
              const SizedBox(height: 28),

              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                  icon: Icon(Icons.logout_rounded, color: colors.warningRed, size: 18),
                  label: Text(
                    'Sign Out of wara.io',
                    style: TextStyle(color: colors.warningRed, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
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

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, color: colors.text, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: colors.muted, fontSize: 12),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: colors.muted, size: 20),
      ),
    );
  }
}
