import 'dart:typed_data';

import '../../serial/model/serial_models.dart';

/// TCP / UDP 共用一套调试台；协议由页签类型决定。
enum SocketProtocol { tcp, udp }

/// 仅 TCP：客户端连远端，或本机监听。
enum SocketRole { client, server }

enum SocketNoticeKind {
  ready,
  opened,
  closed,
  closedSend,
  closedRule,
  closedBatch,
  openFailed,
  badHex,
  emptySend,
  noRemote,
  noClient,
  hostInvalid,
  portInvalid,
  timeoutInvalid,
  periodInvalid,
  repeatInvalid,
  saveStarted,
  saveWritten,
  logSaved,
  recvCleared,
  loopStarted,
  loopStopped,
  batchRunning,
  batchEnded,
  ruleToggled,
  scriptToggled,
  scriptSaved,
  lessonCreated,
  lessonTried,
  deleted,
  duplicated,
  quickSaved,
  folderSaved,
  ruleSaved,
  batchSaved,
  fileLoaded,
  peerJoined,
  peerLeft,
  roleChanged,
}

class SocketNotice {
  const SocketNotice({
    required this.id,
    required this.kind,
    this.warn = false,
    this.args = const {},
  });

  final int id;
  final SocketNoticeKind kind;
  final bool warn;
  final Map<String, Object> args;
}

class SocketPeer {
  const SocketPeer({required this.id, required this.address});

  final String id;
  final String address;
}

/// Gateway 推上来的一帧；TCP 服务端 / UDP 带来源。
class SocketIncoming {
  const SocketIncoming({
    required this.bytes,
    this.peerId,
    this.peerAddress,
  });

  final Uint8List bytes;
  final String? peerId;
  final String? peerAddress;
}

class SocketLogLine {
  const SocketLogLine({
    required this.no,
    required this.time,
    required this.dir,
    this.bytes,
    this.sys,
    this.args = const {},
    this.peer,
  });

  final int no;
  final DateTime time;
  final LogDir dir;
  final Uint8List? bytes;
  final SysLogKind? sys;
  final Map<String, Object> args;
  final String? peer;
}

class SocketWorkspace {
  const SocketWorkspace({
    required this.role,
    required this.host,
    required this.port,
    required this.remoteHost,
    required this.remotePort,
    required this.rxFormat,
    required this.logMode,
    required this.wrap,
    required this.hideRx,
    required this.autoScroll,
    required this.packetTimeoutMs,
    required this.txFormat,
    required this.escape,
    required this.atCrlf,
    required this.crlf,
    required this.checksum,
    required this.clearAfterSend,
    required this.loopEnabled,
    required this.loopPeriodMs,
    required this.txText,
    required this.compact,
    required this.toolsVisible,
    required this.tab,
    required this.quick,
    required this.rules,
    required this.batch,
    required this.selectedBatchId,
    required this.history,
    required this.scripts,
  });

  final SocketRole role;
  final String host;
  final int port;
  final String remoteHost;
  final int remotePort;
  final DataFormat rxFormat;
  final bool logMode;
  final bool wrap;
  final bool hideRx;
  final bool autoScroll;
  final int packetTimeoutMs;
  final DataFormat txFormat;
  final bool escape;
  final bool atCrlf;
  final bool crlf;
  final ChecksumKind checksum;
  final bool clearAfterSend;
  final bool loopEnabled;
  final int loopPeriodMs;
  final String txText;
  final bool compact;
  final bool toolsVisible;
  final ToolTab tab;
  final List<QuickNode> quick;
  final List<ReplyRule> rules;
  final List<BatchJob> batch;
  final String? selectedBatchId;
  final List<HistoryEntry> history;
  final List<LuaScript> scripts;

  static SocketWorkspace defaults() => SocketWorkspace(
    role: SocketRole.client,
    host: '127.0.0.1',
    port: 8080,
    remoteHost: '127.0.0.1',
    remotePort: 8080,
    rxFormat: DataFormat.hex,
    logMode: true,
    wrap: true,
    hideRx: false,
    autoScroll: true,
    packetTimeoutMs: 20,
    txFormat: DataFormat.hex,
    escape: true,
    atCrlf: false,
    crlf: false,
    checksum: ChecksumKind.none,
    clearAfterSend: false,
    loopEnabled: false,
    loopPeriodMs: 1000,
    txText: '',
    compact: false,
    toolsVisible: true,
    tab: ToolTab.quick,
    quick: const [],
    rules: const [],
    batch: const [],
    selectedBatchId: null,
    history: const [],
    scripts: LuaScript.presets,
  );

