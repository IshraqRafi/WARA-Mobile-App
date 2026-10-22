import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../features/projects/domain/project_provider.dart';

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
    final text = Theme.of(context).textTheme;
    final badge = compact ? 48.0 : 64.0;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xxl),
        child: Semantics(
          liveRegion: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(color: colors.errorTint, shape: BoxShape.circle),
                child: Icon(Icons.cloud_off_rounded, size: badge * 0.45, color: colors.error),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(title, textAlign: TextAlign.center, style: text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(message, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: colors.muted)),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen "Couldn't load projects" state with Retry, shared by every
/// projects tab.
class ProjectsLoadError extends ConsumerWidget {
  final Object error;
  const ProjectsLoadError({super.key, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        backgroundColor: context.colors.bg,
        body: SafeArea(
          child: WaraErrorState(
            title: 'Couldn\'t load projects',
            message: friendlyErrorMessage(error),
            onRetry: () => ref.read(projectsProvider.notifier).retry(),
          ),
        ),
      );
}
