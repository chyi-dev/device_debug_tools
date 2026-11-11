import 'dart:async';
import 'dart:convert';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../data/mcp_http_server.dart';
import '../data/mcp_message_queue.dart';
import '../data/mcp_settings_store.dart';
import '../model/mcp_models.dart';

typedef McpStateListener = void Function();

/// MCP 本机服务与询问队列编排。
class McpRepository {
  McpRepository({required McpSettingsStore store}) : _store = store {
    _settings = _store.read();
  }

  final McpSettingsStore _store;
  final McpMessageQueue _queue = McpMessageQueue();
  final List<McpLogEntry> _logs = [];
  final List<McpStateListener> _listeners = [];

  late McpSettings _settings;
  McpWorkbench? _workbench;
  McpHttpServer? _server;
  var _clientSeen = false;
  var _seq = 0;

  McpSettings get settings => _settings;

  int? get boundPort => _server?.boundPort;

  bool get listening => _server?.isRunning == true;

  bool get clientConnected => _clientSeen && listening;

  List<McpPendingMessage> get pending => _queue.pending;

  List<McpLogEntry> get logs => List.unmodifiable(_logs);

  void addListener(McpStateListener listener) => _listeners.add(listener);

  void removeListener(McpStateListener listener) => _listeners.remove(listener);

  void bindWorkbench(McpWorkbench workbench) {
    _workbench = workbench;
    _notify();
  }

  void unbindWorkbench() {
    _workbench = null;
    _notify();
  }

  Future<void> startIfNeeded() async {
    if (_settings.enabled) {
      await _ensureServer();
    }
  }

  /// 因未激活停掉监听，不改写已保存的 [McpSettings.enabled]。
  Future<void> suspendListening() async {
    final wasListening = listening;
    await _stopServer();
    _queue.clearAll(outcome: McpAskOutcome.revoked);
    if (wasListening) {
      _log('未激活，已暂停 MCP');
    }
    _notify();
  }

  Future<void> setEnabled(bool enabled) async {
    _settings = _settings.copyWith(enabled: enabled);
    await _persist();
    if (enabled) {
      await _ensureServer();
      _log('打开 MCP');
    } else {
      await _stopServer();
      _queue.clearAll(outcome: McpAskOutcome.revoked);
      _log('关闭 MCP');
    }
    _notify();
  }

  Future<void> updateSettings(McpSettings next) async {
    final prev = _settings;
    final portChanged = next.port != prev.port;
    _settings = next;
    await _persist();

    if (next.allowSend != prev.allowSend) {
      _log(next.allowSend ? '允许发送数据' : '禁止发送数据');
    }
    if (next.allowRead != prev.allowRead) {
      _log(next.allowRead ? '允许读取数据' : '禁止读取数据');
    }
    if (next.allowReply != prev.allowReply) {
      _log(next.allowReply ? '允许自动应答' : '禁止自动应答');
      if (!next.allowReply) {
        _revokeKind(McpMessageKind.reply);
      }
    }
    if (next.allowScript != prev.allowScript) {
      _log(next.allowScript ? '允许实现脚本' : '禁止实现脚本');
      if (!next.allowScript) {
        _revokeKind(McpMessageKind.script);
      }
    }
    if (next.allowQuick != prev.allowQuick) {
      _log(next.allowQuick ? '允许快捷指令' : '禁止快捷指令');
      if (!next.allowQuick) {
        _revokeKind(McpMessageKind.quick);
      }
    }
    if (next.replyPolicy != prev.replyPolicy) {
      _log('自动应答启用策略：${_policyLabel(next.replyPolicy)}');
    }
    if (next.scriptPolicy != prev.scriptPolicy) {
      _log('脚本启用策略：${_policyLabel(next.scriptPolicy)}');
    }
    if (next.quickPolicy != prev.quickPolicy) {
      _log('快捷指令启用策略：${_policyLabel(next.quickPolicy)}');
    }
    if (next.enabled != prev.enabled) {
      await setEnabled(next.enabled);
      return;
    }
    if (next.enabled && (portChanged || _server == null)) {
      await _ensureServer(forceRestart: portChanged);
    }
    _notify();
  }

