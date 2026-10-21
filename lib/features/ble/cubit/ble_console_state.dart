import '../../serial/model/serial_models.dart';
import '../model/ble_models.dart';

const _keep = Object();

class BleConsoleState {
  const BleConsoleState({
    required this.filter,
    required this.scanning,
    required this.scanned,
    required this.adapterReady,
    required this.devices,
    required this.selectedId,
    required this.connected,
    required this.connecting,
    required this.services,
    required this.pinNotify,
    required this.pinWrite,
    required this.writeType,
    required this.mtu,
    required this.chunkSize,
    required this.txText,
    required this.lines,
    required this.rxCount,
    required this.txCount,
    required this.wrap,
    required this.autoScroll,
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
    required this.hint,
    required this.toast,
  });

  factory BleConsoleState.initial() {
    final ws = BleWorkspace.defaults();
    return BleConsoleState(
      filter: ws.filter,
      scanning: false,
      scanned: false,
      adapterReady: true,
      devices: const [],
      selectedId: null,
      connected: false,
      connecting: false,
      services: const [],
      pinNotify: null,
      pinWrite: null,
      writeType: ws.writeType,
      mtu: ws.mtu,
      chunkSize: ws.chunkSize,
      txText: ws.txText,
      lines: const [],
      rxCount: 0,
      txCount: 0,
      wrap: ws.wrap,
      autoScroll: ws.autoScroll,
      compact: ws.compact,
      toolsVisible: ws.toolsVisible,
      tab: ws.tab,
      quick: ws.quick,
      rules: ws.rules,
      batch: ws.batch,
      selectedBatchId: ws.batch.isEmpty ? null : ws.batch.first.id,
      batchRun: null,
      history: ws.history,
      scripts: ws.scripts,
      scriptMeta: const {},
      scriptLog: const [],
      hint: const BleNotice(id: 0, kind: BleNoticeKind.ready),
      toast: null,
    );
  }

  final String filter;
  final bool scanning;
  final bool scanned;
  final bool adapterReady;
  final List<BleDeviceInfo> devices;
  final String? selectedId;
  final bool connected;
  final bool connecting;
  final List<BleServiceInfo> services;
  final BleCharacteristicInfo? pinNotify;
  final BleCharacteristicInfo? pinWrite;
  final BleWriteType writeType;
  final int mtu;
  final int chunkSize;
  final String txText;
  final List<BleLogLine> lines;
  final int rxCount;
  final int txCount;
  final bool wrap;
  final bool autoScroll;
  final bool compact;
  final bool toolsVisible;
  final ToolTab tab;
  final List<QuickCommand> quick;
  final List<ReplyRule> rules;
  final List<BatchJob> batch;
  final String? selectedBatchId;
  final BatchProgress? batchRun;
  final List<HistoryEntry> history;
  final List<LuaScript> scripts;
  final Map<String, ScriptMeta> scriptMeta;
  final List<ScriptLogEntry> scriptLog;
  final BleNotice hint;
  final BleNotice? toast;

  BleDeviceInfo? get selected {
    for (final device in devices) {
      if (device.id == selectedId) return device;
    }
    return null;
  }

  String? get deviceName => selected?.label;

  List<BleDeviceInfo> get visibleDevices {
    final q = filter.trim().toLowerCase();
    if (q.isEmpty) return devices;
    return [
      for (final device in devices)
        if (device.name.toLowerCase().contains(q) ||
            device.address.toLowerCase().contains(q))
          device,
    ];
  }

  BleConsoleState copyWith({
    String? filter,
    bool? scanning,
    bool? scanned,
    bool? adapterReady,
    List<BleDeviceInfo>? devices,
    Object? selectedId = _keep,
    bool? connected,
    bool? connecting,
    List<BleServiceInfo>? services,
    Object? pinNotify = _keep,
    Object? pinWrite = _keep,
    BleWriteType? writeType,
    int? mtu,
    int? chunkSize,
    String? txText,
    List<BleLogLine>? lines,
    int? rxCount,
    int? txCount,
    bool? wrap,
    bool? autoScroll,
    bool? compact,
    bool? toolsVisible,
    ToolTab? tab,
    List<QuickCommand>? quick,
    List<ReplyRule>? rules,
    List<BatchJob>? batch,
    Object? selectedBatchId = _keep,
    Object? batchRun = _keep,
    List<HistoryEntry>? history,
    List<LuaScript>? scripts,
    Map<String, ScriptMeta>? scriptMeta,
    List<ScriptLogEntry>? scriptLog,
    BleNotice? hint,
    Object? toast = _keep,
  }) {
    return BleConsoleState(
      filter: filter ?? this.filter,
      scanning: scanning ?? this.scanning,
      scanned: scanned ?? this.scanned,
      adapterReady: adapterReady ?? this.adapterReady,
      devices: devices ?? this.devices,
      selectedId: identical(selectedId, _keep)
          ? this.selectedId
          : selectedId as String?,
      connected: connected ?? this.connected,
      connecting: connecting ?? this.connecting,
      services: services ?? this.services,
      pinNotify: identical(pinNotify, _keep)
          ? this.pinNotify
          : pinNotify as BleCharacteristicInfo?,
      pinWrite: identical(pinWrite, _keep)
          ? this.pinWrite
          : pinWrite as BleCharacteristicInfo?,
      writeType: writeType ?? this.writeType,
      mtu: mtu ?? this.mtu,
      chunkSize: chunkSize ?? this.chunkSize,
      txText: txText ?? this.txText,
      lines: lines ?? this.lines,
      rxCount: rxCount ?? this.rxCount,
      txCount: txCount ?? this.txCount,
      wrap: wrap ?? this.wrap,
      autoScroll: autoScroll ?? this.autoScroll,
      compact: compact ?? this.compact,
      toolsVisible: toolsVisible ?? this.toolsVisible,
      tab: tab ?? this.tab,
      quick: quick ?? this.quick,
      rules: rules ?? this.rules,
      batch: batch ?? this.batch,
      selectedBatchId: identical(selectedBatchId, _keep)
          ? this.selectedBatchId
          : selectedBatchId as String?,
      batchRun: identical(batchRun, _keep)
          ? this.batchRun
          : batchRun as BatchProgress?,
      history: history ?? this.history,
      scripts: scripts ?? this.scripts,
      scriptMeta: scriptMeta ?? this.scriptMeta,
      scriptLog: scriptLog ?? this.scriptLog,
      hint: hint ?? this.hint,
      toast: identical(toast, _keep) ? this.toast : toast as BleNotice?,
    );
  }

  BleWorkspace toWorkspace() => BleWorkspace(
    filter: filter,
    writeType: writeType,
    mtu: mtu,
    chunkSize: chunkSize,
    compact: compact,
    toolsVisible: toolsVisible,
    tab: tab,
    txText: txText,
    wrap: wrap,
    autoScroll: autoScroll,
    quick: quick,
    rules: rules,
    batch: batch,
    history: history,
    scripts: scripts,
  );
}
