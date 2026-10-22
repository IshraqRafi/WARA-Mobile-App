import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import '../../../../shared/motion/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/google_g_logo.dart';
import '../../../../shared/widgets/wara_banner.dart';
import '../../../../shared/widgets/wara_logo.dart';
import '../../domain/auth_provider.dart';

/// Google sign-in with a role selector. The selected role applies to new
/// accounts; existing accounts always keep their stored role.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  UserRole _role = UserRole.editor;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final res = await ref.read(authProvider.notifier).signInWithGoogle(role: _role);
    final mismatch = res.roleMismatch;
    if (mismatch != null) {
      messenger.showSnackBar(SnackBar(
        content: Text('Signed in as ${mismatch == UserRole.manager ? 'Manager' : 'Editor'}'),
        duration: const Duration(seconds: 3),
      ));
    }
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
                  const Center(child: WaraLogo(size: 96)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(AppInfo.name, textAlign: TextAlign.center, style: text.headlineMedium),
                  const SizedBox(height: AppSpacing.xxl),
                  RoleSlider(
                    value: _role,
                    enabled: !_isLoading,
                    onChanged: (r) => setState(() => _role = r),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_errorMessage != null) ...[
                    WaraBanner(message: _errorMessage!),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  LayoutBuilder(
                    builder: (context, box) => Center(
                      child: Semantics(
                        button: true,
                        label: _isLoading ? 'Signing in with Google' : 'Continue with Google',
                        excludeSemantics: true,
                        child: Pressable(
                          enabled: !_isLoading,
                          child: AnimatedContainer(
                            duration: Motion.of(context, Motion.medium),
                            curve: Motion.curve,
                            width: _isLoading ? 52 : box.maxWidth,
                            height: 52,
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(color: colors.border),
                            ),
                            child: Material(
                              type: MaterialType.transparency,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(26),
                                onTap: _isLoading ? null : _handleGoogleSignIn,
                                child: AnimatedSwitcher(
                                  duration: Motion.of(context, Motion.fast),
                                  child: _isLoading
                                      ? SizedBox.square(
                                          key: const ValueKey('busy'),
                                          dimension: 22,
                                          child: CircularProgressIndicator(color: colors.primary, strokeWidth: 2.5),
                                        )
                                      : FittedBox(
                                          key: const ValueKey('idle'),
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const GoogleGLogo(size: 20),
                                              const SizedBox(width: AppSpacing.md),
                                              Text('Continue with Google', style: text.titleMedium),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('By continuing you accept the Terms and Privacy Policy.', textAlign: TextAlign.center, style: text.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-segment [Editor | Manager] selector with a spring-driven thumb.
class RoleSlider extends StatefulWidget {
  final UserRole value;
  final ValueChanged<UserRole> onChanged;
  final bool enabled;

  const RoleSlider({super.key, required this.value, required this.onChanged, this.enabled = true});

  static const _roles = [UserRole.editor, UserRole.manager];
  static const _labels = {UserRole.editor: 'Editor', UserRole.manager: 'Manager'};

  @override
  State<RoleSlider> createState() => _RoleSliderState();
}

class _RoleSliderState extends State<RoleSlider> with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(mass: 1, stiffness: 420, damping: 26);
  late final AnimationController _x = AnimationController.unbounded(vsync: this, value: _target);

  double get _target => widget.value == RoleSlider._roles.first ? -1 : 1;

  @override
  void didUpdateWidget(RoleSlider old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    if (Motion.reduced(context)) {
      _x.value = _target;
    } else {
      _x.animateWith(SpringSimulation(_spring, _x.value, _target, _x.velocity));
    }
  }

  @override
  void dispose() {
    _x.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final value = widget.value;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Stack(
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _x,
              builder: (context, child) => Align(alignment: Alignment(_x.value, 0), child: child),
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final r in RoleSlider._roles)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: r == value,
                    label: RoleSlider._labels[r],
                    excludeSemantics: true,
                    child: InkWell(
                      key: ValueKey('role_${r.name}'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: widget.enabled
                          ? () {
                              if (r != value) HapticFeedback.selectionClick();
                              widget.onChanged(r);
                            }
                          : null,
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: Motion.of(context, const Duration(milliseconds: 220)),
                          style: (text.labelLarge ?? const TextStyle()).copyWith(
                            color: r == value ? onPrimary : colors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                          child: Text(RoleSlider._labels[r]!),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
