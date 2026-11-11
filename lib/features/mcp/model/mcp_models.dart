// MCP 授权、策略、待确认消息与动作日志。

enum McpEnablePolicy { on, off, ask }

enum McpMessageKind { script, reply, quick }

enum McpAskOutcome { enabled, disabled, dropped, revoked }

class McpSettings {
  const McpSettings({
    required this.enabled,
    required this.port,
    required this.allowSend,
    required this.allowRead,
    required this.allowReply,
    required this.allowScript,
    required this.allowQuick,
    required this.replyPolicy,
    required this.scriptPolicy,
    required this.quickPolicy,
  });

  static const defaults = McpSettings(
    enabled: false,
    port: 39217,
    allowSend: false,
    allowRead: true,
    allowReply: false,
    allowScript: false,
    allowQuick: false,
    replyPolicy: McpEnablePolicy.ask,
    scriptPolicy: McpEnablePolicy.ask,
    quickPolicy: McpEnablePolicy.ask,
  );

  final bool enabled;
  final int port;
  final bool allowSend;
  final bool allowRead;
  final bool allowReply;
  final bool allowScript;
  final bool allowQuick;
  final McpEnablePolicy replyPolicy;
  final McpEnablePolicy scriptPolicy;
  final McpEnablePolicy quickPolicy;

  McpSettings copyWith({
    bool? enabled,
    int? port,
    bool? allowSend,
    bool? allowRead,
    bool? allowReply,
    bool? allowScript,
    bool? allowQuick,
    McpEnablePolicy? replyPolicy,
    McpEnablePolicy? scriptPolicy,
    McpEnablePolicy? quickPolicy,
  }) {
    return McpSettings(
      enabled: enabled ?? this.enabled,
      port: port ?? this.port,
      allowSend: allowSend ?? this.allowSend,
      allowRead: allowRead ?? this.allowRead,
      allowReply: allowReply ?? this.allowReply,
      allowScript: allowScript ?? this.allowScript,
      allowQuick: allowQuick ?? this.allowQuick,
      replyPolicy: replyPolicy ?? this.replyPolicy,
      scriptPolicy: scriptPolicy ?? this.scriptPolicy,
      quickPolicy: quickPolicy ?? this.quickPolicy,
    );
  }

  Map<String, Object> toJson() => {
    'enabled': enabled,
    'port': port,
    'allowSend': allowSend,
    'allowRead': allowRead,
    'allowReply': allowReply,
    'allowScript': allowScript,
    'allowQuick': allowQuick,
    'replyPolicy': replyPolicy.name,
    'scriptPolicy': scriptPolicy.name,
    'quickPolicy': quickPolicy.name,
  };

  static McpSettings fromJson(Object? raw) {
    if (raw is! Map) return defaults;
    McpEnablePolicy policy(Object? value) {
      final name = value?.toString();
      for (final item in McpEnablePolicy.values) {
        if (item.name == name) return item;
      }
      return McpEnablePolicy.ask;
    }

    final port = raw['port'];
    return McpSettings(
      enabled: raw['enabled'] == true,
      port: port is int
          ? port
          : int.tryParse('$port') ?? defaults.port,
      allowSend: raw['allowSend'] == true,
      allowRead: raw['allowRead'] != false,
      allowReply: raw['allowReply'] == true,
      allowScript: raw['allowScript'] == true,
      allowQuick: raw['allowQuick'] == true,
      replyPolicy: policy(raw['replyPolicy']),
      scriptPolicy: policy(raw['scriptPolicy']),
      quickPolicy: policy(raw['quickPolicy']),
    );
  }
}

class McpLogEntry {
  const McpLogEntry({required this.time, required this.body});

  final DateTime time;
  final String body;
}

class McpPendingMessage {
  const McpPendingMessage({
    required this.id,
    required this.kind,
    required this.tabId,
    required this.tabName,
    required this.name,
    required this.body,
    required this.enqueuedAt,
    this.replyPayload,
  });

  final String id;
  final McpMessageKind kind;
  final String tabId;
  final String tabName;
  final String name;
  final String body;
  final DateTime enqueuedAt;

  /// 自动应答导入时的结构化字段。
  final Map<String, Object?>? replyPayload;
}

