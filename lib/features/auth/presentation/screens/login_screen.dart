import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../domain/auth_provider.dart';

/// Google is the only sign-in method. New accounts continue to onboarding.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final res = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = res.success ? null : res.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: WaraLogo(size: 72)),
                  const SizedBox(height: 20),
                  Text(
                    'wara.io',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.text, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'MEDIA AGENCY OPERATING SYSTEM',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Run projects, editors and payouts for your media agency in one place.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.text, fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 36),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!, style: TextStyle(color: colors.error, fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colors.border, width: 1.2),
                        backgroundColor: colors.card,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isLoading
                          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: colors.primary, strokeWidth: 2))
                          : Icon(Icons.g_mobiledata_rounded, color: colors.primary, size: 26),
                      label: Text(
                        'Continue with Google',
                        style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'By continuing you agree to the wara.io Terms of Service and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.muted, fontSize: 11, height: 1.4),
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
