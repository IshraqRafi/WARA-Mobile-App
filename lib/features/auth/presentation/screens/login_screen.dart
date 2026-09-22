import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../domain/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(text: '');
  final _passwordCtrl = TextEditingController(text: '');
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.manager;
  bool _isSignUpMode = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      _isSignUpMode = false;
      _errorMessage = null;
      _emailCtrl.clear();
      _passwordCtrl.clear();
    });
  }

  Future<void> _handleAuthAction() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_isSignUpMode && _selectedRole == UserRole.editor) {
      // Create new Editor Account
      final res = await ref.read(authProvider.notifier).registerEditor(
            _emailCtrl.text,
            _passwordCtrl.text,
          );
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!res.success) {
            _errorMessage = res.error ?? 'Registration failed. Please try again.';
          }
        });
      }
    } else {
      // Regular Login
      final res = await ref.read(authProvider.notifier).login(
            _emailCtrl.text,
            _passwordCtrl.text,
            selectedRole: _selectedRole,
          );
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (!res.success) {
            _errorMessage = res.error ?? 'Authentication failed. Please verify credentials.';
          }
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    final res = await ref.read(authProvider.notifier).signInWithGoogle(_selectedRole);

    if (mounted) {
      setState(() {
        _isGoogleLoading = false;
        if (!res.success) {
          _errorMessage = res.error;
        }
      });
    }
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
                  // ── wara.io Logo & Header ────────────────────────────────
                  const Center(
                    child: WaraLogo(size: 72),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'wara.io',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'MEDIA AGENCY OPERATING SYSTEM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Role Selector Tabs ───────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onRoleChanged(UserRole.manager),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == UserRole.manager ? colors.card : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: _selectedRole == UserRole.manager
                                    ? Border.all(color: colors.primary.withValues(alpha: 0.2))
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings_outlined,
                                    size: 16,
                                    color: _selectedRole == UserRole.manager ? colors.primary : colors.muted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Manager Access',
                                    style: TextStyle(
                                      color: _selectedRole == UserRole.manager ? colors.text : colors.muted,
                                      fontSize: 13,
                                      fontWeight: _selectedRole == UserRole.manager ? FontWeight.bold : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _onRoleChanged(UserRole.editor),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == UserRole.editor ? colors.card : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: _selectedRole == UserRole.editor
                                    ? Border.all(color: colors.primary.withValues(alpha: 0.2))
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.video_camera_back_outlined,
                                    size: 16,
                                    color: _selectedRole == UserRole.editor ? colors.primary : colors.muted,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Editor Portal',
                                    style: TextStyle(
                                      color: _selectedRole == UserRole.editor ? colors.text : colors.muted,
                                      fontSize: 13,
                                      fontWeight: _selectedRole == UserRole.editor ? FontWeight.bold : FontWeight.w500,
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
                  const SizedBox(height: 24),

                  // ── Login Card ───────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedRole == UserRole.manager
                              ? 'Agency Manager Access'
                              : (_isSignUpMode ? 'Create Editor Account' : 'Editor Workspace Sign In'),
                          style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedRole == UserRole.manager
                              ? 'Restricted to authorized agency administrators'
                              : (_isSignUpMode
                                  ? 'Register to join the creative team and claim projects'
                                  : 'Open access: Sign in with your Google account or email'),
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 20),

                        // Error Banner Warning
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.isDark ? Colors.black : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: colors.warningRed, width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: colors.warningRed, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(color: colors.warningRed, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Text('Email Address', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          style: TextStyle(color: colors.text, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'name@agency.com',
                            hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                            prefixIcon: Icon(Icons.email_outlined, color: colors.muted, size: 20),
                            fillColor: colors.card,
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text('Password', style: TextStyle(color: colors.text, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: TextStyle(color: colors.text, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: _isSignUpMode ? 'Min 6 characters' : '••••••••',
                            hintStyle: TextStyle(color: colors.muted, fontSize: 13),
                            prefixIcon: Icon(Icons.lock_outline, color: colors.muted, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: colors.muted, size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            fillColor: colors.card,
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _isGoogleLoading) ? null : _handleAuthAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.isDark ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: colors.isDark ? Colors.black : Colors.white, strokeWidth: 2.5))
                                : Text(
                                    _selectedRole == UserRole.manager
                                        ? 'Sign In as Manager'
                                        : (_isSignUpMode ? 'Create Account & Setup Profile' : 'Sign In as Editor'),
                                    style: TextStyle(color: colors.isDark ? Colors.black : Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: colors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('OR', style: TextStyle(color: colors.muted, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            Expanded(child: Divider(color: colors.border)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Google Sign-In Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: (_isLoading || _isGoogleLoading) ? null : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: colors.border, width: 1.2),
                              backgroundColor: colors.card,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: _isGoogleLoading
                                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: colors.primary, strokeWidth: 2))
                                : Icon(Icons.g_mobiledata_rounded, color: colors.primary, size: 24),
                            label: Text(
                              _selectedRole == UserRole.manager
                                  ? 'Continue with Google (Manager)'
                                  : (_isSignUpMode ? 'Sign Up with Google (Editor)' : 'Continue with Google (Editor)'),
                              style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),

                        // Editor Sign In / Sign Up Mode Toggle
                        if (_selectedRole == UserRole.editor) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  _isSignUpMode = !_isSignUpMode;
                                  _errorMessage = null;
                                });
                              },
                              child: Text(
                                _isSignUpMode
                                    ? 'Already have an account? Sign In'
                                    : "New editor? Create an account",
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, color: colors.muted, size: 14),
                      const SizedBox(width: 6),
                      Text('wara.io Verified Agency Infrastructure', style: TextStyle(color: colors.muted, fontSize: 11)),
                    ],
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
