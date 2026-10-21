import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../model/ble_models.dart';

abstract class BleWorkspaceStore {
  BleWorkspace? read();

  Future<void> write(BleWorkspace workspace);
}

class HiveBleWorkspaceStore implements BleWorkspaceStore {
  HiveBleWorkspaceStore(this._box, {required String storageKey})
    : _key = storageKey;

  final Box<dynamic> _box;
  final String _key;

  @override
  BleWorkspace? read() {
    final raw = _box.get(_key);
    if (raw is! String || raw.isEmpty) return null;
    try {
      return BleWorkspace.fromJson(jsonDecode(raw));
    } catch (error, stackTrace) {
      AppLogger.i.error(
        'BLE 工作区解析失败',
        category: LogCategory.database,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> write(BleWorkspace workspace) {
    return _box.put(_key, jsonEncode(workspace.toJson()));
  }
}
