import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WaraToast {
  static void show(
    BuildContext context, {
      required String message,
      IconData icon = Icons.check_circle_outline_rounded,
      Duration duration = const Duration(seconds: 4),
    }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _WaraToastWidget(
        message: message,
        icon: icon,
        duration: duration,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _WaraToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _WaraToastWidget({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_WaraToastWidget> createState() => _WaraToastWidgetState();
}

class _WaraToastWidgetState extends State<_WaraToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOutCubic),
    ));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.15, curve: Curves.easeOut),
    ));

    _ctrl.forward();

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: colors.isDark ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(widget.icon, color: colors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onDismiss,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colors.card,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.border),
                            ),
                            child: Icon(Icons.close_rounded, color: colors.muted, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // White progress timer bar running from left to right
                  AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) {
                      return LinearProgressIndicator(
                        value: _ctrl.value,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                        minHeight: 3,
                      );
                    },
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