class McpConnectionInfo {
  const McpConnectionInfo({
    required this.id,
    required this.name,
    required this.kind,
    required this.open,
  });

  final String id;
  final String name;
  final String kind;
  final bool open;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'kind': kind,
    'open': open,
  };
}

class McpLogSnapshotLine {
  const McpLogSnapshotLine({
    required this.time,
    required this.dir,
    required this.body,
  });

  final String time;
  final String dir;
  final String body;

  Map<String, Object> toJson() => {
    'time': time,
    'dir': dir,
    'body': body,
  };
}

/// 工作台桥接结果：成功或失败原因（英文短码，由调用方映射文案）。
sealed class McpBridgeResult {
  const McpBridgeResult();
}

class McpBridgeOk extends McpBridgeResult {
  const McpBridgeOk([this.data]);

  final Object? data;
}

class McpBridgeErr extends McpBridgeResult {
  const McpBridgeErr(this.code, [this.detail]);

  final String code;
  final String? detail;
}

/// 解析成功后的页签定位结果。
class McpResolvedTab {
  const McpResolvedTab({required this.id, required this.name});

  final String id;
  final String name;
}

/// 按 ID 或显示名称解析页签。至少提供一个；都提供时以 ID 为准且名称须一致。
McpBridgeResult resolveMcpTab({
  required List<McpConnectionInfo> tabs,
  String? tabId,
  String? tabName,
}) {
  final id = tabId?.trim() ?? '';
  final name = tabName?.trim() ?? '';
  if (id.isEmpty && name.isEmpty) {
    return const McpBridgeErr('tab_required', '须提供 tabId 或 tabName 之一');
  }
  if (id.isNotEmpty) {
    McpConnectionInfo? hit;
    for (final tab in tabs) {
      if (tab.id == id) {
        hit = tab;
        break;
      }
    }
    if (hit == null) {
      return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
    }
    if (name.isNotEmpty && hit.name != name) {
      return McpBridgeErr(
        'tab_name_mismatch',
        '页签名称不匹配，当前为「${hit.name}」',
      );
    }
    return McpBridgeOk(McpResolvedTab(id: hit.id, name: hit.name));
  }
  final matches = [for (final tab in tabs) if (tab.name == name) tab];
  if (matches.isEmpty) {
    return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
  }
  if (matches.length > 1) {
    return const McpBridgeErr(
      'tab_name_ambiguous',
      '同名页签多于一条，请改用 tabId',
    );
  }
  final hit = matches.first;
  return McpBridgeOk(McpResolvedTab(id: hit.id, name: hit.name));
}

abstract class McpWorkbench {
  List<McpConnectionInfo> listConnections();

  /// 按页签 ID 或显示名称定位；至少提供一个。成功时 data 为 [McpResolvedTab]。
  McpBridgeResult resolveTab({String? tabId, String? tabName});

  Future<McpBridgeResult> sendData({
    required String tabId,
    required String tabName,
    required String data,
    String format,
  });

  Future<McpBridgeResult> readLogs({
    required String tabId,
    required String tabName,
  });

  bool hasScript({required String tabId, required String name});

  bool hasReply({required String tabId, required String name});

  bool hasQuick({required String tabId, required String name});

  Future<McpBridgeResult> importScript({
    required String tabId,
    required String tabName,
    required String name,
    required String code,
    required bool enabled,
  });

  Future<McpBridgeResult> importReply({
    required String tabId,
    required String tabName,
    required String name,
    required Map<String, Object?> payload,
    required bool enabled,
  });

  Future<McpBridgeResult> importQuick({
    required String tabId,
    required String tabName,
    required String name,
    required String data,
    required String format,
    required bool enabled,
  });

  /// 按名称启用/禁用已导入的脚本、自动应答或快捷指令。
  Future<McpBridgeResult> setItemEnabled({
    required McpMessageKind kind,
    required String tabId,
    required String name,
    required bool enabled,
  });

  void noteRejected({
    required String tabId,
    required String tabName,
    required String detail,
  });
}

abstract final class McpLimits {
  static const int messageQueue = 100;
  static const int logLines = 500;
  static const int defaultPort = 39217;
  static const int maxPortTries = 20;
}
