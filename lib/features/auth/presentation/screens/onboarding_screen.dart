import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_banner.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../../../shared/widgets/wara_section_header.dart';
import '../../domain/auth_provider.dart';

/// First run for a new Google account. The role was chosen on the login
/// screen: managers name their agency; editors continue to profile setup,
/// where they enter the agency join key.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _agencyCtrl = TextEditingController();
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
    final isManager = ref.read(authProvider).pendingUser?.role == UserRole.manager;
    final res = isManager
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
    final isManager = pending?.role == UserRole.manager;

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
                        if (isManager)
                          WaraSectionCard(
                            title: 'Agency',
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
                              : Text(isManager ? 'Create agency' : 'Continue'),
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
