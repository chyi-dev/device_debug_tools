import 'dart:typed_data';

enum DataFormat { hex, ascii }

enum Parity { none, odd, even, mark, space }

enum StopBits { one, oneHalf, two }

enum FlowControl { none, rtsCts, dtrDsr, xonXoff }

enum ChecksumKind { none, sum, xor, lrc, crc8, crc16, crc32 }

enum MatchMode { prefix, frame, contains, suffix }

enum MatchKind { template, regex }

enum ToolTab { quick, batch, reply, history, calc, script }

/// 脚本钩子：收到一包数据后 / 数据发出前。
enum ScriptHook { onReceive, beforeSend }

enum LogDir { rx, tx, sys }

enum SysLogKind {
  opened,
  closed,
  autoReply,
  replySkipped,
  batchStart,
  batchDone,
  batchFail,
  batchStopped,
  scriptBlocked,
  scriptFailed,
}

enum EncodeError { empty, badHex }

enum SerialNoticeKind {
  ready,
  portOpened,
  portClosed,
  portClosedSend,
  portClosedRule,
  portClosedBatch,
  noPort,
  portBusy,
  openFailed,
  badHex,
  emptySend,
  configFailed,
  configPartial,
  baudInvalid,
  timeoutInvalid,
  periodInvalid,
  repeatInvalid,
  scanDone,
  paramsApplied,
  timeoutHint,
  timeoutSplitHint,
  saveStarted,
  saveWritten,
  saveCancelled,
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
  quickSaved,
  folderSaved,
  ruleSaved,
  batchSaved,
  checksumFilled,
  exportedConfig,
  importedConfig,
  importInvalid,
  fileLoaded,
}

class SerialNotice {
  const SerialNotice({
    required this.id,
    required this.kind,
    this.warn = false,
    this.args = const {},
  });

  final int id;
  final SerialNoticeKind kind;
  final bool warn;
  final Map<String, Object> args;
}

class SerialPortInfo {
  const SerialPortInfo({required this.name, required this.label});

  final String name;
  final String label;
}

class PinLevels {
  const PinLevels({
    this.dcd = false,
    this.dsr = false,
    this.cts = false,
    this.ri = false,
  });

  final bool dcd;
  final bool dsr;
  final bool cts;
  final bool ri;

  @override
  bool operator ==(Object other) =>
      other is PinLevels &&
      other.dcd == dcd &&
      other.dsr == dsr &&
      other.cts == cts &&
      other.ri == ri;

  @override
  int get hashCode => Object.hash(dcd, dsr, cts, ri);
}

class SerialLinkConfig {
  const SerialLinkConfig({
    required this.portName,
    required this.baud,
    required this.parity,
    required this.dataBits,
    required this.stopBits,
    required this.flow,
    required this.dtr,
    required this.rts,
  });

  final String portName;
  final int baud;
  final Parity parity;
  final int dataBits;
  final StopBits stopBits;
  final FlowControl flow;
  final bool dtr;
  final bool rts;
}

/// [full] 帧格式与线路均已写入；[partial] 仅帧格式/流控写入（Windows 降级）。
enum SerialOpenResult { full, partial }

class LogLine {
  const LogLine({
    required this.no,
    required this.time,
    required this.dir,
    this.bytes,
    this.sys,
    this.args = const {},
  });

  final int no;
  final DateTime time;
  final LogDir dir;
  final Uint8List? bytes;
  final SysLogKind? sys;
  final Map<String, Object> args;
}

/// 快捷指令列表的根节点：指令或单层文件夹（文件夹内只放指令）。
sealed class QuickNode {
  const QuickNode();

  String get id;

  Map<String, Object> toJson();

  /// 无 `type` 的旧指令对象按根目录指令解析。
  static QuickNode? fromJson(Object? raw) {
    if (raw is! Map) return null;
    if (raw['type'] == 'folder' || raw['commands'] is List) {
      return QuickFolder.fromJson(raw);
    }
    return QuickCommand.fromJson(raw);
  }
}

