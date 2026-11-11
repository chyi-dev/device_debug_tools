import 'package:hive/hive.dart';

import '../../../core/storage/storage_keys.dart';
import '../model/mcp_models.dart';

class McpSettingsStore {
  McpSettingsStore(this._box);

  final Box<dynamic> _box;

  McpSettings read() {
    return McpSettings.fromJson(_box.get(StorageKeys.mcpSettings));
  }

  Future<void> write(McpSettings settings) {
    return _box.put(StorageKeys.mcpSettings, settings.toJson());
  }
}
