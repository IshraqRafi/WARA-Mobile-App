import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/chat/domain/chat_provider.dart';
import '../../features/notifications/domain/notification_provider.dart';
import '../../features/payments/domain/payout.dart';
import '../../features/projects/domain/project_provider.dart';
import '../widgets/wara_logo.dart';
import '../widgets/wara_toast.dart';
import 'motion.dart';

/// (uid, agencyId, role) of the signed-in user. A change of agencyId for the
/// same uid is an agency switch (sign-in itself is not: the uid changes).
final agencyIdentityProvider = Provider<(String?, String?, UserRole?)>((ref) {
  return ref.watch(authProvider.select((s) => (s.user?.id, s.user?.agencyId, s.user?.role)));
});

/// Refetch the profile and rebuild agency-scoped providers.
Future<void> defaultAgencyReload(WidgetRef ref) async {
  await ref.read(authProvider.notifier).retryProfileLoad();
  ref.invalidate(projectsProvider);
  ref.invalidate(myProfileProvider);
  ref.invalidate(chatProvider);
  ref.invalidate(notificationsProvider);
  ref.invalidate(payoutsProvider);
}

String agencyHomeFor(UserRole? role) => role == UserRole.manager ? '/manager/workflow' : '/editor/available';

/// Wraps the app. When the agencyId changes for the same user, a full-screen
/// overlay (black in dark, white in light) fades in with the logo and a slim
/// bar, reloads data, routes home underneath, then fades out. Input is
/// blocked throughout.
class AgencySwitchHost extends ConsumerStatefulWidget {
  final Widget child;
  final Future<void> Function(WidgetRef ref)? reload;
  final void Function(WidgetRef ref, String route)? navigate;
  final void Function(String message)? onError;
  final Duration minDuration;
  final Duration timeout;

  const AgencySwitchHost({
    super.key,
    required this.child,
    this.reload,
    this.navigate,
    this.onError,
    this.minDuration = const Duration(milliseconds: 2500),
    this.timeout = const Duration(seconds: 12),
  });

  @override
  ConsumerState<AgencySwitchHost> createState() => _AgencySwitchHostState();
}

class _AgencySwitchHostState extends ConsumerState<AgencySwitchHost> with TickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this);
  late final AnimationController _bar = AnimationController(vsync: this);
  bool _running = false;

  @override
  void dispose() {
    _fade.dispose();
    _bar.dispose();
    super.dispose();
  }

  Future<void> _run(UserRole? role) async {
    if (_running) return;
    final reduced = Motion.reduced(context);
    final fadeDur = reduced ? const Duration(milliseconds: 120) : const Duration(milliseconds: 300);
    setState(() => _running = true);
    _bar.value = 0;
    _fade.duration = fadeDur;
    await _fade.forward(from: 0).orCancel.catchError((_) {});

    // Bar eases to 90% over minDuration; data load runs alongside.
    _bar.duration = widget.minDuration;
    final barTicker = _bar.animateTo(0.9, curve: Curves.easeInOutCubic);
    String? error;
    try {
      await (widget.reload ?? defaultAgencyReload)(ref).timeout(widget.timeout);
    } catch (e) {
      debugPrint('Agency switch reload failed: $e');
      error = e is TimeoutException ? 'Taking too long. Pull to refresh.' : "Couldn't load agency data";
    }
    await barTicker.orCancel.catchError((_) {});
    if (!mounted) return;
    _bar.duration = const Duration(milliseconds: 220);
    await _bar.animateTo(1, curve: Curves.easeOut).orCancel.catchError((_) {});
    if (!mounted) return;

    final route = agencyHomeFor(role);
    if (widget.navigate != null) {
      widget.navigate!(ref, route);
    } else {
      ref.read(routerProvider).go(route);
    }
    await _fade.reverse().orCancel.catchError((_) {});
    if (!mounted) return;
    setState(() => _running = false);
    if (error != null) _toast(error);
  }

  void _toast(String message) {
    if (widget.onError != null) return widget.onError!(message);
    final ctx = ref.read(routerProvider).routerDelegate.navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) WaraToast.show(ctx, message: message, icon: Icons.error_outline_rounded);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<(String?, String?, UserRole?)>(agencyIdentityProvider, (prev, next) {
      final (pUid, pAgency, _) = prev ?? (null, null, null);
      final (uid, agency, role) = next;
      if (uid != null && uid == pUid && (agency ?? '').isNotEmpty && agency != pAgency) {
        _run(role);
      }
    });
    final reduced = Motion.reduced(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? Colors.black : Colors.white;
    final fg = dark ? Colors.white : Colors.black;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        AbsorbPointer(absorbing: _running, child: widget.child),
        if (_running)
          Positioned.fill(
            child: AnimatedBuilder(
              key: const Key('agency_switch_overlay'),
              animation: Listenable.merge([_fade, _bar]),
              builder: (_, _) {
                final f = Curves.easeOut.transform(_fade.value);
                final logoT = Curves.easeOutCubic.transform(_fade.value);
                return Opacity(
                  opacity: f,
                  child: ColoredBox(
                    color: bg,
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Opacity(
                          opacity: logoT,
                          child: Transform.scale(
                            scale: reduced ? 1 : 0.96 + 0.04 * logoT,
                            child: const WaraLogo(size: 64),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Opacity(
                          opacity: f,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 140,
                              height: 3,
                              child: Stack(children: [
                                Positioned.fill(child: ColoredBox(color: fg.withValues(alpha: 0.10))),
                                FractionallySizedBox(
                                  key: const Key('agency_switch_bar'),
                                  widthFactor: _bar.value,
                                  heightFactor: 1,
                                  alignment: Alignment.centerLeft,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: fg.withValues(alpha: 0.55),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
