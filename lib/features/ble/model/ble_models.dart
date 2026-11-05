import 'dart:typed_data';

import '../../serial/model/serial_models.dart';

enum BleWriteType { withoutResponse, withResponse }

enum BleNoticeKind {
  ready,
  adapterOff,
  scanDone,
  scanEmpty,
  scanFailed,
  noDevice,
  connected,
  connectFailed,
  disconnected,
  pinNotify,
  unpinNotify,
  pinWrite,
  unpinWrite,
  noWrite,
  sentNoNotify,
  badHex,
  emptySend,
  mtuInvalid,
  chunkInvalid,
  logSaved,
  recvCleared,
  batchRunning,
  batchEnded,
  ruleOn,
  ruleOff,
  deleted,
  duplicated,
  quickSaved,
  ruleSaved,
  batchSaved,
  scriptSaved,
  closedSend,
}

/// BLE 右侧工具页，不含串口的校验计算。
const kBleToolTabs = <ToolTab>[
  ToolTab.quick,
  ToolTab.batch,
  ToolTab.reply,
  ToolTab.history,
  ToolTab.script,
];

ToolTab bleToolTab(ToolTab tab) =>
    tab == ToolTab.calc ? ToolTab.quick : tab;

class BleNotice {
  const BleNotice({
    required this.id,
    required this.kind,
    this.warn = false,
    this.args = const {},
  });

  final int id;
  final BleNoticeKind kind;
  final bool warn;
  final Map<String, Object> args;
}

class BleDeviceInfo {
  const BleDeviceInfo({
    required this.id,
    required this.name,
    required this.address,
    this.rssi = 0,
  });

  final String id;
  final String name;
  final String address;
  final int rssi;

  String get label => name.trim().isEmpty ? address : name;
}

class BleCharacteristicInfo {
  const BleCharacteristicInfo({
    required this.uuid,
    required this.serviceUuid,
    this.name = '',
    this.canNotify = false,
    this.canWrite = false,
    this.canWriteWithoutResponse = false,
    this.canRead = false,
  });

  final String uuid;
  final String serviceUuid;
  final String name;
  final bool canNotify;
  final bool canWrite;
  final bool canWriteWithoutResponse;
  final bool canRead;

  bool get pinNotify => canNotify;
  bool get pinWrite => canWrite || canWriteWithoutResponse;
  bool get readOnly => canRead && !pinNotify && !pinWrite;

  String get title => name.trim().isEmpty ? uuid : '$name · $uuid';
}

class BleServiceInfo {
  const BleServiceInfo({
    required this.uuid,
    this.name = '',
    this.characteristics = const [],
    this.expanded = true,
  });

  final String uuid;
  final String name;
  final List<BleCharacteristicInfo> characteristics;
  final bool expanded;

  String get title => name.trim().isEmpty ? uuid : '$name · $uuid';

  BleServiceInfo copyWith({bool? expanded}) => BleServiceInfo(
    uuid: uuid,
    name: name,
    characteristics: characteristics,
    expanded: expanded ?? this.expanded,
  );
}

class BleNotifyEvent {
  const BleNotifyEvent({
    required this.deviceId,
    required this.serviceUuid,
    required this.characteristicUuid,
    required this.value,
  });

  final String deviceId;
  final String serviceUuid;
  final String characteristicUuid;
  final Uint8List value;
}

class BleLogLine {
  const BleLogLine({
    required this.no,
    required this.time,
    required this.dir,
    this.bytes,
    this.text = '',
  });

  final int no;
  final DateTime time;
  final LogDir dir;
  final Uint8List? bytes;
  final String text;
}

class BleWorkspace {
  const BleWorkspace({
    required this.filter,
    required this.writeType,
    required this.mtu,
    required this.chunkSize,
    required this.compact,
    required this.toolsVisible,
    required this.tab,
    required this.txText,
    required this.wrap,
    required this.autoScroll,
    required this.quick,
    required this.rules,
    required this.batch,
    required this.history,
    required this.scripts,
  });

  factory BleWorkspace.defaults() => BleWorkspace(
    filter: '',
    writeType: BleWriteType.withoutResponse,
    mtu: 247,
    chunkSize: 180,
    compact: false,
    toolsVisible: true,
    tab: ToolTab.quick,
    txText: '',
    wrap: true,
    autoScroll: true,
    quick: const [],
    rules: const [],
    batch: const [],
    history: const [],
    scripts: const [],
  );

  final String filter;
  final BleWriteType writeType;
  final int mtu;
  final int chunkSize;
  final bool compact;
  final bool toolsVisible;
  final ToolTab tab;
  final String txText;
  final bool wrap;
  final bool autoScroll;
  final List<QuickCommand> quick;
  final List<ReplyRule> rules;
  final List<BatchJob> batch;
  final List<HistoryEntry> history;
  final List<LuaScript> scripts;

  Map<String, Object> toJson() => {
    'filter': filter,
    'writeType': writeType.name,
    'mtu': mtu,
    'chunkSize': chunkSize,
    'compact': compact,
    'toolsVisible': toolsVisible,
    'tab': tab.name,
    'txText': txText,
    'wrap': wrap,
    'autoScroll': autoScroll,
    'quick': quick.map((item) => item.toJson()).toList(),
    'rules': rules.map((item) => item.toJson()).toList(),
    'batch': batch.map((item) => item.toJson()).toList(),
    'history': history.map((item) => item.toJson()).toList(),
    'scripts': scripts.map((item) => item.toJson()).toList(),
  };

  static BleWorkspace fromJson(Object raw) {
    final map = raw is Map ? raw : const {};
    final quick = <QuickCommand>[];
    final rules = <ReplyRule>[];
    final batch = <BatchJob>[];
    final history = <HistoryEntry>[];
    final scripts = <LuaScript>[];
    final quickRaw = map['quick'];
    if (quickRaw is List) {
      for (final item in quickRaw) {
        final command = QuickCommand.fromJson(item);
        if (command != null) quick.add(command);
      }
    }
    final rulesRaw = map['rules'];
    if (rulesRaw is List) {
      for (final item in rulesRaw) {
        final rule = ReplyRule.fromJson(item);
        if (rule != null) rules.add(rule);
      }
    }
    final batchRaw = map['batch'];
    if (batchRaw is List) {
      for (final item in batchRaw) {
        final job = BatchJob.fromJson(item);
        if (job != null) batch.add(job);
      }
    }
    final historyRaw = map['history'];
    if (historyRaw is List) {
      for (final item in historyRaw) {
        final entry = HistoryEntry.fromJson(item);
        if (entry != null) history.add(entry);
      }
    }
    final scriptsRaw = map['scripts'];
    if (scriptsRaw is List) {
      for (final item in scriptsRaw) {
        final script = LuaScript.fromJson(item);
        if (script != null) scripts.add(script);
      }
    }
    return BleWorkspace(
      filter: map['filter']?.toString() ?? '',
      writeType: BleWriteType.values.asNameMap()[map['writeType']?.toString()] ??
          BleWriteType.withoutResponse,
      mtu: _int(map['mtu'], 247),
      chunkSize: _int(map['chunkSize'], 180),
      compact: map['compact'] == true,
      toolsVisible: map['toolsVisible'] != false,
      tab: bleToolTab(
        ToolTab.values.asNameMap()[map['tab']?.toString()] ?? ToolTab.quick,
      ),
      txText: map['txText']?.toString() ?? '',
      wrap: map['wrap'] != false,
      autoScroll: map['autoScroll'] != false,
      quick: quick,
      rules: rules,
      batch: batch,
      history: history,
      scripts: scripts,
    );
  }
}

int _int(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}
