import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_banner.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../../shared/widgets/wara_section_header.dart';
import '../../domain/auth_provider.dart';

/// First run for a new Google account: create an agency (manager) or join one
/// (editor, finishes on the profile setup screen with a join key).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

enum _Path { createAgency, joinAgency }

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _agencyCtrl = TextEditingController();
  _Path _path = _Path.createAgency;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _agencyCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final notifier = ref.read(authProvider.notifier);
    final res = _path == _Path.createAgency
        ? await notifier.createAgencyAsManager(_agencyCtrl.text)
        : await notifier.continueAsEditor();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = res.success ? null : res.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final pending = ref.watch(authProvider.select((s) => s.pendingUser));
    final firstName = (pending?.name ?? '').split(' ').first;
    final margin = AppSpacing.screenMargin(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(margin, AppSpacing.xxl, margin, AppSpacing.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: WaraLogo(size: 56)),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          firstName.isEmpty ? 'Welcome to wara.io' : 'Welcome, $firstName',
                          textAlign: TextAlign.center,
                          style: text.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('How will you use wara.io?', textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.muted)),
                        WaraSectionCard(
                          title: 'Choose your role',
                          divided: false,
                          contentPadding: const EdgeInsets.all(AppSpacing.md),
                          children: [
                            _OptionCard(
                              icon: Icons.business_center_rounded,
                              title: 'Create an agency',
                              subtitle: 'Manage projects, invite editors and track payouts.',
                              selected: _path == _Path.createAgency,
                              onTap: () => setState(() => _path = _Path.createAgency),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _OptionCard(
                              icon: Icons.movie_edit,
                              title: 'Join an agency as an editor',
                              subtitle: 'Use the join key your agency manager shared with you.',
                              selected: _path == _Path.joinAgency,
                              onTap: () => setState(() => _path = _Path.joinAgency),
                            ),
                          ],
                        ),
                        if (_path == _Path.createAgency)
                          WaraSectionCard(
                            title: 'Agency details',
                            divided: false,
                            contentPadding: const EdgeInsets.all(AppSpacing.lg),
                            children: [
                              TextField(
                                controller: _agencyCtrl,
                                textCapitalization: TextCapitalization.words,
                                style: text.bodyLarge,
                                decoration: const InputDecoration(
                                  labelText: 'Agency name',
                                  prefixIcon: Icon(Icons.apartment_rounded),
                                ),
                              ),
                            ],
                          ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppSpacing.lg),
                          WaraBanner(message: _errorMessage!),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Pinned action bar.
            Container(
              decoration: BoxDecoration(color: colors.bg, border: Border(top: BorderSide(color: colors.border))),
              padding: EdgeInsets.fromLTRB(margin, AppSpacing.md, margin, AppSpacing.sm),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _continue,
                          child: _isLoading
                              ? SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2.5),
                                )
                              : Text(_path == _Path.createAgency ? 'Create agency' : 'Continue'),
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : () => ref.read(authProvider.notifier).logout(),
                        style: TextButton.styleFrom(foregroundColor: colors.muted),
                        child: Text(
                          pending == null ? 'Sign out' : 'Not ${pending.email}? Sign out',
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: selected ? colors.primaryTint : colors.surface,
            borderRadius: AppRadius.brMd,
            border: Border.all(color: selected ? colors.primary : colors.border, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? colors.primary : colors.muted, size: 24),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: text.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: text.bodySmall),
                  ],
                ),
              ),
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? colors.primary : colors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
