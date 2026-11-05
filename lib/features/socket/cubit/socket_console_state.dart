import 'dart:typed_data';

import '../../serial/model/serial_models.dart';
import '../model/socket_models.dart';

const _keep = Object();

class SocketConsoleState {
  const SocketConsoleState({
    required this.protocol,
    required this.role,
    required this.host,
    required this.port,
    required this.remoteHost,
    required this.remotePort,
    required this.open,
    required this.busy,
    required this.peers,
    required this.selectedPeerId,
    required this.rxFormat,
    required this.logMode,
    required this.wrap,
    required this.hideRx,
    required this.autoScroll,
    required this.packetTimeoutMs,
    required this.saveActive,
    required this.saveName,
    required this.savedCount,
    required this.txFormat,
    required this.escape,
    required this.atCrlf,
    required this.crlf,
    required this.checksum,
    required this.clearAfterSend,
    required this.loopEnabled,
    required this.loopPeriodMs,
    required this.looping,
    required this.txText,
    required this.fileName,
    required this.fileBytes,
    required this.lines,
    required this.rxCount,
    required this.txCount,
    required this.compact,
    required this.toolsVisible,
    required this.tab,
    required this.quick,
    required this.rules,
    required this.batch,
    required this.selectedBatchId,
    required this.batchRun,
    required this.history,
    required this.scripts,
    required this.scriptMeta,
    required this.scriptLog,
    required this.selectedScriptId,
    required this.scriptDock,
    required this.scriptTutorial,
    required this.openLesson,
    required this.hint,
    required this.toast,
  });

  factory SocketConsoleState.initial(SocketProtocol protocol) {
    final ws = SocketWorkspace.defaults();
    return SocketConsoleState(
      protocol: protocol,
      role: protocol == SocketProtocol.udp ? SocketRole.client : ws.role,
      host: ws.host,
      port: ws.port,
      remoteHost: ws.remoteHost,
      remotePort: ws.remotePort,
      open: false,
      busy: false,
      peers: const [],
      selectedPeerId: null,
      rxFormat: ws.rxFormat,
      logMode: ws.logMode,
      wrap: ws.wrap,
      hideRx: ws.hideRx,
      autoScroll: ws.autoScroll,
      packetTimeoutMs: ws.packetTimeoutMs,
      saveActive: false,
      saveName: '',
      savedCount: 0,
      txFormat: ws.txFormat,
      escape: ws.escape,
      atCrlf: ws.atCrlf,
      crlf: ws.crlf,
      checksum: ws.checksum,
      clearAfterSend: ws.clearAfterSend,
      loopEnabled: ws.loopEnabled,
      loopPeriodMs: ws.loopPeriodMs,
      looping: false,
      txText: ws.txText,
      fileName: null,
      fileBytes: null,
      lines: const [],
      rxCount: 0,
      txCount: 0,
      compact: ws.compact,
      toolsVisible: ws.toolsVisible,
      tab: ws.tab,
      quick: ws.quick,
      rules: ws.rules,
      batch: ws.batch,
      selectedBatchId: ws.selectedBatchId,
      batchRun: null,
      history: ws.history,
      scripts: ws.scripts,
      scriptMeta: const {},
      scriptLog: const [],
      selectedScriptId: ws.scripts.isEmpty ? null : ws.scripts.first.id,
      scriptDock: true,
      scriptTutorial: false,
      openLesson: 'hooks',
      hint: const SocketNotice(id: 0, kind: SocketNoticeKind.ready),
      toast: null,
    );
  }

