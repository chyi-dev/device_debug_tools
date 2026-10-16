import '../model/home_tab.dart';

const _keep = Object();

class HomeTabsState {
  const HomeTabsState({required this.tabs, required this.activeId});

  const HomeTabsState.empty() : tabs = const [], activeId = null;

  final List<HomeTab> tabs;
  final String? activeId;

  HomeTab? get active {
    for (final tab in tabs) {
      if (tab.id == activeId) return tab;
    }
    return null;
  }

  HomeTabsState copyWith({List<HomeTab>? tabs, Object? activeId = _keep}) {
    return HomeTabsState(
      tabs: tabs ?? this.tabs,
      activeId: identical(activeId, _keep)
          ? this.activeId
          : activeId as String?,
    );
  }
}
