import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_logo.dart';
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
    final pending = ref.watch(authProvider.select((s) => s.pendingUser));
    final firstName = (pending?.name ?? '').split(' ').first;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: WaraLogo(size: 56)),
                  const SizedBox(height: 20),
                  Text(
                    firstName.isEmpty ? 'Welcome to wara.io' : 'Welcome, $firstName',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.text, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'How will you use wara.io?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  _OptionCard(
                    icon: Icons.business_center_rounded,
                    title: 'Create an agency',
                    subtitle: 'Manage projects, invite editors and track payouts.',
                    selected: _path == _Path.createAgency,
                    onTap: () => setState(() => _path = _Path.createAgency),
                  ),
                  const SizedBox(height: 12),
                  _OptionCard(
                    icon: Icons.movie_edit,
                    title: 'Join an agency as an editor',
                    subtitle: 'Use the join key your agency manager shared with you.',
                    selected: _path == _Path.joinAgency,
                    onTap: () => setState(() => _path = _Path.joinAgency),
                  ),
                  if (_path == _Path.createAgency) ...[
                    const SizedBox(height: 20),
                    TextField(
                      controller: _agencyCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(color: colors.text),
                      decoration: InputDecoration(
                        labelText: 'Agency name',
                        labelStyle: TextStyle(color: colors.muted),
                        filled: true,
                        fillColor: colors.surface,
                        prefixIcon: Icon(Icons.apartment_rounded, color: colors.muted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                      ),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(_errorMessage!, style: TextStyle(color: colors.error, fontSize: 12)),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colors.isDark ? Colors.black : Colors.white, strokeWidth: 2.5))
                        : Text(
                            _path == _Path.createAgency ? 'Create agency' : 'Continue',
                            style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : () => ref.read(authProvider.notifier).logout(),
                    child: Text(
                      pending == null ? 'Sign out' : 'Not ${pending.email}? Sign out',
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? colors.primary.withValues(alpha: 0.08) : colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? colors.primary : colors.border, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? colors.primary : colors.muted, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: colors.muted, fontSize: 12, height: 1.35)),
                ],
              ),
            ),
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? colors.primary : colors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}
