import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/app_design.dart';
import '../../i18n/i18n.dart';

/// 桌面端主框架：左侧 NavigationRail + 右侧内容区。
///
/// destinations 顺序必须与 `createRouter` 中 `StatefulShellBranch` 顺序一致。
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final destinations = [
      NavigationRailDestination(
        icon: const Icon(Icons.cable_outlined),
        selectedIcon: const Icon(Icons.cable),
        label: Text(t.nav.serial),
      ),
    ];

    // NavigationRail 要求至少 2 个 destination。
    if (destinations.length < 2) {
      return Scaffold(body: navigationShell);
    }

    final width = MediaQuery.sizeOf(context).width;
    final extended = AppDesign.sizeClassOf(width) == WindowSizeClass.expanded;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: destinations,
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