  final SocketProtocol protocol;
  final SocketRole role;
  final String host;
  final int port;
  final String remoteHost;
  final int remotePort;
  final bool open;
  final bool busy;
  final List<SocketPeer> peers;
  /// TCP 服务端：null 表示发给全部客户端。
  final String? selectedPeerId;
  final DataFormat rxFormat;
  final bool logMode;
  final bool wrap;
  final bool hideRx;
  final bool autoScroll;
  final int packetTimeoutMs;
  final bool saveActive;
  final String saveName;
  final int savedCount;
  final DataFormat txFormat;
  final bool escape;
  final bool atCrlf;
  final bool crlf;
  final ChecksumKind checksum;
  final bool clearAfterSend;
  final bool loopEnabled;
  final int loopPeriodMs;
  final bool looping;
  final String txText;
  final String? fileName;
  final Uint8List? fileBytes;
  final List<SocketLogLine> lines;
  final int rxCount;
  final int txCount;
  final bool compact;
  final bool toolsVisible;
  final ToolTab tab;
  final List<QuickNode> quick;
  final List<ReplyRule> rules;
  final List<BatchJob> batch;
  final String? selectedBatchId;
  final BatchProgress? batchRun;
  final List<HistoryEntry> history;
  final List<LuaScript> scripts;
  final Map<String, ScriptMeta> scriptMeta;
  final List<ScriptLogEntry> scriptLog;
  final String? selectedScriptId;
  final bool scriptDock;
  final bool scriptTutorial;
  final String? openLesson;
  final SocketNotice hint;
  final SocketNotice? toast;

  bool get isTcp => protocol == SocketProtocol.tcp;

  bool get isUdp => protocol == SocketProtocol.udp;

  bool get isTcpServer => isTcp && role == SocketRole.server;

  bool get isTcpClient => isTcp && role == SocketRole.client;

  LuaScript? get selectedScript {
    for (final script in scripts) {
      if (script.id == selectedScriptId) return script;
    }
    return scripts.isEmpty ? null : scripts.first;
  }

  bool get scriptDockVisible =>
      toolsVisible && tab == ToolTab.script && scriptDock && scripts.isNotEmpty;

  String get endpoint {
    if (isUdp) return 'UDP $host:$port';
    if (isTcpServer) return 'TCP LISTEN $host:$port';
    return 'TCP $host:$port';
  }

  String get connectionLabel {
    final mark = open ? 'OPENED' : 'CLOSED';
    if (isUdp) return 'UDP $host:$port $mark → $remoteHost:$remotePort';
    if (isTcpServer) {
      String target = 'ALL(${peers.length})';
      if (selectedPeerId != null) {
        target = selectedPeerId!;
        for (final peer in peers) {
          if (peer.id == selectedPeerId) {
            target = peer.address;
            break;
          }
        }
      }
      return 'TCP SERVER $host:$port $mark → $target';
    }
    return 'TCP CLIENT $host:$port $mark';
  }

  SocketWorkspace toWorkspace() => SocketWorkspace(
    role: role,
    host: host,
    port: port,
    remoteHost: remoteHost,
    remotePort: remotePort,
    rxFormat: rxFormat,
    logMode: logMode,
    wrap: wrap,
    hideRx: hideRx,
    autoScroll: autoScroll,
    packetTimeoutMs: packetTimeoutMs,
    txFormat: txFormat,
    escape: escape,
    atCrlf: atCrlf,
    crlf: crlf,
    checksum: checksum,
    clearAfterSend: clearAfterSend,
    loopEnabled: loopEnabled,
    loopPeriodMs: loopPeriodMs,
    txText: txText,
    compact: compact,
    toolsVisible: toolsVisible,
    tab: tab,
    quick: quick,
    rules: rules,
    batch: batch,
    selectedBatchId: selectedBatchId,
    history: history,
    scripts: scripts,
  );

