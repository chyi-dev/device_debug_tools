import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/serial/page/serial_console_page.dart';
import '../widgets/main_shell.dart';
import 'route_names.dart';

/// GoRouter 根 Navigator，供全局 Overlay / Dialog 使用。
final appRootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// 创建 GoRouter 配置；新增侧边导航项需同步 [MainShell] 的 destinations。
GoRouter createRouter() {
  return GoRouter(
    navigatorKey: appRootNavigatorKey,
    initialLocation: RouteNames.serial,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.serial,
                builder: (context, state) => const SerialConsolePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
