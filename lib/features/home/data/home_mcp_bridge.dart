import '../../../i18n/i18n.dart';
import '../../mcp/model/mcp_models.dart';
import '../../serial/model/serial_models.dart';
import '../cubit/home_tabs_cubit.dart';
import '../model/connection_kind.dart';
import '../model/home_tab.dart';

/// 将 MCP 动作转到各协议 ConsoleCubit；页签可用 ID 或显示名称定位。
class HomeMcpBridge implements McpWorkbench {
  HomeMcpBridge(this._home);

  final HomeTabsCubit _home;

  @override
  List<McpConnectionInfo> listConnections() {
    return [
      for (final tab in _home.state.tabs)
        McpConnectionInfo(
          id: tab.id,
          name: displayNameOf(tab),
          kind: tab.kind.name,
          open: _home.liveFor(tab.id).open,
        ),
    ];
  }

  @override
  McpBridgeResult resolveTab({String? tabId, String? tabName}) {
    return resolveMcpTab(
      tabs: listConnections(),
      tabId: tabId,
      tabName: tabName,
    );
  }

  McpResolvedTab? _resolved(String? tabId, String? tabName) {
    final result = resolveTab(tabId: tabId, tabName: tabName);
    if (result is! McpBridgeOk) return null;
    final data = result.data;
    return data is McpResolvedTab ? data : null;
  }

  @override
  Future<McpBridgeResult> sendData({
    required String tabId,
    required String tabName,
    required String data,
    String format = 'hex',
  }) async {
    final resolved = _resolved(tabId, tabName);
    if (resolved == null) {
      return resolveTab(tabId: tabId, tabName: tabName);
    }
    final id = resolved.id;
    final tab = _tabById(id);
    if (tab == null) {
      return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
    }
    final fmt = format.toLowerCase() == 'ascii'
        ? DataFormat.ascii
        : DataFormat.hex;
    switch (tab.kind) {
      case ConnectionKind.serial:
        final ok = await _home.serialFor(id)?.sendFromMcp(data, format: fmt);
        return ok == true
            ? const McpBridgeOk()
            : const McpBridgeErr('send_failed', '发送失败或串口未打开');
      case ConnectionKind.ble:
        final ok = await _home.bleFor(id)?.sendFromMcp(data, format: fmt);
        return ok == true
            ? const McpBridgeOk()
            : const McpBridgeErr('send_failed', '发送失败、未连接或未钉 Write');
      case ConnectionKind.mqtt:
        final ok = await _home.mqttFor(id)?.sendFromMcp(data);
        return ok == true
            ? const McpBridgeOk()
            : const McpBridgeErr('send_failed', '发布失败或未连接');
      case ConnectionKind.tcp:
      case ConnectionKind.udp:
        final ok = await _home.socketFor(id)?.sendFromMcp(data, format: fmt);
        return ok == true
            ? const McpBridgeOk()
            : const McpBridgeErr('send_failed', '发送失败或连接未打开');
    }
  }

  @override
  Future<McpBridgeResult> readLogs({
    required String tabId,
    required String tabName,
  }) async {
    final resolved = _resolved(tabId, tabName);
    if (resolved == null) {
      return resolveTab(tabId: tabId, tabName: tabName);
    }
    final id = resolved.id;
    final tab = _tabById(id);
    if (tab == null) {
      return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
    }
    final lines = switch (tab.kind) {
      ConnectionKind.serial => _home.serialFor(id)?.mcpLogSnapshot(),
      ConnectionKind.ble => _home.bleFor(id)?.mcpLogSnapshot(),
      ConnectionKind.mqtt => _home.mqttFor(id)?.mcpLogSnapshot(),
      ConnectionKind.tcp ||
      ConnectionKind.udp => _home.socketFor(id)?.mcpLogSnapshot(),
    };
    if (lines == null) {
      return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
    }
    return McpBridgeOk(lines);
  }

  @override
  bool hasScript({required String tabId, required String name}) {
    final tab = _tabById(tabId);
    if (tab == null) return false;
    return switch (tab.kind) {
      ConnectionKind.serial =>
        _home.serialFor(tabId)?.hasScriptNamed(name) ?? false,
      ConnectionKind.ble => _home.bleFor(tabId)?.hasScriptNamed(name) ?? false,
      ConnectionKind.mqtt =>
        _home.mqttFor(tabId)?.hasScriptNamed(name) ?? false,
      ConnectionKind.tcp ||
      ConnectionKind.udp =>
        _home.socketFor(tabId)?.hasScriptNamed(name) ?? false,
    };
  }

  @override
  bool hasReply({required String tabId, required String name}) {
    final tab = _tabById(tabId);
    if (tab == null) return false;
    return switch (tab.kind) {
      ConnectionKind.serial =>
        _home.serialFor(tabId)?.hasReplyNamed(name) ?? false,
      ConnectionKind.ble => _home.bleFor(tabId)?.hasReplyNamed(name) ?? false,
      ConnectionKind.mqtt => false,
      ConnectionKind.tcp ||
      ConnectionKind.udp =>
        _home.socketFor(tabId)?.hasReplyNamed(name) ?? false,
    };
  }

