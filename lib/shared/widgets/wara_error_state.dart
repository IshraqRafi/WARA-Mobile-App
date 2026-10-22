import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Turns a raw error into a short, user-facing message.
String friendlyErrorMessage(Object? error) {
  final raw = error?.toString() ?? '';
  if (raw.contains('permission-denied')) {
    return 'You don\'t have access to this data. Check that you are signed in to the right agency.';
  }
  if (raw.contains('unavailable') || raw.contains('network')) {
    return 'Can\'t reach the server. Check your internet connection.';
  }
  return 'Something went wrong while loading. Please try again.';
}

/// Shared error state: icon, title, message and a Retry button.
/// Use it wherever a load failure would otherwise leave the screen blank.
class WaraErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  const WaraErrorState({
    super.key,
    this.title = 'Couldn\'t load this',
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: compact ? 28 : 40, color: colors.error),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted, fontSize: 12, height: 1.4),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: Icon(Icons.refresh_rounded, size: 18, color: colors.primary),
                  label: Text('Retry', style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
