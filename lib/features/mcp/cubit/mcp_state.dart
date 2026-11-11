import '../model/mcp_models.dart';

class McpState {
  const McpState({
    required this.settings,
    required this.listening,
    required this.clientConnected,
    required this.boundPort,
    required this.pending,
    required this.logs,
  });

  factory McpState.initial(McpSettings settings) => McpState(
    settings: settings,
    listening: false,
    clientConnected: false,
    boundPort: null,
    pending: const [],
    logs: const [],
  );

  final McpSettings settings;
  final bool listening;
  final bool clientConnected;
  final int? boundPort;
  final List<McpPendingMessage> pending;
  final List<McpLogEntry> logs;

  int get pendingCount => pending.length;

  String get endpoint {
    final port = boundPort ?? settings.port;
    return 'http://127.0.0.1:$port/mcp';
  }

  String get cursorConfigJson {
    final port = boundPort ?? settings.port;
    return '''
{
  "mcpServers": {
    "device_debug_tools": {
      "url": "http://127.0.0.1:$port/mcp"
    }
  }
}''';
  }

  McpState copyWith({
    McpSettings? settings,
    bool? listening,
    bool? clientConnected,
    int? boundPort,
    bool clearBoundPort = false,
    List<McpPendingMessage>? pending,
    List<McpLogEntry>? logs,
  }) {
    return McpState(
      settings: settings ?? this.settings,
      listening: listening ?? this.listening,
      clientConnected: clientConnected ?? this.clientConnected,
      boundPort: clearBoundPort ? null : (boundPort ?? this.boundPort),
      pending: pending ?? this.pending,
      logs: logs ?? this.logs,
    );
  }
}
