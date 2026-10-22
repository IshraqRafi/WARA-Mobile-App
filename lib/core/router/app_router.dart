import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/editor/presentation/screens/editor_profile_setup_screen.dart';
import '../../features/editor/presentation/screens/editor_available_screen.dart';
import '../../features/editor/presentation/screens/editor_workspace_screen.dart';
import '../../features/editor/presentation/screens/editor_settings_screen.dart';
import '../../features/manager/presentation/screens/manager_workflow_screen.dart';
import '../../features/manager/presentation/screens/manager_pending_screen.dart';
import '../../features/manager/presentation/screens/manager_finance_screen.dart';
import '../../features/manager/presentation/screens/manager_settings_screen.dart';
import '../../features/chat/presentation/screens/chat_inbox_screen.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/chat/domain/chat_models.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../../shared/widgets/wara_bottom_bar.dart';
import '../../shared/motion/page_transitions.dart';
import '../../features/projects/domain/project_provider.dart';

/// Bridges auth changes into GoRouter without rebuilding the router.
/// Only the fields that affect redirects trigger a refresh.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<(bool, bool, UserRole?, bool)>(
      authProvider.select((s) => (
            s.isAuthenticated,
            s.needsOnboarding,
            s.user?.role,
            s.user?.isProfileComplete ?? true,
          )),
      (_, _) => notifyListeners(),
    );
  }
}

/// A single GoRouter for the app's lifetime. Auth changes re-run [redirect]
/// via refreshListenable, so the navigation stack and tab state are kept.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  String homeFor(bool isEditor, bool isProfileComplete) => isEditor
      ? (isProfileComplete ? '/editor/available' : '/editor/profile-setup')
      : '/manager/workflow';

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isAuth = auth.isAuthenticated;
      final isEditor = auth.user?.role == UserRole.editor;
      final isProfileComplete = auth.user?.isProfileComplete ?? true;
      final loc = state.matchedLocation;

      if (!isAuth) {
        if (auth.needsOnboarding) return loc == '/welcome' ? null : '/welcome';
        return loc == '/login' ? null : '/login';
      }

      if (isEditor && !isProfileComplete) {
        return loc == '/editor/profile-setup' ? null : '/editor/profile-setup';
      }
      if (loc == '/login' || loc == '/welcome' || loc == '/editor/profile-setup') {
        return homeFor(isEditor, isProfileComplete);
      }
      // Keep users inside their own role's shell.
      if (isEditor && loc.startsWith('/manager/')) return homeFor(true, true);
      if (!isEditor && loc.startsWith('/editor/')) return homeFor(false, true);
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => fadeThroughPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => fadeThroughPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/editor/profile-setup',
        pageBuilder: (context, state) => fadeThroughPage(state, const EditorProfileSetupScreen()),
      ),

      GoRoute(
        path: '/chat/:conversationId',
        pageBuilder: (context, state) {
          final convoId = state.pathParameters['conversationId'] ?? 'agency_general';
          final title = state.uri.queryParameters['title'] ?? (convoId == 'agency_general' ? '# agency-room' : 'Direct Message');
          final isChannel = convoId == 'agency_general';
          return fadeThroughPage(
            state,
            ChatRoomScreen(
              conversationId: convoId,
              title: title,
              type: isChannel ? ConversationType.channel : ConversationType.direct,
            ),
          );
        },
      ),

      // Editor Navigation Shell (4 Tabs)
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) => fadeThroughPage(state, _EditorShell(shell: shell)),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/editor/available', pageBuilder: (c, s) => fadeThroughPage(s, const EditorAvailableScreen()))]),
          StatefulShellBranch(routes: [GoRoute(path: '/editor/workspace', pageBuilder: (c, s) => fadeThroughPage(s, const EditorWorkspaceScreen()))]),
          StatefulShellBranch(routes: [GoRoute(path: '/editor/messages', pageBuilder: (c, s) => fadeThroughPage(s, const ChatInboxScreen()))]),
          StatefulShellBranch(routes: [GoRoute(path: '/editor/settings', pageBuilder: (c, s) => fadeThroughPage(s, const EditorSettingsScreen()))]),
        ],
      ),

      // Manager Navigation Shell (5 Tabs)
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, shell) => fadeThroughPage(state, _ManagerShell(shell: shell)),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/manager/workflow', pageBuilder: (c, s) => fadeThroughPage(s, const ManagerWorkflowScreen()))]),
          StatefulShellBranch(routes: [GoRoute(path: '/manager/pending', pageBuilder: (c, s) => fadeThroughPage(s, const ManagerPendingScreen()))]),
          StatefulShellBranch(routes: [GoRoute(path: '/manager/finance', pageBuilder: (c, s) => fadeThroughPage(s, const ManagerFinanceScreen()))]),
          StatefulShellBranch(routes: [GoRoute(path: '/manager/messages', pageBuilder: (c, s) => fadeThroughPage(s, const ChatInboxScreen()))]),
          StatefulShellBranch(routes: [GoRoute(path: '/manager/settings', pageBuilder: (c, s) => fadeThroughPage(s, const ManagerSettingsScreen()))]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _EditorShell extends ConsumerWidget {
  final StatefulNavigationShell shell;
  const _EditorShell({required this.shell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final active = ref.watch(workspaceBadgeProvider);
    return Scaffold(
      backgroundColor: colors.bg,
      body: shell,
      bottomNavigationBar: WaraBottomBar(
        selectedIndex: shell.currentIndex,
        onItemSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: [
          const WaraNavItem(
            icon: Icons.storefront_outlined,
            label: 'Marketplace',
            selectedIcon: Icons.storefront_rounded,
          ),
          WaraNavItem(
            icon: Icons.work_outline_rounded,
            label: 'Workspace',
            selectedIcon: Icons.work_rounded,
            badgeCount: active,
          ),
          const WaraNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Messages',
            selectedIcon: Icons.chat_bubble_rounded,
          ),
          const WaraNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Settings',
            selectedIcon: Icons.person_rounded,
          ),
        ],
      ),
    );
  }
}

class _ManagerShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _ManagerShell({required this.shell});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      body: shell,
      bottomNavigationBar: WaraBottomBar(
        selectedIndex: shell.currentIndex,
        onItemSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: const [
          WaraNavItem(
            icon: Icons.dashboard_outlined,
            label: 'Workflow',
            selectedIcon: Icons.dashboard_rounded,
          ),
          WaraNavItem(
            icon: Icons.hourglass_top_outlined,
            label: 'Pending',
            selectedIcon: Icons.hourglass_top_rounded,
          ),
          WaraNavItem(
            icon: Icons.account_balance_outlined,
            label: 'Finance',
            selectedIcon: Icons.account_balance_rounded,
          ),
          WaraNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Messages',
            selectedIcon: Icons.chat_bubble_rounded,
          ),
          WaraNavItem(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Settings',
            selectedIcon: Icons.admin_panel_settings_rounded,
          ),
        ],
      ),
    );
  }
}