  SocketConsoleState copyWith({
    SocketRole? role,
    String? host,
    int? port,
    String? remoteHost,
    int? remotePort,
    bool? open,
    bool? busy,
    List<SocketPeer>? peers,
    Object? selectedPeerId = _keep,
    DataFormat? rxFormat,
    bool? logMode,
    bool? wrap,
    bool? hideRx,
    bool? autoScroll,
    int? packetTimeoutMs,
    bool? saveActive,
    String? saveName,
    int? savedCount,
    DataFormat? txFormat,
    bool? escape,
    bool? atCrlf,
    bool? crlf,
    ChecksumKind? checksum,
    bool? clearAfterSend,
    bool? loopEnabled,
    int? loopPeriodMs,
    bool? looping,
    String? txText,
    Object? fileName = _keep,
    Object? fileBytes = _keep,
    List<SocketLogLine>? lines,
    int? rxCount,
    int? txCount,
    bool? compact,
    bool? toolsVisible,
    ToolTab? tab,
    List<QuickNode>? quick,
    List<ReplyRule>? rules,
    List<BatchJob>? batch,
    Object? selectedBatchId = _keep,
    Object? batchRun = _keep,
    List<HistoryEntry>? history,
    List<LuaScript>? scripts,
    Map<String, ScriptMeta>? scriptMeta,
    List<ScriptLogEntry>? scriptLog,
    Object? selectedScriptId = _keep,
    bool? scriptDock,
    bool? scriptTutorial,
    Object? openLesson = _keep,
    SocketNotice? hint,
    Object? toast = _keep,
  }) {
    return SocketConsoleState(
      protocol: protocol,
      role: role ?? this.role,
      host: host ?? this.host,
      port: port ?? this.port,
      remoteHost: remoteHost ?? this.remoteHost,
      remotePort: remotePort ?? this.remotePort,
      open: open ?? this.open,
      busy: busy ?? this.busy,
      peers: peers ?? this.peers,
      selectedPeerId: selectedPeerId == _keep
          ? this.selectedPeerId
          : selectedPeerId as String?,
      rxFormat: rxFormat ?? this.rxFormat,
      logMode: logMode ?? this.logMode,
      wrap: wrap ?? this.wrap,
      hideRx: hideRx ?? this.hideRx,
      autoScroll: autoScroll ?? this.autoScroll,
      packetTimeoutMs: packetTimeoutMs ?? this.packetTimeoutMs,
      saveActive: saveActive ?? this.saveActive,
      saveName: saveName ?? this.saveName,
      savedCount: savedCount ?? this.savedCount,
      txFormat: txFormat ?? this.txFormat,
      escape: escape ?? this.escape,
      atCrlf: atCrlf ?? this.atCrlf,
      crlf: crlf ?? this.crlf,
      checksum: checksum ?? this.checksum,
      clearAfterSend: clearAfterSend ?? this.clearAfterSend,
      loopEnabled: loopEnabled ?? this.loopEnabled,
      loopPeriodMs: loopPeriodMs ?? this.loopPeriodMs,
      looping: looping ?? this.looping,
      txText: txText ?? this.txText,
      fileName: fileName == _keep ? this.fileName : fileName as String?,
      fileBytes: fileBytes == _keep ? this.fileBytes : fileBytes as Uint8List?,
      lines: lines ?? this.lines,
      rxCount: rxCount ?? this.rxCount,
      txCount: txCount ?? this.txCount,
      compact: compact ?? this.compact,
      toolsVisible: toolsVisible ?? this.toolsVisible,
      tab: tab ?? this.tab,
      quick: quick ?? this.quick,
      rules: rules ?? this.rules,
      batch: batch ?? this.batch,
      selectedBatchId: selectedBatchId == _keep
          ? this.selectedBatchId
          : selectedBatchId as String?,
      batchRun: batchRun == _keep ? this.batchRun : batchRun as BatchProgress?,
      history: history ?? this.history,
      scripts: scripts ?? this.scripts,
      scriptMeta: scriptMeta ?? this.scriptMeta,
      scriptLog: scriptLog ?? this.scriptLog,
      selectedScriptId: selectedScriptId == _keep
          ? this.selectedScriptId
          : selectedScriptId as String?,
      scriptDock: scriptDock ?? this.scriptDock,
      scriptTutorial: scriptTutorial ?? this.scriptTutorial,
      openLesson: openLesson == _keep ? this.openLesson : openLesson as String?,
      hint: hint ?? this.hint,
      toast: toast == _keep ? this.toast : toast as SocketNotice?,
    );
  }
}
