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
import '../../features/chat/presentation/screens/chat_inbox_screen.dart';
import '../../features/chat/presentation/screens/chat_room_screen.dart';
import '../../features/chat/domain/chat_models.dart';
import '../constants/app_constants.dart';
import '../theme/app_theme.dart';
import '../../shared/widgets/wara_bottom_bar.dart';

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

      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) {
          final convoId = state.pathParameters['conversationId'] ?? 'agency_general';
          final title = state.uri.queryParameters['title'] ?? (convoId == 'agency_general' ? '# agency-room' : 'Direct Message');
          final isChannel = convoId == 'agency_general';
          return ChatRoomScreen(
            conversationId: convoId,
            title: title,
            type: isChannel ? ConversationType.channel : ConversationType.direct,
          );
        },
      ),

      // Editor Navigation Shell (4 Tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _EditorShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/editor/available', builder: (c, s) => const EditorAvailableScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/editor/workspace', builder: (c, s) => const EditorWorkspaceScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/editor/messages', builder: (c, s) => const ChatInboxScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/editor/settings', builder: (c, s) => const EditorSettingsScreen())]),
        ],
      ),

      // Manager Navigation Shell (5 Tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _ManagerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/manager/workflow', builder: (c, s) => const ManagerWorkflowScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/manager/pending', builder: (c, s) => const ManagerPendingScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/manager/finance', builder: (c, s) => const ManagerFinanceScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/manager/messages', builder: (c, s) => const ChatInboxScreen())]),
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
      bottomNavigationBar: WaraBottomBar(
        selectedIndex: shell.currentIndex,
        onItemSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        items: const [
          WaraNavItem(
            icon: Icons.storefront_outlined,
            selectedIcon: Icons.storefront_rounded,
          ),
          WaraNavItem(
            icon: Icons.work_outline_rounded,
            selectedIcon: Icons.work_rounded,
          ),
          WaraNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            selectedIcon: Icons.chat_bubble_rounded,
          ),
          WaraNavItem(
            icon: Icons.person_outline_rounded,
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
            selectedIcon: Icons.dashboard_rounded,
          ),
          WaraNavItem(
            icon: Icons.hourglass_top_outlined,
            selectedIcon: Icons.hourglass_top_rounded,
          ),
          WaraNavItem(
            icon: Icons.account_balance_outlined,
            selectedIcon: Icons.account_balance_rounded,
          ),
          WaraNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            selectedIcon: Icons.chat_bubble_rounded,
          ),
          WaraNavItem(
            icon: Icons.admin_panel_settings_outlined,
            selectedIcon: Icons.admin_panel_settings_rounded,
          ),
        ],
      ),
    );
  }
}