  @override
  bool hasQuick({required String tabId, required String name}) {
    final tab = _tabById(tabId);
    if (tab == null) return false;
    return switch (tab.kind) {
      ConnectionKind.serial =>
        _home.serialFor(tabId)?.hasQuickNamed(name) ?? false,
      ConnectionKind.ble => _home.bleFor(tabId)?.hasQuickNamed(name) ?? false,
      ConnectionKind.mqtt => false,
      ConnectionKind.tcp ||
      ConnectionKind.udp =>
        _home.socketFor(tabId)?.hasQuickNamed(name) ?? false,
    };
  }

  @override
  Future<McpBridgeResult> importScript({
    required String tabId,
    required String tabName,
    required String name,
    required String code,
    required bool enabled,
  }) async {
    final resolved = _resolved(tabId, tabName);
    if (resolved == null) {
      return resolveTab(tabId: tabId, tabName: tabName);
    }
    final id = resolved.id;
    final tab = _tabById(id);
    if (tab == null) {
      return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
    }
    final ok = switch (tab.kind) {
      ConnectionKind.serial => _home.serialFor(id)?.importScriptFromMcp(
        name: name,
        code: code,
        enabled: enabled,
      ),
      ConnectionKind.ble => _home.bleFor(id)?.importScriptFromMcp(
        name: name,
        code: code,
        enabled: enabled,
      ),
      ConnectionKind.mqtt => _home.mqttFor(id)?.importScriptFromMcp(
        name: name,
        code: code,
        enabled: enabled,
      ),
      ConnectionKind.tcp || ConnectionKind.udp => _home
          .socketFor(id)
          ?.importScriptFromMcp(name: name, code: code, enabled: enabled),
    };
    if (ok == true) return const McpBridgeOk();
    if (ok == false) return const McpBridgeErr('duplicate', '同名脚本已存在');
    return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
  }

  @override
  Future<McpBridgeResult> importReply({
    required String tabId,
    required String tabName,
    required String name,
    required Map<String, Object?> payload,
    required bool enabled,
  }) async {
    final resolved = _resolved(tabId, tabName);
    if (resolved == null) {
      return resolveTab(tabId: tabId, tabName: tabName);
    }
    final id = resolved.id;
    final tab = _tabById(id);
    if (tab == null) {
      return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
    }
    if (tab.kind == ConnectionKind.mqtt) {
      return const McpBridgeErr('unsupported', 'MQTT 不支持自动应答');
    }
    final rule = _replyFromPayload(
      name: name,
      payload: payload,
      enabled: enabled,
    );
    if (rule == null) {
      return const McpBridgeErr('invalid_reply', '自动应答参数无效');
    }
    final ok = switch (tab.kind) {
      ConnectionKind.serial => _home.serialFor(id)?.importReplyFromMcp(rule),
      ConnectionKind.ble => _home.bleFor(id)?.importReplyFromMcp(rule),
      ConnectionKind.mqtt => false,
      ConnectionKind.tcp ||
      ConnectionKind.udp => _home.socketFor(id)?.importReplyFromMcp(rule),
    };
    if (ok == true) return const McpBridgeOk();
    if (ok == false) return const McpBridgeErr('duplicate', '同名自动应答已存在');
    return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
  }

  @override
  Future<McpBridgeResult> importQuick({
    required String tabId,
    required String tabName,
    required String name,
    required String data,
    required String format,
    required bool enabled,
  }) async {
    final resolved = _resolved(tabId, tabName);
    if (resolved == null) {
      return resolveTab(tabId: tabId, tabName: tabName);
    }
    final id = resolved.id;
    final tab = _tabById(id);
    if (tab == null) {
      return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
    }
    if (tab.kind == ConnectionKind.mqtt) {
      return const McpBridgeErr('unsupported', 'MQTT 不支持快捷指令 MCP 写入');
    }
    final fmt = format.trim().toLowerCase() == 'ascii'
        ? DataFormat.ascii
        : DataFormat.hex;
    final ok = switch (tab.kind) {
      ConnectionKind.serial => _home.serialFor(id)?.importQuickFromMcp(
        name: name,
        data: data,
        format: fmt,
        enabled: enabled,
      ),
      ConnectionKind.ble => _home.bleFor(id)?.importQuickFromMcp(
        name: name,
        data: data,
        format: fmt,
        enabled: enabled,
      ),
      ConnectionKind.mqtt => false,
      ConnectionKind.tcp || ConnectionKind.udp => _home
          .socketFor(id)
          ?.importQuickFromMcp(
            name: name,
            data: data,
            format: fmt,
            enabled: enabled,
          ),
    };
    if (ok == true) return const McpBridgeOk();
    if (ok == false) return const McpBridgeErr('duplicate', '同名快捷指令已存在');
    return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
  }