  Map<String, Object?> toJson() => {
    'role': role.name,
    'host': host,
    'port': port,
    'remoteHost': remoteHost,
    'remotePort': remotePort,
    'rxFormat': rxFormat.name,
    'logMode': logMode,
    'wrap': wrap,
    'hideRx': hideRx,
    'autoScroll': autoScroll,
    'packetTimeoutMs': packetTimeoutMs,
    'txFormat': txFormat.name,
    'escape': escape,
    'atCrlf': atCrlf,
    'crlf': crlf,
    'checksum': checksum.name,
    'clearAfterSend': clearAfterSend,
    'loopEnabled': loopEnabled,
    'loopPeriodMs': loopPeriodMs,
    'txText': txText,
    'compact': compact,
    'toolsVisible': toolsVisible,
    'tab': tab.name,
    'quick': quick.map((q) => q.toJson()).toList(),
    'rules': rules.map((r) => r.toJson()).toList(),
    'batch': batch.map((b) => b.toJson()).toList(),
    'selectedBatchId': selectedBatchId,
    'history': history.map((h) => h.toJson()).toList(),
    'scripts': scripts.map((s) => s.toJson()).toList(),
  };

  static SocketWorkspace? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final base = SocketWorkspace.defaults();
    List<T> listOf<T>(Object? value, T? Function(Object? item) parse) {
      if (value is! List) return [];
      return [for (final item in value) parse(item)].whereType<T>().toList();
    }

    final quick = listOf(raw['quick'], QuickNode.fromJson).withUniqueKeys();
    final rules = listOf(raw['rules'], ReplyRule.fromJson);
    final batch = listOf(raw['batch'], BatchJob.fromJson);
    final history = listOf(raw['history'], HistoryEntry.fromJson);
    final scripts = listOf(raw['scripts'], LuaScript.fromJson);
    return SocketWorkspace(
      role: SocketRole.values.asNameMap()[raw['role']] ?? base.role,
      host: raw['host']?.toString() ?? base.host,
      port: _int(raw['port'], fallback: base.port),
      remoteHost: raw['remoteHost']?.toString() ?? base.remoteHost,
      remotePort: _int(raw['remotePort'], fallback: base.remotePort),
      rxFormat: _format(raw['rxFormat'], base.rxFormat),
      logMode: raw['logMode'] != false,
      wrap: raw['wrap'] != false,
      hideRx: raw['hideRx'] == true,
      autoScroll: raw['autoScroll'] != false,
      packetTimeoutMs: _int(raw['packetTimeoutMs'], fallback: 20),
      txFormat: _format(raw['txFormat'], base.txFormat),
      escape: raw['escape'] != false,
      atCrlf: raw['atCrlf'] == true,
      crlf: raw['crlf'] == true,
      checksum:
          ChecksumKind.values.asNameMap()[raw['checksum']] ?? base.checksum,
      clearAfterSend: raw['clearAfterSend'] == true,
      loopEnabled: raw['loopEnabled'] == true,
      loopPeriodMs: _int(raw['loopPeriodMs'], fallback: 1000),
      txText: raw['txText']?.toString() ?? base.txText,
      compact: raw['compact'] == true,
      toolsVisible: raw['toolsVisible'] != false,
      tab: () {
        final parsed = ToolTab.values.asNameMap()[raw['tab']] ?? base.tab;
        return parsed == ToolTab.calc ? ToolTab.quick : parsed;
      }(),
      quick: raw.containsKey('quick') ? quick : base.quick,
      rules: raw.containsKey('rules') ? rules : base.rules,
      batch: raw.containsKey('batch') ? batch : base.batch,
      selectedBatchId:
          raw['selectedBatchId']?.toString() ?? base.selectedBatchId,
      history: history,
      scripts: raw.containsKey('scripts') ? scripts : base.scripts,
    );
  }
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

DataFormat _format(Object? value, DataFormat fallback) {
  final name = value?.toString();
  if (name == 'ascii' || name == 'ASCII') return DataFormat.ascii;
  if (name == 'hex' || name == 'HEX') return DataFormat.hex;
  return fallback;
}
