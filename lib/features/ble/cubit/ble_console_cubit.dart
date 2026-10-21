import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/utils/debounce.dart';
import '../../serial/data/lua_script_engine.dart';
import '../../serial/data/serial_bytes.dart';
import '../../serial/data/serial_stamp.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../model/ble_models.dart';
import '../repository/ble_console_repository.dart';
import 'ble_console_state.dart';

class BleConsoleCubit extends Cubit<BleConsoleState> {
  BleConsoleCubit({
    required BleConsoleRepository repository,
    LuaScriptEngine? scriptEngine,
    Duration scanDuration = const Duration(seconds: 4),
  }) : _repo = repository,
       _engine = scriptEngine ?? LuaScriptEngine(),
       _scanDuration = scanDuration,
       super(BleConsoleState.initial());

  final BleConsoleRepository _repo;
  final LuaScriptEngine _engine;
  final Duration _scanDuration;
  final Debouncer _persistDebounce = Debouncer(
    duration: const Duration(milliseconds: 400),
  );
  final Map<String, BleDeviceInfo> _found = {};
  final Map<String, String> _brokenLogged = {};
  final List<Timer> _replies = [];
  StreamSubscription<BleDeviceInfo>? _scanSub;
  StreamSubscription<BleNotifyEvent>? _notifySub;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<String>? _errSub;
  Timer? _batchTimer;
  int _seq = 0;
  int _notice = 0;
  int _batchToken = 0;
  var _closing = false;

  Future<void> start() async {
    final saved = _repo.load();
    if (saved != null) emit(_apply(saved));
    _inspectScripts();
    _scanSub ??= _repo.scans.listen(_onScan);
    _notifySub ??= _repo.notifications.listen(_onNotify);
    _connSub ??= _repo.connections.listen(_onConnection);
    _errSub ??= _repo.errors.listen(_onRemoteError);
    final ready = await _repo.adapterReady();
    if (isClosed) return;
    emit(state.copyWith(adapterReady: ready));
    if (!ready) {
      _notify(BleNoticeKind.adapterOff, toast: true, warn: true);
    }
  }

  @override
  Future<void> close() async {
    _persistDebounce.dispose();
    _engine.dispose();
    _stopBatch(notify: false);
    _cancelReplies();
    await _scanSub?.cancel();
    await _notifySub?.cancel();
    await _connSub?.cancel();
    await _errSub?.cancel();
    try {
      await _repo.save(state.toWorkspace());
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '保存 BLE 工作区失败',
        category: LogCategory.database,
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _repo.close();
    return super.close();
  }

  void setFilter(String value) {
    emit(state.copyWith(filter: value));
    _persist();
  }

  void selectDevice(String id) {
    emit(state.copyWith(selectedId: id));
  }

  void setWriteType(BleWriteType type) {
    emit(state.copyWith(writeType: type));
    _persist();
  }

  void setMtu(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value <= 0) {
      _notify(BleNoticeKind.mtuInvalid, toast: true, warn: true);
      return;
    }
    emit(state.copyWith(mtu: value));
    _persist();
  }

