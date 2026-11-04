import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/storage/storage_keys.dart';
import '../model/socket_models.dart';

class SocketWorkspaceStore {
  SocketWorkspaceStore(this._box, {required String storageKey})
    : _key = storageKey;

  final Box<dynamic> _box;
  final String _key;

  SocketWorkspace? read() {
    final raw = _box.get(_key);
    if (raw is! String || raw.isEmpty) return null;
    try {
      return SocketWorkspace.fromJson(jsonDecode(raw));
    } catch (error, stackTrace) {
      AppLogger.i.error(
        'Socket 工作区解析失败',
        category: LogCategory.database,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> write(SocketWorkspace workspace) {
    return _box.put(_key, jsonEncode(workspace.toJson()));
  }
}

/// 默认 key 前缀，供会话工厂在无自定义 key 时回退。
String socketDefaultKey(SocketProtocol protocol) => switch (protocol) {
  SocketProtocol.tcp => StorageKeys.tcpWorkspace,
  SocketProtocol.udp => StorageKeys.udpWorkspace,
};