class QuickCommand extends QuickNode {
  const QuickCommand({
    required this.id,
    required this.name,
    required this.data,
    required this.format,
    this.key = '',
  });

  @override
  final String id;
  final String name;
  final String data;
  final DataFormat format;
  final String key;

  QuickCommand copyWith({String? key}) => QuickCommand(
    id: id,
    name: name,
    data: data,
    format: format,
    key: key ?? this.key,
  );

  @override
  Map<String, Object> toJson() => {
    'type': 'command',
    'id': id,
    'name': name,
    'data': data,
    'format': format.name,
    'key': key,
  };

  static QuickCommand? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name']?.toString() ?? '';
    final data = raw['data']?.toString() ?? '';
    if (name.isEmpty && data.isEmpty) return null;
    return QuickCommand(
      id: _id(raw['id'], 'q'),
      name: name.isEmpty ? data : name,
      data: data,
      format: raw['format'] == 'ascii' || raw['format'] == 'ASCII'
          ? DataFormat.ascii
          : DataFormat.hex,
      key: _fnKey(raw['key']),
    );
  }
}

class QuickFolder extends QuickNode {
  const QuickFolder({
    required this.id,
    required this.name,
    this.expanded = true,
    this.commands = const [],
  });

  @override
  final String id;
  final String name;
  final bool expanded;
  final List<QuickCommand> commands;

  QuickFolder copyWith({
    String? name,
    bool? expanded,
    List<QuickCommand>? commands,
  }) => QuickFolder(
    id: id,
    name: name ?? this.name,
    expanded: expanded ?? this.expanded,
    commands: commands ?? this.commands,
  );

  @override
  Map<String, Object> toJson() => {
    'type': 'folder',
    'id': id,
    'name': name,
    'expanded': expanded,
    'commands': commands.map((c) => c.toJson()).toList(),
  };

  static QuickFolder? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name']?.toString().trim() ?? '';
    if (name.isEmpty) return null;
    final list = raw['commands'];
    return QuickFolder(
      id: _id(raw['id'], 'f'),
      name: name,
      expanded: raw['expanded'] != false,
      commands: list is List
          ? [
              for (final item in list) QuickCommand.fromJson(item),
            ].whereType<QuickCommand>().toList()
          : const [],
    );
  }
}

extension QuickTree on List<QuickNode> {
  Iterable<QuickCommand> get commands sync* {
    for (final node in this) {
      switch (node) {
        case QuickCommand():
          yield node;
        case QuickFolder():
          yield* node.commands;
      }
    }
  }

  List<QuickFolder> get folders => whereType<QuickFolder>().toList();

  QuickCommand? commandById(String id) {
    for (final command in commands) {
      if (command.id == id) return command;
    }
    return null;
  }

  /// 指令所在文件夹 id；在根目录或不存在时为 null。
  String? folderIdOf(String commandId) {
    for (final folder in folders) {
      if (folder.commands.any((c) => c.id == commandId)) return folder.id;
    }
    return null;
  }

  /// 同一 F 键出现多次时保留先出现的那条。
  List<QuickNode> withUniqueKeys() {
    final used = <String>{};
    QuickCommand fix(QuickCommand c) {
      if (c.key.isEmpty) return c;
      return used.add(c.key) ? c : c.copyWith(key: '');
    }

    return [
      for (final node in this)
        switch (node) {
          QuickCommand() => fix(node),
          QuickFolder() => node.copyWith(
            commands: node.commands.map(fix).toList(),
          ),
        },
    ];
  }
}

class ReplyStep {
  const ReplyStep({required this.data, required this.delayMs});

  final String data;
  final int delayMs;

  Map<String, Object> toJson() => {'data': data, 'delay': delayMs};

  static ReplyStep? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return ReplyStep(
      data: raw['data']?.toString() ?? '',
      delayMs: _int(raw['delay']),
    );
  }
}

class ReplyRule {
  const ReplyRule({
    required this.id,
    required this.name,
    required this.match,
    required this.pattern,
    required this.enabled,
    required this.hits,
    required this.replies,
    this.kind = MatchKind.template,
    this.format = DataFormat.hex,
    this.ignoreCase = false,
  });

