import 'dart:typed_data';

import '../model/serial_models.dart';

const _keep = Object();

class SerialConsoleState {
  const SerialConsoleState({
    required this.ports,
    required this.portName,
    required this.baud,
    required this.parity,
    required this.dataBits,
    required this.stopBits,
    required this.flow,
    required this.dtr,
    required this.rts,
    required this.open,
    required this.pins,
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
    required this.hint,
    required this.toast,
  });

  factory SerialConsoleState.initial() {
    final ws = SerialWorkspace.defaults();
    return SerialConsoleState(
      ports: const [],
      portName: ws.portName,
      baud: ws.baud,
      parity: ws.parity,
      dataBits: ws.dataBits,
      stopBits: ws.stopBits,
      flow: ws.flow,
      dtr: ws.dtr,
      rts: ws.rts,
      open: false,
      pins: const PinLevels(),
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
      hint: const SerialNotice(id: 0, kind: SerialNoticeKind.ready),
      toast: null,
    );
  }

  final List<SerialPortInfo> ports;
  final String? portName;
  final int baud;
  final Parity parity;
  final int dataBits;
  final StopBits stopBits;
  final FlowControl flow;
  final bool dtr;
  final bool rts;
  final bool open;
  final PinLevels pins;
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
  final List<LogLine> lines;
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
  final SerialNotice hint;
  final SerialNotice? toast;

  /// 状态栏固定英文标记：`COM3 OPENED, 115200, N, 8, 1, NONE`。
  String get connectionLabel {
    final mark = open ? 'OPENED' : 'CLOSED';
    return '${portName ?? '-'} $mark, $baud, ${parity.token}, $dataBits, ${stopBits.label}, ${flow.label}';
  }

  SerialLinkConfig? get link {
    final name = portName;
    if (name == null || name.isEmpty) return null;
    return SerialLinkConfig(
      portName: name,
      baud: baud,
      parity: parity,
      dataBits: dataBits,
      stopBits: stopBits,
      flow: flow,
      dtr: dtr,
      rts: rts,
    );
  }

  SerialWorkspace toWorkspace() => SerialWorkspace(
    portName: portName,
    baud: baud,
    parity: parity,
    dataBits: dataBits,
    stopBits: stopBits,
    flow: flow,
    dtr: dtr,
    rts: rts,
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
  );

  SerialConsoleState copyWith({
    List<SerialPortInfo>? ports,
    Object? portName = _keep,
    int? baud,
    Parity? parity,
    int? dataBits,
    StopBits? stopBits,
    FlowControl? flow,
    bool? dtr,
    bool? rts,
    bool? open,
    PinLevels? pins,
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
    List<LogLine>? lines,
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
    SerialNotice? hint,
    Object? toast = _keep,
  }) {
    return SerialConsoleState(
      ports: ports ?? this.ports,
      portName: portName == _keep ? this.portName : portName as String?,
      baud: baud ?? this.baud,
      parity: parity ?? this.parity,
      dataBits: dataBits ?? this.dataBits,
      stopBits: stopBits ?? this.stopBits,
      flow: flow ?? this.flow,
      dtr: dtr ?? this.dtr,
      rts: rts ?? this.rts,
      open: open ?? this.open,
      pins: pins ?? this.pins,
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
      hint: hint ?? this.hint,
      toast: toast == _keep ? this.toast : toast as SerialNotice?,
    );
  }
}