  void setChunkSize(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value <= 0) {
      _notify(BleNoticeKind.chunkInvalid, toast: true, warn: true);
      return;
    }
    emit(state.copyWith(chunkSize: value));
    _persist();
  }

  void setTxText(String value) {
    emit(state.copyWith(txText: value));
    _persist();
  }

  void setCompact(bool on) {
    emit(state.copyWith(compact: on));
    _persist();
  }

  void setToolsVisible(bool on) {
    emit(state.copyWith(toolsVisible: on));
    _persist();
  }

  void setTab(ToolTab tab) {
    emit(state.copyWith(tab: bleToolTab(tab), toolsVisible: true));
    _persist();
  }

  void toggleService(String uuid) {
    emit(
      state.copyWith(
        services: [
          for (final service in state.services)
            if (service.uuid == uuid)
              service.copyWith(expanded: !service.expanded)
            else
              service,
        ],
      ),
    );
  }

  Future<void> scan() async {
    if (state.scanning) return;
    if (!state.adapterReady) {
      _notify(BleNoticeKind.adapterOff, toast: true, warn: true);
      return;
    }
    _found.clear();
    emit(
      state.copyWith(scanning: true, scanned: true, devices: const []),
    );
    try {
      await _repo.startScan();
      if (_scanDuration > Duration.zero) {
        await Future<void>.delayed(_scanDuration);
      }
      await _repo.stopScan();
    } on AppException catch (error, stackTrace) {
      _logIo('BLE 扫描失败', error, stackTrace);
      if (isClosed) return;
      emit(state.copyWith(scanning: false));
      _notify(
        BleNoticeKind.scanFailed,
        toast: true,
        warn: true,
        args: {'detail': error.message},
      );
      return;
    }
    if (isClosed) return;
    final devices = [..._found.values];
    final selected = devices.any((item) => item.id == state.selectedId)
        ? state.selectedId
        : (devices.length == 1 ? devices.first.id : state.selectedId);
    emit(
      state.copyWith(
        scanning: false,
        devices: devices,
        selectedId: selected,
      ),
    );
    if (state.visibleDevices.isEmpty) {
      _notify(BleNoticeKind.scanEmpty, toast: true);
    } else {
      _notify(
        BleNoticeKind.scanDone,
        toast: true,
        args: {'count': state.visibleDevices.length},
      );
    }
  }

  Future<void> toggleConnect() async {
    if (state.connecting) return;
    if (state.connected) {
      await _disconnect();
      return;
    }
    final device = state.selected;
    if (device == null) {
      _notify(BleNoticeKind.noDevice, toast: true, warn: true);
      return;
    }
    emit(state.copyWith(connecting: true));
    try {
      await _repo.stopScan();
      final mtu = await _repo.connect(device.id, mtu: state.mtu);
      final services = await _repo.discover();
      if (isClosed) return;
      emit(
        state.copyWith(
          connecting: false,
          connected: true,
          scanning: false,
          mtu: mtu,
          services: services,
        ),
      );
      _sys('${device.label} CONNECTED, MTU $mtu · 在左栏钉住 Notify 和 Write');
      _notify(
        BleNoticeKind.connected,
        toast: true,
        args: {'name': device.label, 'mtu': mtu},
      );
    } on AppException catch (error, stackTrace) {
      _logIo('BLE 连接失败', error, stackTrace);
      if (isClosed) return;
      emit(state.copyWith(connecting: false, connected: false));
      _notify(
        BleNoticeKind.connectFailed,
        toast: true,
        warn: true,
        args: {'detail': error.message},
      );
    } catch (error, stackTrace) {
      _logIo('BLE 连接失败', error, stackTrace);
      if (isClosed) return;
      emit(state.copyWith(connecting: false, connected: false));
      _notify(
        BleNoticeKind.connectFailed,
        toast: true,
        warn: true,
        args: {'detail': '$error'},
      );
    }
  }

  Future<void> pinNotify(BleCharacteristicInfo characteristic) async {
    if (!state.connected) return;
    final current = state.pinNotify;
    if (current != null && _sameUuid(current.uuid, characteristic.uuid)) {
      await _repo.setNotify(
        serviceUuid: current.serviceUuid,
        characteristicUuid: current.uuid,
        enable: false,
      );
      emit(state.copyWith(pinNotify: null));
      _sys('取消 Notify 钉选');
      _notify(BleNoticeKind.unpinNotify, toast: true);
      return;
    }
    if (current != null) {
      await _repo.setNotify(
        serviceUuid: current.serviceUuid,
        characteristicUuid: current.uuid,
        enable: false,
      );
    }
    await _repo.setNotify(
      serviceUuid: characteristic.serviceUuid,
      characteristicUuid: characteristic.uuid,
      enable: true,
    );
    emit(state.copyWith(pinNotify: characteristic));
    _sys('钉住 Notify ${characteristic.uuid}');
    _notify(
      BleNoticeKind.pinNotify,
      toast: true,
      args: {'uuid': characteristic.uuid},
    );
  }

  Future<void> pinWrite(BleCharacteristicInfo characteristic) async {
    if (!state.connected) return;
    final current = state.pinWrite;
    if (current != null && _sameUuid(current.uuid, characteristic.uuid)) {
      emit(state.copyWith(pinWrite: null));
      _sys('取消 Write 钉选');
      _notify(BleNoticeKind.unpinWrite, toast: true);
      return;
    }
    emit(state.copyWith(pinWrite: characteristic));
    _sys('钉住 Write ${characteristic.uuid} · ${_writeLabel()}');
    _notify(
      BleNoticeKind.pinWrite,
      toast: true,
      args: {'uuid': characteristic.uuid, 'type': _writeLabel()},
    );
  }

  Future<void> sendFromEditor() async {
    await _transmit(state.txText, recordHistory: true);
  }

  Future<void> sendQuick(String id) async {
    for (final item in state.quick) {
      if (item.id == id) {
        await _transmit(item.data, format: item.format);
        return;
      }
    }
  }

  void sendQuickByKey(String key) {
    for (final item in state.quick) {
      if (item.key == key) {
        unawaited(sendQuick(item.id));
        return;
      }
    }
  }

  void saveQuick(QuickCommand command) {
    final exists = state.quick.any((item) => item.id == command.id);
    emit(
      state.copyWith(
        quick: [
          for (final item in state.quick)
            if (item.id == command.id) command else item,
          if (!exists) command,
        ],
      ),
    );
    _persist();
    _notify(BleNoticeKind.quickSaved, toast: true);
  }

  void deleteQuick(String id) {
    emit(
      state.copyWith(quick: [for (final item in state.quick) if (item.id != id) item]),
    );
    _persist();
    _notify(BleNoticeKind.deleted, toast: true);
  }

  void saveRule(ReplyRule rule) {
    final exists = state.rules.any((item) => item.id == rule.id);
    emit(
      state.copyWith(
        rules: [
          for (final item in state.rules)
            if (item.id == rule.id) rule else item,
          if (!exists) rule,
        ],
      ),
    );
    _persist();
    _notify(BleNoticeKind.ruleSaved, toast: true);
  }

  void toggleRule(String id) {
    ReplyRule? hit;
    emit(
      state.copyWith(
        rules: [
          for (final item in state.rules)
            if (item.id == id)
              (hit = item.copyWith(enabled: !item.enabled))
            else
              item,
        ],
      ),
    );
    _persist();
    if (hit == null) return;
    _notify(
      hit.enabled ? BleNoticeKind.ruleOn : BleNoticeKind.ruleOff,
      toast: true,
      args: {'name': hit.name},
    );
  }

  void deleteRule(String id) {
    emit(
      state.copyWith(rules: [for (final item in state.rules) if (item.id != id) item]),
    );
    _persist();
    _notify(BleNoticeKind.deleted, toast: true);
  }

  void saveBatch(BatchJob job) {
    final exists = state.batch.any((item) => item.id == job.id);
    emit(
      state.copyWith(
        batch: [
          for (final item in state.batch)
            if (item.id == job.id) job else item,
          if (!exists) job,
        ],
        selectedBatchId: job.id,
      ),
    );
    _persist();
    _notify(BleNoticeKind.batchSaved, toast: true);
  }

  void deleteBatch(String id) {
    emit(
      state.copyWith(
        batch: [for (final item in state.batch) if (item.id != id) item],
        selectedBatchId: state.selectedBatchId == id ? null : state.selectedBatchId,
      ),
    );
    _persist();
    _notify(BleNoticeKind.deleted, toast: true);
  }

  void runBatch(String id) {
    BatchJob? job;
    for (final item in state.batch) {
      if (item.id == id) job = item;
    }
    if (job == null || job.steps.isEmpty) return;
    _stopBatch(notify: false);
    _batchToken++;
    final token = _batchToken;
    unawaited(_runBatch(job, token));
  }

  void stopBatch() => _stopBatch(notify: true);

  void resendHistory(String text) {
    unawaited(_transmit(text));
  }

  void saveScript(LuaScript script) {
    final exists = state.scripts.any((item) => item.id == script.id);
    emit(
      state.copyWith(
        scripts: [
          for (final item in state.scripts)
            if (item.id == script.id) script else item,
          if (!exists) script,
        ],
      ),
    );
    _inspectScripts();
    _persist();
    _notify(BleNoticeKind.scriptSaved, toast: true);
  }

  void toggleScript(String id) {
    LuaScript? hit;
    emit(
      state.copyWith(
        scripts: [
          for (final item in state.scripts)
            if (item.id == id)
              (hit = item.copyWith(enabled: !item.enabled))
            else
              item,
        ],
      ),
    );
    _persist();
    if (hit == null) return;
    _notify(
      hit.enabled ? BleNoticeKind.ruleOn : BleNoticeKind.ruleOff,
      toast: true,
      args: {'name': hit.name},
    );
  }

  void deleteScript(String id) {
    emit(
      state.copyWith(
        scripts: [for (final item in state.scripts) if (item.id != id) item],
      ),
    );
    _inspectScripts();
    _persist();
    _notify(BleNoticeKind.deleted, toast: true);
  }

  void runScript(String id) {
    LuaScript? script;
    for (final item in state.scripts) {
      if (item.id == id) script = item;
    }
    if (script == null) return;
    final lastRx = _lastRxBytes();
    if (lastRx == null) return;
    final out = _engine.receive(script.id, script.code, lastRx);
    final entries = _outcomeEntries(script, out);
    if (entries.isNotEmpty) _scriptLogs(script, entries);
  }

  Future<void> clearLog() async {
    emit(state.copyWith(lines: const [], rxCount: 0, txCount: 0));
    _notify(BleNoticeKind.recvCleared, toast: true);
  }

  Future<void> saveLog() async {
    final path = await _repo.pickSave(
      suggestedName: 'ble_${fileStamp(DateTime.now())}.txt',
      extension: 'txt',
    );
    if (path == null) return;
    final buffer = StringBuffer();
    for (final line in state.lines) {
      if (line.dir == LogDir.sys) {
        buffer.writeln('[${fullStamp(line.time)}]# ${line.text}');
      } else {
        final tag = line.dir == LogDir.rx ? 'RECV' : 'SEND';
        buffer.writeln('[${fullStamp(line.time)}]# $tag HEX>');
        buffer.writeln(SerialBytes.toHex(line.bytes ?? const []));
      }
    }
    await _repo.writeText(path: path, text: buffer.toString());
    _notify(BleNoticeKind.logSaved, toast: true);
  }

  Future<void> _transmit(
    String text, {
    DataFormat format = DataFormat.hex,
    bool recordHistory = false,
  }) async {
    if (!state.connected) {
      _notify(BleNoticeKind.closedSend, toast: true, warn: true);
      return;
    }
    final pin = state.pinWrite;
    if (pin == null) {
      _notify(BleNoticeKind.noWrite, toast: true, warn: true);
      return;
    }
    final encoded = SerialBytes.encode(
      text: text,
      format: format,
      escape: false,
      atCrlf: false,
      crlf: false,
      checksum: ChecksumKind.none,
    );
    if (encoded.error == EncodeError.badHex) {
      _notify(BleNoticeKind.badHex, toast: true, warn: true);
      return;
    }
    final raw = encoded.bytes;
    if (encoded.error == EncodeError.empty || raw == null || raw.isEmpty) {
      _notify(BleNoticeKind.emptySend, toast: true, warn: true);
      return;
    }
    final hooked = _sendHooks(raw);
    final bytes = hooked.bytes;
    if (bytes == null) return;
    try {
      await _writeChunked(pin, bytes);
    } on AppException catch (error, stackTrace) {
      _logIo('BLE 发送失败', error, stackTrace);
      return;
    }
    if (recordHistory) _remember(text);
    _push(dir: LogDir.tx, bytes: bytes);
    if (state.pinNotify == null) {
      _notify(BleNoticeKind.sentNoNotify, toast: true);
    }
  }

  Future<void> _writeChunked(
    BleCharacteristicInfo pin,
    Uint8List bytes,
  ) async {
    final size = math.max(1, state.chunkSize);
    final withResponse = state.writeType == BleWriteType.withResponse;
    for (var i = 0; i < bytes.length; i += size) {
      final end = math.min(i + size, bytes.length);
      await _repo.write(
        serviceUuid: pin.serviceUuid,
        characteristicUuid: pin.uuid,
        data: Uint8List.fromList(bytes.sublist(i, end)),
        withResponse: withResponse,
      );
      if (end < bytes.length) {
        await Future<void>.delayed(const Duration(milliseconds: 12));
      }
    }
  }

  Future<void> _runBatch(BatchJob job, int token) async {
    final total = job.steps.length * job.repeat;
    var step = 0;
    for (var round = 1; round <= job.repeat; round++) {
      for (final item in job.steps) {
        if (isClosed || token != _batchToken) return;
        step++;
        emit(
          state.copyWith(
            batchRun: BatchProgress(
              jobId: job.id,
              step: step,
              total: total,
              round: round,
              rounds: job.repeat,
            ),
          ),
        );
        _notify(
          BleNoticeKind.batchRunning,
          hint: true,
          args: {'step': step, 'total': total},
        );
        if (item.delayMs > 0) {
          await Future<void>.delayed(Duration(milliseconds: item.delayMs));
        }
        if (isClosed || token != _batchToken) return;
        await _transmit(item.data);
      }
    }
    if (isClosed || token != _batchToken) return;
    emit(state.copyWith(batchRun: null));
    _notify(BleNoticeKind.batchEnded, toast: true);
  }

  void _stopBatch({required bool notify}) {
    _batchToken++;
    _batchTimer?.cancel();
    _batchTimer = null;
    if (state.batchRun != null) {
      emit(state.copyWith(batchRun: null));
    }
    if (notify) _notify(BleNoticeKind.batchEnded, toast: true);
  }

  void _onScan(BleDeviceInfo device) {
    _found[device.id] = device;
    if (!state.scanning) return;
    emit(state.copyWith(devices: [..._found.values]));
  }

  void _onNotify(BleNotifyEvent event) {
    final pin = state.pinNotify;
    if (!state.connected || pin == null) return;
    if (!_sameUuid(pin.uuid, event.characteristicUuid)) return;
    _push(dir: LogDir.rx, bytes: event.value);
    _receiveHooks(event.value);
    _matchRules(event.value);
  }

  void _onConnection(bool connected) {
    if (connected || !state.connected) return;
    unawaited(_resetLink(notify: true));
  }

  void _onRemoteError(String detail) {
    _notify(
      BleNoticeKind.connectFailed,
      toast: true,
      warn: true,
      args: {'detail': detail},
    );
  }

  Future<void> _disconnect() async {
    await _repo.disconnect();
    await _resetLink(notify: true);
  }

  Future<void> _resetLink({required bool notify}) async {
    if (_closing) return;
    _closing = true;
    try {
      _stopBatch(notify: false);
      _cancelReplies();
      final pin = state.pinNotify;
      if (pin != null) {
        try {
          await _repo.setNotify(
            serviceUuid: pin.serviceUuid,
            characteristicUuid: pin.uuid,
            enable: false,
          );
        } catch (_) {}
      }
      if (isClosed) return;
      emit(
        state.copyWith(
          connected: false,
          connecting: false,
          services: const [],
          pinNotify: null,
          pinWrite: null,
        ),
      );
      _sys('已断开');
      if (notify) _notify(BleNoticeKind.disconnected);
    } finally {
      _closing = false;
    }
  }

  void _push({required LogDir dir, Uint8List? bytes, String text = ''}) {
    final lines = [...state.lines];
    lines.add(
      BleLogLine(
        no: ++_seq,
        time: DateTime.now(),
        dir: dir,
        bytes: bytes,
        text: text,
      ),
    );
    if (lines.length > SerialMetrics.logLimit) {
      lines.removeRange(0, lines.length - SerialMetrics.logLimit);
    }
    var rx = state.rxCount;
    var tx = state.txCount;
    if (dir == LogDir.rx) rx += bytes?.length ?? 0;
    if (dir == LogDir.tx) tx += bytes?.length ?? 0;
    emit(state.copyWith(lines: lines, rxCount: rx, txCount: tx));
  }

  void _sys(String text) => _push(dir: LogDir.sys, text: text);

  void _remember(String text) {
    final history = [
      HistoryEntry(text: text, time: DateTime.now()),
      ...state.history.where((item) => item.text != text),
    ];
    if (history.length > SerialMetrics.historyLimit) {
      history.removeRange(SerialMetrics.historyLimit, history.length);
    }
    emit(state.copyWith(history: history));
    _persist();
  }

  void _receiveHooks(Uint8List bytes) {
    for (final script in state.scripts) {
      if (!script.enabled || !_compiles(script)) continue;
      final out = _engine.receive(script.id, script.code, bytes);
      final entries = _outcomeEntries(script, out);
      if (entries.isNotEmpty) _scriptLogs(script, entries);
    }
  }

  ({Uint8List? bytes, String by, bool failed}) _sendHooks(Uint8List bytes) {
    var current = bytes;
    for (final script in state.scripts) {
      if (!script.enabled || !_compiles(script)) continue;
      final out = _engine.beforeSend(script.id, script.code, current);
      final entries = _outcomeEntries(script, out);
      if (out.error != null) {
        _scriptLogs(script, entries);
        return (bytes: null, by: script.name, failed: true);
      }
      final next = out.bytes;
      if (next == null || next.isEmpty) {
        _scriptLogs(script, entries);
        return (bytes: null, by: script.name, failed: false);
      }
      if (entries.isNotEmpty) _scriptLogs(script, entries);
      current = next;
    }
    return (bytes: current, by: '', failed: false);
  }

  bool _compiles(LuaScript script) {
    final error = _engine.inspect(script.id, script.code).error;
    if (error == null) return true;
    if (_brokenLogged[script.id] != script.code) {
      _brokenLogged[script.id] = script.code;
      _scriptLogs(script, [
        ScriptLogEntry(
          time: DateTime.now(),
          name: script.name,
          kind: ScriptLogKind.error,
          text: error,
        ),
      ]);
    }
    return false;
  }

  void _inspectScripts() {
    _engine.retain(state.scripts.map((s) => s.id));
    emit(
      state.copyWith(
        scriptMeta: {
          for (final script in state.scripts)
            script.id: ScriptMeta(
              hooks: _engine.inspect(script.id, script.code).hooks,
              error: _engine.inspect(script.id, script.code).error,
            ),
        },
      ),
    );
  }

  List<ScriptLogEntry> _outcomeEntries(LuaScript script, ScriptOutcome out) {
    return [
      for (final text in out.logs)
        ScriptLogEntry(
          time: DateTime.now(),
          name: script.name,
          kind: ScriptLogKind.output,
          text: text,
        ),
      if (out.error != null)
        ScriptLogEntry(
          time: DateTime.now(),
          name: script.name,
          kind: ScriptLogKind.error,
          text: out.error!,
        ),
    ];
  }

  void _scriptLogs(LuaScript script, List<ScriptLogEntry> entries) {
    if (entries.isEmpty) return;
    final log = [...state.scriptLog, ...entries];
    if (log.length > SerialMetrics.scriptLogLimit) {
      log.removeRange(0, log.length - SerialMetrics.scriptLogLimit);
    }
    emit(state.copyWith(scriptLog: log));
  }

  void _matchRules(Uint8List bytes) {
    if (state.pinWrite == null) return;
    final matched = <(ReplyRule, List<Uint8List?>)>[];
    final next = <ReplyRule>[];
    for (final rule in state.rules) {
      final captures = rule.enabled
          ? SerialBytes.ruleCaptures(rule, bytes)
          : null;
      if (captures == null) {
        next.add(rule);
        continue;
      }
      final hit = rule.copyWith(hits: rule.hits + 1);
      next.add(hit);
      matched.add((hit, captures));
    }
    if (matched.isEmpty) return;
    emit(state.copyWith(rules: next));
    _persist();
    for (final (rule, captures) in matched) {
      _scheduleReplies(rule, captures);
    }
  }

  void _scheduleReplies(ReplyRule rule, List<Uint8List?> captures) {
    var wait = 0;
    for (final reply in rule.replies) {
      wait += reply.delayMs < 0 ? 0 : reply.delayMs;
      late final Timer timer;
      timer = Timer(Duration(milliseconds: wait), () {
        _replies.remove(timer);
        if (!state.connected || isClosed) return;
        final data = SerialBytes.expandReply(reply.data, captures);
        if (data == null) return;
        unawaited(_transmit(data, format: DataFormat.hex));
      });
      _replies.add(timer);
    }
  }

  void _cancelReplies() {
    for (final timer in _replies) {
      timer.cancel();
    }
    _replies.clear();
  }

  Uint8List? _lastRxBytes() {
    for (var i = state.lines.length - 1; i >= 0; i--) {
      final line = state.lines[i];
      if (line.dir == LogDir.rx) return line.bytes;
    }
    return null;
  }

  BleConsoleState _apply(BleWorkspace ws) {
    return state.copyWith(
      filter: ws.filter,
      writeType: ws.writeType,
      mtu: ws.mtu,
      chunkSize: ws.chunkSize,
      compact: ws.compact,
      toolsVisible: ws.toolsVisible,
      tab: ws.tab,
      txText: ws.txText,
      wrap: ws.wrap,
      autoScroll: ws.autoScroll,
      quick: ws.quick,
      rules: ws.rules,
      batch: ws.batch,
      selectedBatchId: ws.batch.isEmpty ? null : ws.batch.first.id,
      history: ws.history,
      scripts: ws.scripts,
    );
  }

  void _persist() {
    _persistDebounce.run(() {
      unawaited(_repo.save(state.toWorkspace()));
    });
  }

  void _notify(
    BleNoticeKind kind, {
    bool toast = false,
    bool warn = false,
    bool hint = true,
    Map<String, Object> args = const {},
  }) {
    final notice = BleNotice(
      id: ++_notice,
      kind: kind,
      warn: warn,
      args: args,
    );
    if (toast && hint) {
      emit(state.copyWith(hint: notice, toast: notice));
    } else if (toast) {
      emit(state.copyWith(toast: notice));
    } else if (hint) {
      emit(state.copyWith(hint: notice));
    }
  }

  String _writeLabel() => state.writeType == BleWriteType.withResponse
      ? 'With Response'
      : 'Without Response';

  void _logIo(String message, Object error, StackTrace stackTrace) {
    AppLogger.i.error(
      message,
      category: LogCategory.device,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

bool _sameUuid(String a, String b) {
  String norm(String value) => value.replaceAll('-', '').toUpperCase();
  final left = norm(a);
  final right = norm(b);
  if (left == right) return true;
  if (left.length == 4 && right.endsWith('00001000800000805F9B34FB')) {
    return right.substring(4, 8) == left;
  }
  if (right.length == 4 && left.endsWith('00001000800000805F9B34FB')) {
    return left.substring(4, 8) == right;
  }
  return false;
}