  final String id;
  final String name;
  final MatchMode match;
  final String pattern;
  final bool enabled;
  final int hits;
  final List<ReplyStep> replies;
  final MatchKind kind;
  final DataFormat format;

  /// 只对 ASCII 生效。
  final bool ignoreCase;

  ReplyRule copyWith({bool? enabled, int? hits, List<ReplyStep>? replies}) {
    return ReplyRule(
      id: id,
      name: name,
      match: match,
      pattern: pattern,
      enabled: enabled ?? this.enabled,
      hits: hits ?? this.hits,
      replies: replies ?? this.replies,
      kind: kind,
      format: format,
      ignoreCase: ignoreCase,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'match': match.name,
    'kind': kind.name,
    'format': format.name,
    'ignoreCase': ignoreCase,
    'pattern': pattern,
    'enabled': enabled,
    'hits': hits,
    'replies': replies.map((r) => r.toJson()).toList(),
  };

  static ReplyRule? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final replies = <ReplyStep>[];
    final list = raw['replies'];
    if (list is List) {
      for (final item in list) {
        final step = ReplyStep.fromJson(item);
        if (step != null) replies.add(step);
      }
    }
    return ReplyRule(
      id: _id(raw['id'], 'r'),
      name: raw['name']?.toString() ?? '',
      match: MatchMode.values.asNameMap()[raw['match']] ?? MatchMode.prefix,
      kind: MatchKind.values.asNameMap()[raw['kind']] ?? MatchKind.template,
      format: DataFormat.values.asNameMap()[raw['format']] ?? DataFormat.hex,
      ignoreCase: raw['ignoreCase'] == true,
      pattern: raw['pattern']?.toString() ?? '',
      enabled: raw['enabled'] == true,
      hits: _int(raw['hits']),
      replies: replies,
    );
  }
}

class BatchStep {
  const BatchStep({required this.data, required this.delayMs, this.note = ''});

  final String data;
  final int delayMs;
  final String note;

  Map<String, Object> toJson() => {
    'data': data,
    'delay': delayMs,
    'note': note,
  };

  static BatchStep? fromJson(Object? raw) {
    if (raw is String) {
      return BatchStep(data: raw, delayMs: 0);
    }
    if (raw is! Map) return null;
    return BatchStep(
      data: raw['data']?.toString() ?? '',
      delayMs: _int(raw['delay']),
      note: raw['note']?.toString() ?? '',
    );
  }
}

class BatchJob {
  const BatchJob({
    required this.id,
    required this.name,
    required this.repeat,
    required this.stopOnFail,
    required this.steps,
  });

  final String id;
  final String name;
  final int repeat;
  final bool stopOnFail;
  final List<BatchStep> steps;

  BatchJob copyWith({int? repeat, bool? stopOnFail, List<BatchStep>? steps}) {
    return BatchJob(
      id: id,
      name: name,
      repeat: repeat ?? this.repeat,
      stopOnFail: stopOnFail ?? this.stopOnFail,
      steps: steps ?? this.steps,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'repeat': repeat,
    'stopOnFail': stopOnFail,
    'steps': steps.map((s) => s.toJson()).toList(),
  };

  static BatchJob? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final steps = <BatchStep>[];
    final list = raw['steps'];
    if (list is List) {
      for (final item in list) {
        final step = BatchStep.fromJson(item);
        if (step != null) steps.add(step);
      }
    }
    return BatchJob(
      id: _id(raw['id'], 'b'),
      name: raw['name']?.toString() ?? '',
      repeat: _int(raw['repeat'], fallback: 1),
      stopOnFail: raw['stopOnFail'] != false,
      steps: steps,
    );
  }
}

class BatchProgress {
  const BatchProgress({
    required this.jobId,
    required this.step,
    required this.total,
    required this.round,
    required this.rounds,
  });

  final String jobId;
  final int step;
  final int total;
  final int round;
  final int rounds;
}