  Future<void> resolveMessage(String id, {required bool enable}) async {
    final message = _queue.byId(id);
    if (message == null) return;
    final what = _kindLabel(message.kind);
    final bench = _workbench;
    if (bench == null) {
      _queue.complete(id, McpAskOutcome.revoked);
      _log('工作台未就绪，无法确认启用$what ${message.name}（已导入未启用）。');
      _notify();
      return;
    }
    // 询问前已导入为未启用；启用时只改开关，取消则保持未启用。
    if (enable) {
      final result = await bench.setItemEnabled(
        kind: message.kind,
        tabId: message.tabId,
        name: message.name,
        enabled: true,
      );
      if (result is McpBridgeErr) {
        _log('启用$what ${message.name} 失败：${result.code}');
        _queue.complete(id, McpAskOutcome.disabled);
        _notify();
        return;
      }
      _log('通过 MCP 启用了$what ${message.name}（${message.tabName}）。');
      _queue.complete(id, McpAskOutcome.enabled);
    } else {
      _log('通过 MCP 确认不启用$what ${message.name}（${message.tabName}）。');
      _queue.complete(id, McpAskOutcome.disabled);
    }
    _notify();
  }

  Future<void> dispose() async {
    await _stopServer();
    _queue.clearAll(outcome: McpAskOutcome.revoked);
    _listeners.clear();
  }

