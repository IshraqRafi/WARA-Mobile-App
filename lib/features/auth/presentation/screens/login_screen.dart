import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/google_g_logo.dart';
import '../../../../shared/widgets/wara_banner.dart';
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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin(context), vertical: AppSpacing.xxl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: WaraLogo(size: 72)),
                  const SizedBox(height: AppSpacing.xl),
                  Text(AppInfo.name, textAlign: TextAlign.center, style: text.displayLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    AppInfo.tagline.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: text.labelMedium?.copyWith(letterSpacing: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Run projects, editors and payouts for your media agency in one place.',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  if (_errorMessage != null) ...[
                    WaraBanner(message: _errorMessage!),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  SizedBox(
                    height: 52,
                    child: Semantics(
                      button: true,
                      label: _isLoading ? 'Signing in with Google' : 'Continue with Google',
                      excludeSemantics: true,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: colors.card,
                          disabledBackgroundColor: colors.card,
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        ),
                        child: _isLoading
                            ? SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(color: colors.primary, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const GoogleGLogo(size: 20),
                                  const SizedBox(width: AppSpacing.md),
                                  Text('Continue with Google', style: text.titleMedium),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'By continuing you agree to the wara.io Terms of Service and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall,
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
