import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../model/mqtt_models.dart';

abstract class MqttWorkspaceStore {
  MqttWorkspace? read();

  Future<void> write(MqttWorkspace workspace);
}

class HiveMqttWorkspaceStore implements MqttWorkspaceStore {
  HiveMqttWorkspaceStore(this._box, {required String storageKey})
    : _key = storageKey;

  final Box<dynamic> _box;
  final String _key;

  @override
  MqttWorkspace? read() {
    final raw = _box.get(_key);
    if (raw is! String || raw.isEmpty) return null;
    try {
      return MqttWorkspace.fromJson(jsonDecode(raw));
    } catch (error, stackTrace) {
      AppLogger.i.error(
        'MQTT 工作区解析失败',
        category: LogCategory.database,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  @override
  Future<void> write(MqttWorkspace workspace) {
    return _box.put(_key, jsonEncode(workspace.toJson()));
  }
}