  Future<void> _ensureServer({bool forceRestart = false}) async {
    if (!forceRestart && _server?.isRunning == true) return;
    await _stopServer();
    final server = McpHttpServer(
      onRpc: _onRpc,
      onClientSeen: () {
        if (!_clientSeen) {
          _clientSeen = true;
          _notify();
        }
      },
    );
    try {
      await server.start(preferredPort: _settings.port);
      _server = server;
      if (server.boundPort != null && server.boundPort != _settings.port) {
        _settings = _settings.copyWith(port: server.boundPort);
        await _persist();
        _log('端口占用，改用 ${server.boundPort}');
      }
    } catch (e, s) {
      AppLogger.i.error(
        'MCP start failed',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
      _log('MCP 启动失败');
      rethrow;
    }
  }

  Future<void> _stopServer() async {
    final server = _server;
    _server = null;
    _clientSeen = false;
    if (server != null) {
      await server.stop();
    }
  }

  Future<Object?> _onRpc(String method, Object? params) async {
    switch (method) {
      case 'initialize':
        return {
          'protocolVersion': '2024-11-05',
          'capabilities': {'tools': <String, Object>{}},
          'serverInfo': {
            'name': 'device_debug_tools',
            'version': '1.0.0',
          },
        };
      case 'ping':
        return <String, Object>{};
      case 'tools/list':
        return {'tools': _toolDefs()};
      case 'tools/call':
        return _callTool(params);
      default:
        throw McpRpcException('Method not found: $method', code: -32601);
    }
  }

  List<Map<String, Object>> _toolDefs() {
    const tabIdProp = {
      'type': 'string',
      'description': '页签 ID（与 tabName 二选一，也可都传）',
    };
    const tabNameProp = {
      'type': 'string',
      'description': '页签显示名称（与 tabId 二选一，也可都传）',
    };

    return [
      {
        'name': 'list_connections',
        'description': '列出全部连接页签的 id、显示名称、协议与是否打开',
        'inputSchema': {
          'type': 'object',
          'properties': <String, Object>{},
        },
      },
      {
        'name': 'read_logs',
        'description': '读取指定页签的数据日志快照（最多 500 条）',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'tabId': tabIdProp,
            'tabName': tabNameProp,
          },
        },
      },
      {
        'name': 'send_data',
        'description': '向指定页签发送一帧。不支持循环发送。',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'tabId': tabIdProp,
            'tabName': tabNameProp,
            'data': {'type': 'string', 'description': '要发送的数据'},
            'format': {
              'type': 'string',
              'description': 'hex 或 ascii，默认 hex',
            },
          },
          'required': ['data'],
        },
      },
      {
        'name': 'import_script',
        'description': '向指定页签导入 Lua 脚本',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'tabId': tabIdProp,
            'tabName': tabNameProp,
            'name': {'type': 'string'},
            'code': {'type': 'string'},
          },
          'required': ['name', 'code'],
        },
      },
      {
        'name': 'import_reply',
        'description': '向指定页签导入自动应答规则（MQTT 不支持）',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'tabId': tabIdProp,
            'tabName': tabNameProp,
            'name': {'type': 'string'},
            'pattern': {'type': 'string'},
            'match': {
              'type': 'string',
              'description': 'contains / prefix / suffix / frame / regex',
            },
            'format': {'type': 'string', 'description': 'hex 或 ascii'},
            'replies': {
              'type': 'array',
              'items': {
                'type': 'object',
                'properties': {
                  'data': {'type': 'string'},
                  'delayMs': {'type': 'integer'},
                },
              },
            },
          },
          'required': ['name', 'pattern', 'replies'],
        },
      },
      {
        'name': 'import_quick',
        'description': '向指定页签导入快捷指令（MQTT 不支持）',
        'inputSchema': {
          'type': 'object',
          'properties': {
            'tabId': tabIdProp,
            'tabName': tabNameProp,
            'name': {'type': 'string'},
            'data': {'type': 'string', 'description': '指令数据'},
            'format': {
              'type': 'string',
              'description': 'hex 或 ascii，默认 hex',
            },
          },
          'required': ['name', 'data'],
        },
      },
    ];
  }

  Future<Map<String, Object>> _callTool(Object? params) async {
    if (!_settings.enabled) {
      return _toolError('MCP 未启用');
    }
    if (params is! Map) {
      return _toolError('无效参数');
    }
    final name = params['name']?.toString() ?? '';
    final args = params['arguments'];
    final map = args is Map
        ? <String, Object?>{
            for (final e in args.entries) e.key.toString(): e.value,
          }
        : <String, Object?>{};

    switch (name) {
      case 'list_connections':
        final bench = _workbench;
        if (bench == null) return _toolError('工作台未就绪');
        final list = bench.listConnections();
        return _toolText(jsonEncode(list.map((e) => e.toJson()).toList()));
      case 'read_logs':
        return _readLogs(map);
      case 'send_data':
        return _sendData(map);
      case 'import_script':
        return _importScript(map);
      case 'import_reply':
        return _importReply(map);
      case 'import_quick':
        return _importQuick(map);
      default:
        return _toolError('未知工具: $name');
    }
  }

  Future<Map<String, Object>> _readLogs(Map<String, Object?> args) async {
    if (!_settings.allowRead) return _toolError('未授权读取数据');
    final resolved = _resolveTabArgs(args);
    if (resolved.error != null) return resolved.error!;
    final tab = resolved.tab!;
    final result = await _workbench!.readLogs(
      tabId: tab.id,
      tabName: tab.name,
    );
    if (result is McpBridgeErr) {
      return _toolError(_errText(result));
    }
    final data = (result as McpBridgeOk).data;
    final count = data is List ? data.length : 0;
    _log('通过 MCP 读取了「${tab.name}」的数据日志（$count 条）。');
    return _toolText(jsonEncode(data));
  }

  Future<Map<String, Object>> _sendData(Map<String, Object?> args) async {
    if (!_settings.allowSend) return _toolError('未授权发送数据');
    final resolved = _resolveTabArgs(args);
    if (resolved.error != null) return resolved.error!;
    final tab = resolved.tab!;

    // 拒绝循环发送参数
    for (final key in const [
      'repeat',
      'interval',
      'intervalMs',
      'loop',
      'count',
      'period',
      'periodMs',
    ]) {
      if (args.containsKey(key) && args[key] != null) {
        _workbench?.noteRejected(
          tabId: tab.id,
          tabName: tab.name,
          detail: '循环发送被拒绝',
        );
        _log('通过 MCP 拒绝了循环发送（${tab.name}）。');
        return _toolError('不支持循环发送');
      }
    }

    final data = '${args['data'] ?? ''}';
    final format = '${args['format'] ?? 'hex'}'.trim().toLowerCase();
    final fmt = format.isEmpty ? 'hex' : format;
    final result = await _workbench!.sendData(
      tabId: tab.id,
      tabName: tab.name,
      data: data,
      format: fmt,
    );
    if (result is McpBridgeErr) {
      _log('通过 MCP 向「${tab.name}」发送失败：${result.code}');
      return _toolError(_errText(result));
    }
    _log('通过 MCP 向「${tab.name}」发送了指令：$data（$fmt）');
    return _toolText('已发送');
  }

  Future<Map<String, Object>> _importScript(Map<String, Object?> args) async {
    if (!_settings.allowScript) {
      final name = '${args['name'] ?? ''}';
      _log('实现脚本未允许，$name 没有导入。');
      return _toolError('未授权实现脚本');
    }
    final resolved = _resolveTabArgs(args);
    if (resolved.error != null) return resolved.error!;
    final tab = resolved.tab!;
    final name = '${args['name'] ?? ''}'.trim();
    final code = '${args['code'] ?? ''}';
    if (name.isEmpty || code.isEmpty) {
      return _toolError('name 与 code 不能为空');
    }
    if (_workbench!.hasScript(tabId: tab.id, name: name)) {
      _log('脚本 $name 已在「${tab.name}」列表中，没有重复导入。');
      return _toolError('同名脚本已存在');
    }
    return _importWithPolicy(
      kind: McpMessageKind.script,
      policy: _settings.scriptPolicy,
      tabId: tab.id,
      tabName: tab.name,
      name: name,
      body: code,
    );
  }

  Future<Map<String, Object>> _importReply(Map<String, Object?> args) async {
    if (!_settings.allowReply) {
      final name = '${args['name'] ?? ''}';
      _log('自动应答未允许，$name 没有导入。');
      return _toolError('未授权自动应答');
    }
    final resolved = _resolveTabArgs(args);
    if (resolved.error != null) return resolved.error!;
    final tab = resolved.tab!;
    final name = '${args['name'] ?? ''}'.trim();
    if (name.isEmpty) return _toolError('name 不能为空');
    if (_workbench!.hasReply(tabId: tab.id, name: name)) {
      _log('自动应答 $name 已在「${tab.name}」列表中，没有重复导入。');
      return _toolError('同名自动应答已存在');
    }
    final payload = <String, Object?>{
      'name': name,
      'pattern': args['pattern'],
      'match': args['match'] ?? 'contains',
      'format': args['format'] ?? 'hex',
      'replies': args['replies'],
      'ignoreCase': args['ignoreCase'] == true,
    };
    final body = _replyPreview(payload);
    return _importWithPolicy(
      kind: McpMessageKind.reply,
      policy: _settings.replyPolicy,
      tabId: tab.id,
      tabName: tab.name,
      name: name,
      body: body,
      replyPayload: payload,
    );
  }

  Future<Map<String, Object>> _importQuick(Map<String, Object?> args) async {
    if (!_settings.allowQuick) {
      final name = '${args['name'] ?? ''}';
      _log('快捷指令未允许，$name 没有导入。');
      return _toolError('未授权快捷指令');
    }
    final resolved = _resolveTabArgs(args);
    if (resolved.error != null) return resolved.error!;
    final tab = resolved.tab!;
    final name = '${args['name'] ?? ''}'.trim();
    final data = '${args['data'] ?? ''}';
    if (name.isEmpty || data.isEmpty) {
      return _toolError('name 与 data 不能为空');
    }
    if (_workbench!.hasQuick(tabId: tab.id, name: name)) {
      _log('快捷指令 $name 已在「${tab.name}」列表中，没有重复导入。');
      return _toolError('同名快捷指令已存在');
    }
    final format = '${args['format'] ?? 'hex'}'.trim().toLowerCase();
    return _importWithPolicy(
      kind: McpMessageKind.quick,
      policy: _settings.quickPolicy,
      tabId: tab.id,
      tabName: tab.name,
      name: name,
      body: data,
      quickFormat: format.isEmpty ? 'hex' : format,
    );
  }

  Future<Map<String, Object>> _importWithPolicy({
    required McpMessageKind kind,
    required McpEnablePolicy policy,
    required String tabId,
    required String tabName,
    required String name,
    required String body,
    Map<String, Object?>? replyPayload,
    String? quickFormat,
  }) async {
    final what = _kindLabel(kind);
    if (policy == McpEnablePolicy.off) {
      final result = await _doImport(
        kind: kind,
        tabId: tabId,
        tabName: tabName,
        name: name,
        body: body,
        enabled: false,
        replyPayload: replyPayload,
        quickFormat: quickFormat,
      );
      if (result is McpBridgeErr) return _toolError(_errText(result));
      _log('通过 MCP 创建了$what $name，未启用（$tabName）。');
      return _toolText('已导入未启用');
    }
    if (policy == McpEnablePolicy.on) {
      final result = await _doImport(
        kind: kind,
        tabId: tabId,
        tabName: tabName,
        name: name,
        body: body,
        enabled: true,
        replyPayload: replyPayload,
        quickFormat: quickFormat,
      );
      if (result is McpBridgeErr) return _toolError(_errText(result));
      _log('通过 MCP 创建了$what $name，已启用（$tabName）。');
      return _toolText('已导入并启用');
    }

    // 询问：先导入为未启用，再排队确认是否启用。
    final imported = await _doImport(
      kind: kind,
      tabId: tabId,
      tabName: tabName,
      name: name,
      body: body,
      enabled: false,
      replyPayload: replyPayload,
      quickFormat: quickFormat,
    );
    if (imported is McpBridgeErr) return _toolError(_errText(imported));
    _log('通过 MCP 创建了$what $name，待确认启用（$tabName）。');

    final completer = Completer<McpAskOutcome>();
    final message = McpPendingMessage(
      id: 'm${++_seq}_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}',
      kind: kind,
      tabId: tabId,
      tabName: tabName,
      name: name,
      body: body,
      enqueuedAt: DateTime.now(),
      replyPayload: replyPayload,
    );
    final dropped = _queue.enqueue(message, completer);
    if (dropped != null) {
      _log(
        '消息队列已满，丢弃最早的${_kindLabel(dropped.kind)} ${dropped.name} 的启用确认（条目已导入未启用）。',
      );
    }
    _notify();
    final outcome = await completer.future;
    switch (outcome) {
      case McpAskOutcome.enabled:
        return _toolText('已导入并启用');
      case McpAskOutcome.disabled:
      case McpAskOutcome.dropped:
      case McpAskOutcome.revoked:
        return _toolText('已导入未启用');
    }
  }

  Future<McpBridgeResult> _doImport({
    required McpMessageKind kind,
    required String tabId,
    required String tabName,
    required String name,
    required String body,
    required bool enabled,
    Map<String, Object?>? replyPayload,
    String? quickFormat,
  }) {
    final bench = _workbench!;
    switch (kind) {
      case McpMessageKind.script:
        return bench.importScript(
          tabId: tabId,
          tabName: tabName,
          name: name,
          code: body,
          enabled: enabled,
        );
      case McpMessageKind.reply:
        return bench.importReply(
          tabId: tabId,
          tabName: tabName,
          name: name,
          payload: replyPayload ?? const {},
          enabled: enabled,
        );
      case McpMessageKind.quick:
        return bench.importQuick(
          tabId: tabId,
          tabName: tabName,
          name: name,
          data: body,
          format: quickFormat ?? 'hex',
          enabled: enabled,
        );
    }
  }

  ({McpResolvedTab? tab, Map<String, Object>? error}) _resolveTabArgs(
    Map<String, Object?> args,
  ) {
    final tabId = '${args['tabId'] ?? ''}'.trim();
    final tabName = '${args['tabName'] ?? ''}'.trim();
    final bench = _workbench;
    if (bench == null) {
      return (tab: null, error: _toolError('工作台未就绪'));
    }
    final resolved = bench.resolveTab(
      tabId: tabId.isEmpty ? null : tabId,
      tabName: tabName.isEmpty ? null : tabName,
    );
    if (resolved is McpBridgeErr) {
      return (tab: null, error: _toolError(_errText(resolved)));
    }
    final data = (resolved as McpBridgeOk).data;
    if (data is! McpResolvedTab) {
      return (tab: null, error: _toolError('页签解析失败'));
    }
    return (tab: data, error: null);
  }

  void _revokeKind(McpMessageKind kind) {
    final revoked = _queue.revokeWhere((m) => m.kind == kind);
    for (final item in revoked) {
      _log(
        '授权关闭，取消${_kindLabel(kind)} ${item.name} 的启用确认（已导入未启用）。',
      );
    }
  }

  String _kindLabel(McpMessageKind kind) => switch (kind) {
    McpMessageKind.script => '脚本',
    McpMessageKind.reply => '自动应答',
    McpMessageKind.quick => '快捷指令',
  };

  String _replyPreview(Map<String, Object?> payload) {
    final pattern = '${payload['pattern'] ?? ''}';
    final replies = payload['replies'];
    final buf = StringBuffer('匹配  $pattern');
    if (replies is List) {
      for (final item in replies) {
        if (item is Map) {
          buf.write('\n应答  ${item['data'] ?? ''}');
        }
      }
    }
    return buf.toString();
  }

  String _policyLabel(McpEnablePolicy policy) => switch (policy) {
    McpEnablePolicy.on => '默认启用',
    McpEnablePolicy.off => '默认禁用',
    McpEnablePolicy.ask => '询问',
  };

  String _errText(McpBridgeErr err) {
    if (err.detail != null && err.detail!.isNotEmpty) {
      return '${err.code}: ${err.detail}';
    }
    return err.code;
  }

  Map<String, Object> _toolText(String text) => {
    'content': [
      {'type': 'text', 'text': text},
    ],
  };

  Map<String, Object> _toolError(String text) => {
    'content': [
      {'type': 'text', 'text': text},
    ],
    'isError': true,
  };

  void _log(String body) {
    _logs.add(McpLogEntry(time: DateTime.now(), body: body));
    if (_logs.length > McpLimits.logLines) {
      _logs.removeRange(0, _logs.length - McpLimits.logLines);
    }
  }

  Future<void> _persist() => _store.write(_settings);

  void _notify() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}
