import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'storage_keys.dart';

/// 用户偏好设置存储服务
class UserPrefsStorage {
  UserPrefsStorage(this._box);

  final Box<dynamic> _box;

  ThemeMode readThemeMode() {
    final name = _box.get(StorageKeys.themeMode) as String?;
    return ThemeMode.values.firstWhere(
      (m) => m.name == name,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _box.put(StorageKeys.themeMode, mode.name);
  }

  String readLocale() => _box.get(StorageKeys.localeTag) as String? ?? 'zh';

  Future<void> saveLocale(String tag) async {
    await _box.put(StorageKeys.localeTag, tag);
  }

  bool? readEnableFileLog() => _box.get(StorageKeys.enableFileLog) as bool?;

  Future<void> saveEnableFileLog(bool value) async {
    await _box.put(StorageKeys.enableFileLog, value);
  }
}
