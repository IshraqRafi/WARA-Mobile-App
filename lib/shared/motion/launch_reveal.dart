import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/wara_logo.dart';
import 'motion.dart';

/// Cold-start brand reveal drawn over the first frames of the app: the logo
/// scales and fades in, then "wara.io" rises letter by letter, then the
/// overlay fades away. 850ms total, once per process, never blocks auth
/// (the app builds and signs in underneath). Skipped with reduce-motion.
class LaunchReveal extends StatefulWidget {
  final Widget child;
  const LaunchReveal({super.key, required this.child});

  static const Duration total = Duration(milliseconds: 850);
  static const String word = 'wara.io';
  static bool _played = false;

  /// Test hook: let the reveal play again.
  @visibleForTesting
  static void reset() => _played = false;

  @override
  State<LaunchReveal> createState() => _LaunchRevealState();
}

class _LaunchRevealState extends State<LaunchReveal> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  bool _decided = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_decided) return;
    _decided = true;
    if (LaunchReveal._played || Motion.reduced(context)) {
      LaunchReveal._played = true;
      return;
    }
    LaunchReveal._played = true;
    _c = AnimationController(vsync: this, duration: LaunchReveal.total)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          setState(() {
            _c?.dispose();
            _c = null;
          });
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null) return widget.child;
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(child: _RevealOverlay(animation: c)),
          ),
        ),
      ],
    );
  }
}

class _RevealOverlay extends StatelessWidget {
  final Animation<double> animation;
  const _RevealOverlay({required this.animation});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logoIn = CurvedAnimation(parent: animation, curve: const Interval(0, 0.5, curve: Curves.easeOutCubic));
    final out = CurvedAnimation(parent: animation, curve: const Interval(0.78, 1, curve: Curves.easeIn));
    const word = LaunchReveal.word;
    final style = TextStyle(
      color: colors.text,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      decoration: TextDecoration.none,
    );
    return FadeTransition(
      opacity: ReverseAnimation(out),
      child: ColoredBox(
        color: colors.bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: logoIn,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.82, end: 1).animate(logoIn),
                  child: const WaraLogo(size: 96),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < word.length; i++)
                    _Letter(
                      char: word[i],
                      style: style,
                      // Letters start 0.22..0.48 and each rises over 0.28.
                      animation: CurvedAnimation(
                        parent: animation,
                        curve: Interval(0.22 + i * 0.04, 0.5 + i * 0.04, curve: Curves.easeOutCubic),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Letter extends StatelessWidget {
  final String char;
  final TextStyle style;
  final Animation<double> animation;
  const _Letter({required this.char, required this.style, required this.animation});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(animation),
        child: Text(char, style: style),
      ),
    );
  }
}
