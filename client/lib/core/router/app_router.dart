import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/scanner/scanner_screen.dart';
import '../../features/report/report_screen.dart';
import '../../features/main/main_scaffold.dart';
import '../../features/analysis/text_input_screen.dart';
import '../../features/analysis/analysis_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/report',
              pageBuilder: (context, state) => const NoTransitionPage(child: ReportScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => NoTransitionPage(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Center(
                    child: Text(
                      '设置与偏好',
                      style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    // ── 全屏叠加页面 (Shell 外部) ──
    GoRoute(
      path: '/scanner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/text-input',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TextInputScreen(),
    ),
    GoRoute(
      path: '/analysis',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final contractText = state.extra as String? ?? '';
        return AnalysisScreen(contractText: contractText);
      },
    ),
  ],
);