  @override
  Future<McpBridgeResult> setItemEnabled({
    required McpMessageKind kind,
    required String tabId,
    required String name,
    required bool enabled,
  }) async {
    final tab = _tabById(tabId);
    if (tab == null) {
      return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
    }
    final ok = switch (kind) {
      McpMessageKind.script => switch (tab.kind) {
        ConnectionKind.serial =>
          _home.serialFor(tabId)?.setScriptEnabledByName(name, enabled),
        ConnectionKind.ble =>
          _home.bleFor(tabId)?.setScriptEnabledByName(name, enabled),
        ConnectionKind.mqtt =>
          _home.mqttFor(tabId)?.setScriptEnabledByName(name, enabled),
        ConnectionKind.tcp ||
        ConnectionKind.udp =>
          _home.socketFor(tabId)?.setScriptEnabledByName(name, enabled),
      },
      McpMessageKind.reply => switch (tab.kind) {
        ConnectionKind.serial =>
          _home.serialFor(tabId)?.setReplyEnabledByName(name, enabled),
        ConnectionKind.ble =>
          _home.bleFor(tabId)?.setReplyEnabledByName(name, enabled),
        ConnectionKind.mqtt => false,
        ConnectionKind.tcp ||
        ConnectionKind.udp =>
          _home.socketFor(tabId)?.setReplyEnabledByName(name, enabled),
      },
      McpMessageKind.quick => switch (tab.kind) {
        ConnectionKind.serial =>
          _home.serialFor(tabId)?.setQuickEnabledByName(name, enabled),
        ConnectionKind.ble =>
          _home.bleFor(tabId)?.setQuickEnabledByName(name, enabled),
        ConnectionKind.mqtt => false,
        ConnectionKind.tcp ||
        ConnectionKind.udp =>
          _home.socketFor(tabId)?.setQuickEnabledByName(name, enabled),
      },
    };
    if (ok == true) return const McpBridgeOk();
    if (ok == false) {
      return const McpBridgeErr('not_found', '目标条目不存在或不支持');
    }
    return const McpBridgeErr('tab_not_found', '页签不存在或已关闭');
  }

  @override
  void noteRejected({
    required String tabId,
    required String tabName,
    required String detail,
  }) {
    final resolved = _resolved(tabId, tabName);
    if (resolved == null) return;
    final id = resolved.id;
    final tab = _tabById(id);
    if (tab == null) return;
    switch (tab.kind) {
      case ConnectionKind.serial:
        _home.serialFor(id)?.noteMcpRejected(detail);
      case ConnectionKind.ble:
        _home.bleFor(id)?.noteMcpRejected(detail);
      case ConnectionKind.mqtt:
        _home.mqttFor(id)?.noteMcpRejected(detail);
      case ConnectionKind.tcp:
      case ConnectionKind.udp:
        _home.socketFor(id)?.noteMcpRejected(detail);
    }
  }

  String displayNameOf(HomeTab tab) {
    final label = tab.label?.trim() ?? '';
    if (label.isNotEmpty) return label;
    final live = _home.liveFor(tab.id).title?.trim() ?? '';
    if (live.isNotEmpty) return live;
    final tr = t;
    return switch (tab.kind) {
      ConnectionKind.serial => tr.home.kindSerial,
      ConnectionKind.ble => tr.home.kindBle,
      ConnectionKind.mqtt => tr.home.kindMqtt,
      ConnectionKind.tcp => tr.home.kindTcp,
      ConnectionKind.udp => tr.home.kindUdp,
    };
  }

  HomeTab? _tabById(String id) {
    for (final tab in _home.state.tabs) {
      if (tab.id == id) return tab;
    }
    return null;
  }

  ReplyRule? _replyFromPayload({
    required String name,
    required Map<String, Object?> payload,
    required bool enabled,
  }) {
    final pattern = '${payload['pattern'] ?? ''}'.trim();
    if (pattern.isEmpty) return null;
    final matchName = '${payload['match'] ?? 'contains'}';
    final kind = matchName == 'regex' ? MatchKind.regex : MatchKind.template;
    final match = MatchMode.values.asNameMap()[matchName] ?? MatchMode.contains;
    final formatName = '${payload['format'] ?? 'hex'}';
    final format =
        DataFormat.values.asNameMap()[formatName] ?? DataFormat.hex;
    final replies = <ReplyStep>[];
    final raw = payload['replies'];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final data = '${item['data'] ?? ''}';
        if (data.isEmpty) continue;
        final delay = item['delayMs'] ?? item['delay'];
        replies.add(
          ReplyStep(
            data: data,
            delayMs: delay is int
                ? delay
                : int.tryParse('$delay') ?? 0,
          ),
        );
      }
    }
    if (replies.isEmpty) return null;
    return ReplyRule(
      id: newSerialId('r'),
      name: name,
      match: match,
      pattern: pattern,
      enabled: enabled,
      hits: 0,
      replies: replies,
      kind: kind,
      format: format,
      ignoreCase: payload['ignoreCase'] == true,
    );
  }
}
