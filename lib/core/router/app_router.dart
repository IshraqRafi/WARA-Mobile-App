import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/editor/presentation/screens/editor_profile_setup_screen.dart';
import '../../features/editor/presentation/screens/editor_available_screen.dart';
import '../../features/editor/presentation/screens/editor_workspace_screen.dart';
import '../../features/editor/presentation/screens/editor_settings_screen.dart';
import '../../features/manager/presentation/screens/manager_workflow_screen.dart';
import '../../features/manager/presentation/screens/manager_pending_screen.dart';
import '../../features/manager/presentation/screens/manager_finance_screen.dart';
import '../../features/manager/presentation/screens/manager_settings_screen.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isAuth = ref.watch(authProvider.select((s) => s.isAuthenticated));
  final userRole = ref.watch(authProvider.select((s) => s.user?.role));
  final isEditor = userRole == UserRole.editor;
  final isProfileComplete = ref.watch(authProvider.select((s) => s.user?.isProfileComplete ?? true));

  return GoRouter(
    initialLocation: !isAuth
        ? '/login'
        : (isEditor
            ? (isProfileComplete ? '/editor/available' : '/editor/profile-setup')
            : '/manager/workflow'),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (!isAuth && loc != '/login') return '/login';
      if (isAuth) {
        if (isEditor && !isProfileComplete) {
          if (loc != '/editor/profile-setup') return '/editor/profile-setup';
          return null;
        }
        if (loc == '/login' || loc == '/editor/profile-setup') {
          return isEditor ? '/editor/available' : '/manager/workflow';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/editor/profile-setup',
        builder: (context, state) => const EditorProfileSetupScreen(),
      ),

      // Editor Navigation Shell (3 Tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _EditorShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/editor/available', builder: (c, s) => const EditorAvailableScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/editor/workspace', builder: (c, s) => const EditorWorkspaceScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/editor/settings', builder: (c, s) => const EditorSettingsScreen())]),
        ],
      ),

      // Manager Navigation Shell (4 Tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _ManagerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/manager/workflow', builder: (c, s) => const ManagerWorkflowScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/manager/pending', builder: (c, s) => const ManagerPendingScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/manager/finance', builder: (c, s) => const ManagerFinanceScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/manager/settings', builder: (c, s) => const ManagerSettingsScreen())]),
        ],
      ),
    ],
  );
});

class _EditorShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _EditorShell({required this.shell});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.bg,
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.8), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          backgroundColor: colors.surface,
          indicatorColor: colors.primary.withValues(alpha: 0.15),
          height: 64,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Available Pool',
            ),
            NavigationDestination(
              icon: Icon(Icons.work_outline_rounded),
              selectedIcon: Icon(Icons.work_rounded),
              label: 'My Workspace',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.border.withValues(alpha: 0.8), width: 1)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          backgroundColor: colors.surface,
          indicatorColor: colors.primary.withValues(alpha: 0.15),
          height: 64,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Global Workflow',
            ),
            NavigationDestination(
              icon: Icon(Icons.hourglass_top_outlined),
              selectedIcon: Icon(Icons.hourglass_top_rounded),
              label: 'Pending',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_outlined),
              selectedIcon: Icon(Icons.account_balance_rounded),
              label: 'Finance',
            ),
            NavigationDestination(
              icon: Icon(Icons.admin_panel_settings_outlined),
              selectedIcon: Icon(Icons.admin_panel_settings_rounded),
              label: 'Agency OS',
            ),
          ],
        ),
      ),
    );
  }
}
