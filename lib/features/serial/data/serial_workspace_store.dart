import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/storage/storage_keys.dart';
import '../model/serial_models.dart';

class SerialWorkspaceStore {
  SerialWorkspaceStore(this._box);

  final Box<dynamic> _box;

  SerialWorkspace? read() {
    final raw = _box.get(StorageKeys.serialWorkspace);
    if (raw is! String || raw.isEmpty) return null;
    try {
      return SerialWorkspace.fromJson(jsonDecode(raw));
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '串口工作区解析失败',
        category: LogCategory.database,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> write(SerialWorkspace workspace) {
    return _box.put(
      StorageKeys.serialWorkspace,
      jsonEncode(workspace.toJson()),
    );
  }
}
