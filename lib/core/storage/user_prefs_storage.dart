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

  DateTime? readUpdateLastCheckAt() {
    final ms = _box.get(StorageKeys.updateLastCheckMs) as int?;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveUpdateLastCheckAt(DateTime at) async {
    await _box.put(StorageKeys.updateLastCheckMs, at.millisecondsSinceEpoch);
  }

  String? readUpdateDismissedVersion() =>
      _box.get(StorageKeys.updateDismissedVersion) as String?;

  Future<void> saveUpdateDismissedVersion(String version) async {
    await _box.put(StorageKeys.updateDismissedVersion, version);
  }

  Future<void> clearUpdateDismissedVersion() async {
    await _box.delete(StorageKeys.updateDismissedVersion);
  }

  /// 四协议共用的调试台分区尺寸（逻辑 px）。
  Map<String, double> readConsoleLayout() {
    final raw = _box.get(StorageKeys.consoleLayout);
    if (raw is! Map) return const {};
    final out = <String, double>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) continue;
      if (value is num) out[key] = value.toDouble();
    }
    return out;
  }

  Future<void> saveConsoleLayout(Map<String, double> layout) async {
    await _box.put(StorageKeys.consoleLayout, layout);
  }
}