class HistoryEntry {
  const HistoryEntry({required this.text, this.time});

  final String text;
  final DateTime? time;

  Map<String, Object?> toJson() => {
    'text': text,
    'time': time?.toIso8601String(),
  };

  static HistoryEntry? fromJson(Object? raw) {
    if (raw is String) return HistoryEntry(text: raw);
    if (raw is! Map) return null;
    final text = raw['text']?.toString() ?? '';
    if (text.isEmpty) return null;
    final timeRaw = raw['time']?.toString();
    return HistoryEntry(
      text: text,
      time: timeRaw == null ? null : DateTime.tryParse(timeRaw),
    );
  }
}

class LuaScript {
  const LuaScript({
    required this.id,
    required this.name,
    required this.code,
    required this.enabled,
  });

  final String id;
  final String name;
  final String code;

  /// 只控制自动运行；停用时仍可手动运行。
  final bool enabled;

  LuaScript copyWith({String? name, String? code, bool? enabled}) => LuaScript(
    id: id,
    name: name ?? this.name,
    code: code ?? this.code,
    enabled: enabled ?? this.enabled,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'enabled': enabled,
  };

  static LuaScript? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name']?.toString().trim() ?? '';
    if (name.isEmpty) return null;
    return LuaScript(
      id: _id(raw['id'], 's'),
      name: name,
      code: raw['code']?.toString() ?? '',
      enabled: raw['enabled'] == true,
    );
  }

  static const presets = [
    LuaScript(
      id: 's1',
      name: 'parse_sensor.lua',
      enabled: true,
      code:
          '-- 收到 A5 5A 03 帧后解析温湿度\n'
          'function on_receive(frame)\n'
          '  if frame:starts_with(0xA5, 0x5A, 0x03) then\n'
          '    local t = frame:u16(4) / 10\n'
          '    local h = frame:u16(6) / 10\n'
          '    log(string.format("temp=%.1f℃ hum=%.1f%%", t, h))\n'
          '  end\n'
          'end\n',
    ),
    LuaScript(
      id: 's2',
      name: 'add_checksum.lua',
      enabled: false,
      code:
          '-- 发送前拦截：帧尾追加 SUM8 后再发出\n'
          '-- 返回 nil 表示拦截，这一帧不发送\n'
          'function before_send(frame)\n'
          '  return frame:append(sum8(frame))\n'
          'end\n',
    ),
  ];

  static const template =
      '-- 新脚本：收到数据时运行\n'
      'function on_receive(frame)\n'
      '  log(frame:hex())\n'
      'end\n';
}

/// 脚本编译结果与输出次数，不持久化。
class ScriptMeta {
  const ScriptMeta({this.hooks = const {}, this.error, this.outputs = 0});

  final Set<ScriptHook> hooks;
  final String? error;
  final int outputs;

  ScriptMeta copyWith({int? outputs}) =>
      ScriptMeta(hooks: hooks, error: error, outputs: outputs ?? this.outputs);
}

enum ScriptLogKind {
  /// 脚本里 log() 的原样输出。
  output,
  error,

  /// before_send 改写了帧。
  changed,
  blocked,
  dryRun,
  dryBlocked,
  manualRx,
  noRx,
  badTx,
  noHook,
  tooLong,

  /// 教程「样例试跑」的起始行，后面跟这段代码的输出。
  lessonTry,
}

class ScriptLogEntry {
  const ScriptLogEntry({
    required this.time,
    required this.name,
    required this.kind,
    this.text = '',
    this.from = '',
    this.to = '',
  });

  final DateTime time;
  final String name;
  final ScriptLogKind kind;
  final String text;
  final String from;
  final String to;

  bool get isError =>
      kind == ScriptLogKind.error ||
      kind == ScriptLogKind.tooLong ||
      kind == ScriptLogKind.badTx;
}

