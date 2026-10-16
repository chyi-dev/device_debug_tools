import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/storage/storage_keys.dart';
import '../model/home_tab.dart';

class HomeTabsSnapshot {
  const HomeTabsSnapshot({required this.tabs, required this.activeId});

  final List<HomeTab> tabs;
  final String? activeId;
}

abstract class HomeTabStore {
  HomeTabsSnapshot? read();

  Future<void> write(HomeTabsSnapshot snapshot);
}

class HiveHomeTabStore implements HomeTabStore {
  HiveHomeTabStore(this._box);

  final Box<dynamic> _box;

  @override
  HomeTabsSnapshot? read() {
    final raw = _box.get(StorageKeys.homeTabs);
    if (raw is! String || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final tabs = <HomeTab>[];
      final list = json['tabs'];
      if (list is List) {
        for (final item in list) {
          final tab = HomeTab.fromJson(item);
          if (tab != null) tabs.add(tab);
        }
      }
      final active = json['activeId'];
      return HomeTabsSnapshot(
        tabs: tabs,
        activeId: active is String ? active : null,
      );
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '首页页签解析失败',
        category: LogCategory.database,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> write(HomeTabsSnapshot snapshot) {
    return _box.put(
      StorageKeys.homeTabs,
      jsonEncode({
        'activeId': snapshot.activeId,
        'tabs': snapshot.tabs.map((tab) => tab.toJson()).toList(),
      }),
    );
  }
}
