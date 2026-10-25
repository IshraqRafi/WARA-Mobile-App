import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/auth_provider.dart';
import 'agency_switch.dart';
import 'motion.dart';

/// Cold-start splash using the agency-switch overlay. Opaque from the first
/// frame; the logo fades/scales in and the bar fills while auth and the
/// profile resolve. Stays up at least [minDuration] and at most
/// [maxDuration], then fades out onto whatever the router chose (role home
/// or login). Input is blocked while it is up. Once per process.
class LaunchSplash extends ConsumerStatefulWidget {
  final Widget child;
  final Duration minDuration;
  final Duration maxDuration;
  const LaunchSplash({
    super.key,
    required this.child,
    this.minDuration = const Duration(milliseconds: 1200),
    this.maxDuration = const Duration(milliseconds: 3000),
  });

  static bool _played = false;

  @visibleForTesting
  static void reset() => _played = false;

  @override
  ConsumerState<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends ConsumerState<LaunchSplash> with TickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, value: 1);
  late final AnimationController _logo = AnimationController(vsync: this);
  late final AnimationController _bar = AnimationController(vsync: this);
  bool _showing = false;
  bool _decided = false;
  bool _minDone = false;
  bool _closing = false;
  Timer? _minTimer;
  Timer? _maxTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    if (LaunchSplash._played) return;
    LaunchSplash._played = true;
    _showing = true;
    final reduced = Motion.reduced(context);
    _logo.duration = Duration(milliseconds: reduced ? 120 : 400);
    _logo.forward();
    _bar.duration = widget.minDuration;
    _bar.animateTo(0.85, curve: Curves.easeInOutCubic);
    _minTimer = Timer(widget.minDuration, () {
      _minDone = true;
      _maybeClose();
    });
    _maxTimer = Timer(widget.maxDuration, () => _close());
  }

  void _maybeClose() {
    if (_minDone && ref.read(authRestoredProvider)) _close();
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _minTimer?.cancel();
    _maxTimer?.cancel();
    final reduced = Motion.reduced(context);
    _bar.duration = const Duration(milliseconds: 200);
    await _bar.animateTo(1, curve: Curves.easeOut).orCancel.catchError((_) {});
    if (!mounted) return;
    _fade.duration = Duration(milliseconds: reduced ? 120 : 300);
    await _fade.reverse().orCancel.catchError((_) {});
    if (mounted) setState(() => _showing = false);
  }

  @override
  void dispose() {
    _minTimer?.cancel();
    _maxTimer?.cancel();
    _fade.dispose();
    _logo.dispose();
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(authRestoredProvider, (_, ready) {
      if (ready) _maybeClose();
    });
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        AbsorbPointer(absorbing: _showing, child: widget.child),
        if (_showing)
          Positioned.fill(
            child: WaraSwitchOverlay(key: const Key('launch_splash'), fade: _fade, bar: _bar, logo: _logo),
          ),
      ],
    );
  }
}