class PickedBytes {
  const PickedBytes({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class EncodeResult {
  const EncodeResult.ok(this.bytes) : error = null;

  const EncodeResult.fail(this.error) : bytes = null;

  final Uint8List? bytes;
  final EncodeError? error;
}

class SerialWorkspace {
  const SerialWorkspace({
    required this.portName,
    required this.baud,
    required this.parity,
    required this.dataBits,
    required this.stopBits,
    required this.flow,
    required this.dtr,
    required this.rts,
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

  final String? portName;
  final int baud;
  final Parity parity;
  final int dataBits;
  final StopBits stopBits;
  final FlowControl flow;
  final bool dtr;
  final bool rts;
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

  static SerialWorkspace defaults() => SerialWorkspace(
    portName: null,
    baud: 115200,
    parity: Parity.none,
    dataBits: 8,
    stopBits: StopBits.one,
    flow: FlowControl.none,
    dtr: true,
    rts: true,
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
    'portName': portName,
    'baud': baud,
    'parity': parity.name,
    'dataBits': dataBits,
    'stopBits': stopBits.name,
    'flow': flow.name,
    'dtr': dtr,
    'rts': rts,
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

  static SerialWorkspace? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final base = SerialWorkspace.defaults();
    List<T> listOf<T>(Object? value, T? Function(Object? item) parse) {
      if (value is! List) return [];
      return [for (final item in value) parse(item)].whereType<T>().toList();
    }

    final quick = listOf(raw['quick'], QuickNode.fromJson).withUniqueKeys();
    final rules = listOf(raw['rules'], ReplyRule.fromJson);
    final batch = listOf(raw['batch'], BatchJob.fromJson);
    final history = listOf(raw['history'], HistoryEntry.fromJson);
    final scripts = listOf(raw['scripts'], LuaScript.fromJson);
    return SerialWorkspace(
      portName: raw['portName']?.toString(),
      baud: _int(raw['baud'], fallback: base.baud),
      parity: Parity.values.asNameMap()[raw['parity']] ?? base.parity,
      dataBits: _int(raw['dataBits'], fallback: base.dataBits),
      stopBits: StopBits.values.asNameMap()[raw['stopBits']] ?? base.stopBits,
      flow: FlowControl.values.asNameMap()[raw['flow']] ?? base.flow,
      dtr: raw['dtr'] == true,
      rts: raw['rts'] == true,
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
      tab: ToolTab.values.asNameMap()[raw['tab']] ?? base.tab,
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

const fnKeys = ['F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8'];

String newSerialId(String prefix) =>
    '$prefix${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

String _id(Object? value, String prefix) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? newSerialId(prefix) : text;
}

String _fnKey(Object? value) {
  final text = value?.toString() ?? '';
  return fnKeys.contains(text) ? text : '';
}

DataFormat _format(Object? value, DataFormat fallback) {
  final name = value?.toString();
  if (name == 'ascii' || name == 'ASCII') return DataFormat.ascii;
  if (name == 'hex' || name == 'HEX') return DataFormat.hex;
  return fallback;
}

extension ParityToken on Parity {
  String get token => switch (this) {
    Parity.none => 'N',
    Parity.odd => 'O',
    Parity.even => 'E',
    Parity.mark => 'M',
    Parity.space => 'S',
  };
}

extension StopBitsToken on StopBits {
  String get label => switch (this) {
    StopBits.one => '1',
    StopBits.oneHalf => '1.5',
    StopBits.two => '2',
  };

  /// libserialport：1 与 2 为停止位数，1.5 在部分平台用 3 表示。
  int get wireValue => switch (this) {
    StopBits.one => 1,
    StopBits.two => 2,
    StopBits.oneHalf => 3,
  };
}

extension FlowToken on FlowControl {
  String get label => switch (this) {
    FlowControl.none => 'NONE',
    FlowControl.rtsCts => 'RTS/CTS',
    FlowControl.dtrDsr => 'DTR/DSR',
    FlowControl.xonXoff => 'XON/XOFF',
  };
}

String frameLabel({
  required int dataBits,
  required Parity parity,
  required StopBits stopBits,
}) => '$dataBits${parity.token}${stopBits.label}';
