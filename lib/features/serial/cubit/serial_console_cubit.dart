import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/utils/debounce.dart';
import '../data/lua_script_engine.dart';
import '../data/packet_assembler.dart';
import '../data/serial_bytes.dart';
import '../data/serial_native_text.dart';
import '../data/serial_stamp.dart';
import '../model/config_pack.dart';
import '../model/script_lessons.dart';
import '../model/serial_models.dart';
import '../repository/serial_console_repository.dart';
import '../serial_metrics.dart';
import 'serial_console_state.dart';

class SerialConsoleCubit extends Cubit<SerialConsoleState> {
  SerialConsoleCubit({
    required SerialConsoleRepository repository,
    LuaScriptEngine? scriptEngine,
  }) : _repo = repository,
       _engine = scriptEngine ?? LuaScriptEngine(),
       super(SerialConsoleState.initial());

  final SerialConsoleRepository _repo;
  final LuaScriptEngine _engine;
  final Debouncer _persistDebounce = Debouncer(
    duration: const Duration(milliseconds: 400),
  );
  final Debouncer _scriptDebounce = Debouncer(
    duration: const Duration(milliseconds: 300),
  );
  final PacketAssembler _assembler = PacketAssembler();
  final List<Timer> _replies = [];
  final List<String> _saveBuf = [];

  /// 自动运行时已记录过编译错误的脚本 id → 代码，同一版代码只记一次。
  final Map<String, String> _brokenLogged = {};
  Uint8List? _lastRx;

  StreamSubscription<Uint8List>? _rxSub;
  Timer? _loop;
  Timer? _batchTimer;
  Timer? _pins;
  int _seq = 0;
  int _notice = 0;
  int _batchToken = 0;
  var _closing = false;

  Future<void> start() async {
    final saved = _repo.load();
    if (saved != null) {
      _emit(_applyWorkspace(saved));
    }
    _inspectScripts();
    _rxSub ??= _repo.incoming.listen(_onChunk, onError: _onPortError);
    try {
      await refreshPorts(announce: false);
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '初始化串口列表失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> close() async {
    _persistDebounce.dispose();
    _scriptDebounce.dispose();
    _engine.dispose();
    _stopLoop(notify: false);
    _stopBatch(notify: false);
    _cancelReplies();
    _pins?.cancel();
    _assembler.dispose();
    await _rxSub?.cancel();
    _rxSub = null;
    await _repo.close();
    try {
      await _repo.save(state.toWorkspace());
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '保存串口工作区失败',
        category: LogCategory.database,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return super.close();
  }

  Future<void> refreshPorts({bool announce = true}) async {
    try {
      final found = await _repo.listPorts();
      final ports = [...found];
      final selected = state.portName;
      if (selected != null && ports.every((port) => port.name != selected)) {
        ports.insert(0, SerialPortInfo(name: selected, label: selected));
      }
      final portName = selected ?? (ports.isEmpty ? null : ports.first.name);
      _emit(state.copyWith(ports: ports, portName: portName));
      _persist();
      if (announce) {
        _notify(
          SerialNoticeKind.scanDone,
          toast: true,
          hint: false,
          args: {'count': found.length},
        );
      }
    } on AppException catch (error, stackTrace) {
      AppLogger.i.error(
        '扫描串口失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      if (announce) {
        _notify(
          SerialNoticeKind.openFailed,
          toast: true,
          warn: true,
          hint: false,
          args: {'detail': error.message},
        );
      }
    }
  }

  void setPort(String name) {
    if (state.open && name != state.portName) {
      _notify(SerialNoticeKind.portBusy, toast: true, warn: true, hint: false);
      return;
    }
    _emit(state.copyWith(portName: name));
    _persist();
  }

  Future<void> setBaud(int baud) {
    if (baud <= 0) {
      _notify(
        SerialNoticeKind.baudInvalid,
        toast: true,
        warn: true,
        hint: false,
      );
      return Future.value();
    }
    return _commit(state.copyWith(baud: baud), announce: true);
  }

  Future<void> setParity(Parity parity) =>
      _commit(state.copyWith(parity: parity), announce: true);

  Future<void> setDataBits(int bits) {
    if (bits < 5 || bits > 8) return Future.value();
    return _commit(state.copyWith(dataBits: bits), announce: true);
  }

  Future<void> setStopBits(StopBits stopBits) =>
      _commit(state.copyWith(stopBits: stopBits), announce: true);

  Future<void> setFlow(FlowControl flow) =>
      _commit(state.copyWith(flow: flow), announce: true);

  Future<void> setDtr(bool on) => _commit(state.copyWith(dtr: on));

  Future<void> setRts(bool on) => _commit(state.copyWith(rts: on));

  Future<void> toggleOpen() async {
    if (state.open) {
      await _shutdown();
      return;
    }
    final link = state.link;
    if (link == null) {
      _notify(SerialNoticeKind.noPort, toast: true, warn: true);
      return;
    }
    try {
      final result = await _repo.open(link);
      _emit(state.copyWith(open: true));
      _sys(SysLogKind.opened, {
        'port': link.portName,
        'baud': link.baud,
        'frame': frameLabel(
          dataBits: link.dataBits,
          parity: link.parity,
          stopBits: link.stopBits,
        ),
      });
      if (result == SerialOpenResult.partial) {
        _notify(SerialNoticeKind.configPartial, toast: true, warn: true);
      } else {
        _notify(SerialNoticeKind.portOpened);
      }
      _startPins();
    } on DeviceConfigException catch (error, stackTrace) {
      AppLogger.i.error(
        '串口已打开但参数未能生效',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      _notify(
        SerialNoticeKind.configFailed,
        toast: true,
        warn: true,
        args: {'detail': error.message},
      );
    } on AppException catch (error, stackTrace) {
      AppLogger.i.error(
        '打开串口失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      _notify(
        SerialNoticeKind.openFailed,
        toast: true,
        warn: true,
        args: {'detail': error.message},
      );
    }
  }

  void setRxFormat(DataFormat format) {
    _emit(state.copyWith(rxFormat: format));
    _persist();
  }

  void setLogMode(bool on) {
    _emit(state.copyWith(logMode: on));
    _persist();
  }

  void setWrap(bool on) {
    _emit(state.copyWith(wrap: on));
    _persist();
  }

  void setHideRx(bool on) {
    _emit(state.copyWith(hideRx: on));
    _persist();
  }

  void setAutoScroll(bool on) {
    _emit(state.copyWith(autoScroll: on));
    _persist();
  }

  void setPacketTimeout(int ms) {
    if (ms < 0) {
      _notify(
        SerialNoticeKind.timeoutInvalid,
        toast: true,
        warn: true,
        hint: false,
      );
      return;
    }
    _emit(state.copyWith(packetTimeoutMs: ms));
    _persist();
    _notify(
      ms < SerialMetrics.splitHintMs
          ? SerialNoticeKind.timeoutSplitHint
          : SerialNoticeKind.timeoutHint,
      args: {'ms': ms},
    );
  }

  Future<void> setSaveRx(bool on) async {
    if (on) {
      _saveBuf.clear();
      final name =
          'recv-${state.portName ?? 'port'}-${fileStamp(DateTime.now())}.log';
      _emit(state.copyWith(saveActive: true, saveName: name, savedCount: 0));
      _notify(SerialNoticeKind.saveStarted, toast: true);
      return;
    }
    if (!state.saveActive) return;
    try {
      final path = await _repo.pickSave(
        suggestedName: state.saveName,
        extension: 'log',
      );
      if (path == null) return;
      await _repo.writeText(path: path, text: _saveBuf.join('\r\n'));
      final count = _saveBuf.length;
      final name = state.saveName;
      _saveBuf.clear();
      _emit(state.copyWith(saveActive: false, savedCount: 0));
      _notify(
        SerialNoticeKind.saveWritten,
        toast: true,
        args: {'name': name, 'count': count},
      );
    } on AppException catch (error, stackTrace) {
      _logIo('写出接收文件失败', error, stackTrace);
    }
  }

  void setTxFormat(DataFormat format) {
    if (format == state.txFormat) return;
    final text = state.fileBytes == null
        ? SerialBytes.convertText(
            text: state.txText,
            from: state.txFormat,
            to: format,
            escape: state.escape,
          )
        : state.txText;
    _emit(state.copyWith(txFormat: format, txText: text));
    _persist();
  }

  void setEscape(bool on) {
    _emit(state.copyWith(escape: on));
    _persist();
  }

  void setAtCrlf(bool on) {
    _emit(state.copyWith(atCrlf: on));
    _persist();
  }

  void setCrlf(bool on) {
    _emit(state.copyWith(crlf: on));
    _persist();
  }

  void setChecksum(ChecksumKind kind) {
    _emit(state.copyWith(checksum: kind));
    _persist();
  }

  void setClearAfterSend(bool on) {
    _emit(state.copyWith(clearAfterSend: on));
    _persist();
  }

  Future<void> setFileSource(bool on) async {
    if (!on) {
      _emit(state.copyWith(fileName: null, fileBytes: null));
      return;
    }
    try {
      final picked = await _repo.pickAny();
      if (picked == null) return;
      final head = picked.bytes.length > SerialMetrics.filePreviewBytes
          ? picked.bytes.sublist(0, SerialMetrics.filePreviewBytes)
          : picked.bytes;
      final suffix = picked.bytes.length > SerialMetrics.filePreviewBytes
          ? ' …'
          : '';
      _emit(
        state.copyWith(
          fileName: picked.name,
          fileBytes: picked.bytes,
          txText: '${SerialBytes.toHex(head)}$suffix',
        ),
      );
      _notify(
        SerialNoticeKind.fileLoaded,
        toast: true,
        hint: false,
        args: {'name': picked.name},
      );
    } on AppException catch (error, stackTrace) {
      _logIo('读取发送文件失败', error, stackTrace);
    }
  }

  void setLoopEnabled(bool on) {
    _emit(state.copyWith(loopEnabled: on));
    _persist();
  }

  void setLoopPeriod(int ms) {
    if (ms < SerialMetrics.minLoopMs) {
      _notify(
        SerialNoticeKind.periodInvalid,
        toast: true,
        warn: true,
        hint: false,
      );
      return;
    }
    _emit(state.copyWith(loopPeriodMs: ms));
    _persist();
  }

  void setTxText(String text) {
    _emit(state.copyWith(txText: text));
    _persist();
  }

  Future<void> sendFromEditor() async {
    if (state.looping) {
      stopLoop();
      return;
    }
    final file = state.fileBytes;
    final text = file != null ? SerialBytes.toHex(file) : state.txText;
    final format = file != null ? DataFormat.hex : state.txFormat;
    if (state.loopEnabled) {
      await _startLoop(text, format);
      return;
    }
    final ok = await _transmit(text, format: format, recordHistory: true);
    if (ok && state.clearAfterSend && state.fileBytes == null) {
      _emit(state.copyWith(txText: ''));
      _persist();
    }
  }

  void stopLoop() => _stopLoop(notify: true);

  void clearTx() {
    _emit(state.copyWith(txText: '', fileName: null, fileBytes: null));
    _persist();
  }

  void clearLog() {
    _emit(state.copyWith(lines: const []));
    _notify(SerialNoticeKind.recvCleared);
  }

  Future<void> saveLog() async {
    final path = await _repo.pickSave(
      suggestedName:
          'serial-${state.portName ?? 'port'}-${DateTime.now().millisecondsSinceEpoch}.log',
      extension: 'log',
    );
    if (path == null) return;
    try {
      await _repo.writeText(path: path, text: _logDump());
      _notify(SerialNoticeKind.logSaved, toast: true, hint: false);
    } on AppException catch (error, stackTrace) {
      _logIo('保存日志失败', error, stackTrace);
    }
  }

  void resetCounters() {
    _emit(state.copyWith(rxCount: 0, txCount: 0));
  }

  void setCompact(bool on) {
    if (state.compact == on) return;
    _emit(state.copyWith(compact: on));
    _persist();
  }

  void setToolsVisible(bool on) {
    if (state.toolsVisible == on) return;
    _emit(state.copyWith(toolsVisible: on));
    _persist();
  }

  void setTab(ToolTab tab) {
    _emit(state.copyWith(tab: tab, toolsVisible: true));
    _persist();
  }

  Future<void> sendQuick(String id) async {
    final command = state.quick.commandById(id);
    if (command == null) return;
    await _transmit(
      command.data,
      format: command.format,
      checksum: ChecksumKind.none,
      crlf: false,
      recordHistory: false,
    );
  }

  Future<void> sendQuickByKey(String key) async {
    final command = state.quick.commands.where((item) => item.key == key);
    if (command.isEmpty) return;
    await sendQuick(command.first.id);
  }

  /// [folderId] 为 null 或文件夹不存在时放在根目录；所在文件夹不变则原位替换，否则追加到目标末尾。
  void upsertQuick(QuickCommand command, {String? folderId}) {
    final target = state.quick.folders.any((f) => f.id == folderId)
        ? folderId
        : null;
    final stay =
        state.quick.commandById(command.id) != null &&
        state.quick.folderIdOf(command.id) == target;
    QuickCommand clean(QuickCommand item) =>
        command.key.isNotEmpty &&
            item.key == command.key &&
            item.id != command.id
        ? item.copyWith(key: '')
        : item;
    final quick = <QuickNode>[];
    for (final node in state.quick) {
      switch (node) {
        case QuickCommand():
          if (node.id != command.id) {
            quick.add(clean(node));
          } else if (stay) {
            quick.add(command);
          }
        case QuickFolder():
          final commands = <QuickCommand>[
            for (final item in node.commands)
              if (item.id != command.id) clean(item) else if (stay) command,
          ];
          if (!stay && node.id == target) commands.add(command);
          quick.add(node.copyWith(commands: commands));
      }
    }
    if (!stay && target == null) quick.add(command);
    _emit(state.copyWith(quick: quick));
    _persist();
    _notify(SerialNoticeKind.quickSaved, toast: true, hint: false);
  }

  void deleteQuick(String id) {
    final quick = <QuickNode>[
      for (final node in state.quick)
        switch (node) {
          QuickCommand() => node,
          QuickFolder() => node.copyWith(
            commands: node.commands.where((c) => c.id != id).toList(),
          ),
        },
    ]..removeWhere((node) => node is QuickCommand && node.id == id);
    _emit(state.copyWith(quick: quick));
    _persist();
    _notify(SerialNoticeKind.deleted, toast: true, hint: false);
  }

  /// 复制：立即克隆，插到源条目之后（同文件夹内）；克隆不占 F 键。
  void duplicateQuick(String id) {
    final source = state.quick.commandById(id);
    if (source == null) return;
    final copy = QuickCommand(
      id: _freshId('q', {for (final c in state.quick.commands) c.id}),
      name: _copyName(source.name, {
        for (final c in state.quick.commands) c.name,
      }),
      data: source.data,
      format: source.format,
    );
    final quick = <QuickNode>[
      for (final node in state.quick)
        ...switch (node) {
          QuickCommand() => [node, if (node.id == id) copy],
          QuickFolder() => [
            node.copyWith(
              commands: [
                for (final item in node.commands) ...[
                  item,
                  if (item.id == id) copy,
                ],
              ],
            ),
          ],
        },
    ];
    _emit(state.copyWith(quick: quick));
    _persist();
    _notify(SerialNoticeKind.duplicated, toast: true, hint: false);
  }

  /// 新文件夹追加到根目录末尾；已存在则只改名称。
  void upsertFolder(String? id, String name) {
    final folders = state.quick.folders;
    final exists = id != null && folders.any((f) => f.id == id);
    var newId = newSerialId('f');
    while (folders.any((f) => f.id == newId)) {
      newId = newSerialId('f');
    }
    final quick = exists
        ? [
            for (final node in state.quick)
              if (node is QuickFolder && node.id == id)
                node.copyWith(name: name)
              else
                node,
          ]
        : [...state.quick, QuickFolder(id: newId, name: name)];
    _emit(state.copyWith(quick: quick));
    _persist();
    _notify(SerialNoticeKind.folderSaved, toast: true, hint: false);
  }

  void toggleFolder(String id) {
    _emit(
      state.copyWith(
        quick: [
          for (final node in state.quick)
            if (node is QuickFolder && node.id == id)
              node.copyWith(expanded: !node.expanded)
            else
              node,
        ],
      ),
    );
    _persist();
  }

  /// 连同文件夹内指令一起删除。
  void deleteFolder(String id) {
    _emit(
      state.copyWith(
        quick: state.quick
            .where((node) => !(node is QuickFolder && node.id == id))
            .toList(),
      ),
    );
    _persist();
    _notify(SerialNoticeKind.deleted, toast: true, hint: false);
  }

  Future<void> runBatch(String id) async {
    if (!state.open) {
      _notify(SerialNoticeKind.portClosedBatch, toast: true, warn: true);
      return;
    }
    final job = _byId(state.batch, id);
    if (job == null || job.steps.isEmpty) return;
    _stopBatch(notify: false);
    final token = ++_batchToken;
    final rounds = job.repeat < 1 ? 1 : job.repeat;
    var index = 0;
    var round = 1;
    _sys(SysLogKind.batchStart, {
      'name': job.name,
      'steps': job.steps.length,
      'rounds': rounds,
    });

    Future<void> next() async {
      if (token != _batchToken || isClosed) return;
      if (index >= job.steps.length) {
        if (round >= rounds) {
          _sys(SysLogKind.batchDone, {'name': job.name});
          _emit(state.copyWith(batchRun: null));
          _notify(SerialNoticeKind.batchEnded);
          return;
        }
        round += 1;
        index = 0;
      }
      final step = job.steps[index];
      final delay = index == 0 && round == 1 ? 0 : step.delayMs;
      final completer = Completer<void>();
      _batchTimer = Timer(Duration(milliseconds: delay < 0 ? 0 : delay), () {
        completer.complete();
      });
      await completer.future;
      if (token != _batchToken || isClosed) return;
      _emit(
        state.copyWith(
          batchRun: BatchProgress(
            jobId: job.id,
            step: index + 1,
            total: job.steps.length,
            round: round,
            rounds: rounds,
          ),
        ),
      );
      _notify(
        SerialNoticeKind.batchRunning,
        args: {'step': index + 1, 'total': job.steps.length},
      );
      final ok = await _transmit(
        step.data,
        format: DataFormat.hex,
        checksum: ChecksumKind.none,
        crlf: false,
        recordHistory: false,
      );
      final current = _byId(state.batch, id);
      if (!ok && (current?.stopOnFail ?? job.stopOnFail)) {
        _sys(SysLogKind.batchFail, {'step': index + 1});
        _batchToken++;
        _emit(state.copyWith(batchRun: null));
        _notify(SerialNoticeKind.batchEnded);
        return;
      }
      index += 1;
      await next();
    }

    await next();
  }

  void stopBatch() => _stopBatch(notify: true);

  void upsertBatch(BatchJob job) {
    final batch = [...state.batch];
    final index = batch.indexWhere((item) => item.id == job.id);
    if (index >= 0) {
      batch[index] = job;
    } else {
      batch.add(job);
    }
    _emit(state.copyWith(batch: batch, selectedBatchId: job.id));
    _persist();
    _notify(SerialNoticeKind.batchSaved, toast: true, hint: false);
  }

  void deleteBatch(String id) {
    final batch = state.batch.where((item) => item.id != id).toList();
    final selected = state.selectedBatchId == id
        ? (batch.isEmpty ? null : batch.first.id)
        : state.selectedBatchId;
    _emit(state.copyWith(batch: batch, selectedBatchId: selected));
    _persist();
    _notify(SerialNoticeKind.deleted, toast: true, hint: false);
  }

  void selectBatch(String id) {
    _emit(state.copyWith(selectedBatchId: id));
    _persist();
  }

  /// 复制：步骤、轮数、失败即停一起克隆，插到源任务之后并选中；运行中的任务不受影响。
  void duplicateBatch(String id) {
    final source = _byId(state.batch, id);
    if (source == null) return;
    final copy = BatchJob(
      id: _freshId('b', {for (final b in state.batch) b.id}),
      name: _copyName(source.name, {for (final b in state.batch) b.name}),
      repeat: source.repeat,
      stopOnFail: source.stopOnFail,
      steps: [
        for (final step in source.steps)
          BatchStep(data: step.data, delayMs: step.delayMs, note: step.note),
      ],
    );
    _emit(
      state.copyWith(
        batch: _insertAfterId(state.batch, id, copy, (b) => b.id),
        selectedBatchId: copy.id,
      ),
    );
    _persist();
    _notify(SerialNoticeKind.duplicated, toast: true, hint: false);
  }

  void setBatchRepeat(String id, int repeat) {
    if (repeat <= 0) {
      _notify(
        SerialNoticeKind.repeatInvalid,
        toast: true,
        warn: true,
        hint: false,
      );
      return;
    }
    _replaceBatch(id, (job) => job.copyWith(repeat: repeat));
  }

  void setBatchStopOnFail(String id, bool on) {
    _replaceBatch(id, (job) => job.copyWith(stopOnFail: on));
  }

  void toggleRule(String id) {
    final rule = _byId(state.rules, id);
    if (rule == null) return;
    final enabled = !rule.enabled;
    _replaceRule(id, (item) => item.copyWith(enabled: enabled));
    _notify(
      enabled ? SerialNoticeKind.ruleToggled : SerialNoticeKind.ruleToggled,
      args: {'name': rule.name, 'enabled': enabled},
    );
  }

  Future<void> fireRule(String id) async {
    final rule = _byId(state.rules, id);
    if (rule == null) return;
    if (!state.open) {
      _notify(SerialNoticeKind.portClosedRule, toast: true, warn: true);
      return;
    }
    final hit = rule.copyWith(hits: rule.hits + 1);
    _replaceRule(id, (_) => hit);
    _sys(SysLogKind.autoReply, {'name': hit.name, 'count': hit.replies.length});
    _scheduleReplies(hit, const []);
  }

  void upsertRule(ReplyRule rule) {
    final rules = [...state.rules];
    final index = rules.indexWhere((item) => item.id == rule.id);
    if (index >= 0) {
      rules[index] = rule;
    } else {
      rules.add(rule);
    }
    _emit(state.copyWith(rules: rules));
    _persist();
    _notify(SerialNoticeKind.ruleSaved, toast: true, hint: false);
  }

  void deleteRule(String id) {
    _emit(
      state.copyWith(
        rules: state.rules.where((item) => item.id != id).toList(),
      ),
    );
    _persist();
    _notify(SerialNoticeKind.deleted, toast: true, hint: false);
  }

  /// 复制：克隆插到源规则之后；克隆默认停用、命中归零，避免意外应答。
  void duplicateRule(String id) {
    final source = _byId(state.rules, id);
    if (source == null) return;
    final copy = ReplyRule(
      id: _freshId('r', {for (final r in state.rules) r.id}),
      name: _copyName(source.name, {for (final r in state.rules) r.name}),
      match: source.match,
      pattern: source.pattern,
      enabled: false,
      hits: 0,
      replies: source.replies,
      kind: source.kind,
      format: source.format,
      ignoreCase: source.ignoreCase,
    );
    _emit(
      state.copyWith(rules: _insertAfterId(state.rules, id, copy, (r) => r.id)),
    );
    _persist();
    _notify(SerialNoticeKind.duplicated, toast: true, hint: false);
  }

  Future<void> resendHistory(int index) async {
    if (index < 0 || index >= state.history.length) return;
    final text = state.history[index].text;
    final format = SerialBytes.parseHex(text) != null
        ? DataFormat.hex
        : DataFormat.ascii;
    await _transmit(text, format: format, recordHistory: true);
  }

  void fillHistory(int index) {
    if (index < 0 || index >= state.history.length) return;
    _emit(
      state.copyWith(
        txText: state.history[index].text,
        fileName: null,
        fileBytes: null,
      ),
    );
    _persist();
  }

  void removeHistory(int index) {
    if (index < 0 || index >= state.history.length) return;
    final history = [...state.history]..removeAt(index);
    _emit(state.copyWith(history: history));
    _persist();
  }

  void clearHistory() {
    _emit(state.copyWith(history: const []));
    _persist();
    _notify(SerialNoticeKind.deleted, toast: true, hint: false);
  }

  void selectScript(String id) {
    _emit(state.copyWith(selectedScriptId: id, scriptDock: true));
  }

  void setScriptDock(bool on) {
    if (state.scriptDock == on) return;
    _emit(state.copyWith(scriptDock: on));
  }

  void toggleScript(String id) {
    final script = _scriptById(id);
    if (script == null) return;
    final enabled = !script.enabled;
    _replaceScript(id, (item) => item.copyWith(enabled: enabled));
    _notify(
      SerialNoticeKind.scriptToggled,
      args: {'name': script.name, 'enabled': enabled},
    );
  }

  void newScript() {
    final names = state.scripts.map((s) => s.name).toSet();
    var n = state.scripts.length + 1;
    while (names.contains('script$n.lua')) {
      n++;
    }
    _addScript('script$n.lua', LuaScript.template);
  }

  void setScriptTutorial(bool on) {
    if (state.scriptTutorial == on) return;
    _emit(state.copyWith(scriptTutorial: on));
  }

  /// 展开一课；再点同一课收起。
  void toggleLesson(String key) {
    _emit(state.copyWith(openLesson: state.openLesson == key ? null : key));
  }

  /// 用这课的代码新建脚本（默认停用），切回脚本列表并打开编辑区。
  void newScriptFromLesson(ScriptLesson lesson) {
    final names = state.scripts.map((s) => s.name).toSet();
    final stem = lesson.fileName.replaceFirst(RegExp(r'\.lua$'), '');
    var name = lesson.fileName;
    for (var n = 2; names.contains(name); n++) {
      name = '${stem}_$n.lua';
    }
    final script = _addScript(name, lesson.code);
    _emit(state.copyWith(scriptTutorial: false));
    _notify(
      SerialNoticeKind.lessonCreated,
      args: {'lesson': lesson.key, 'name': script.name},
    );
  }

  /// 样例试跑：把这课的样例帧交给它的代码，输出写进运行日志；不发送，也不计入任何脚本。
  void tryLesson(ScriptLesson lesson) {
    final sample = SerialBytes.parseHex(lesson.sample);
    if (sample == null) return;
    final probe = LuaScript(
      id: 'lesson:${lesson.key}',
      name: lesson.fileName,
      code: lesson.code,
      enabled: false,
    );
    final receive = lesson.hook == ScriptHook.onReceive;
    final out = receive
        ? _engine.receive(probe.id, probe.code, sample)
        : _engine.beforeSend(probe.id, probe.code, sample);
    _engine.forget(probe.id);
    _scriptLogs(probe, [
      _scriptEntry(
        probe,
        ScriptLogKind.lessonTry,
        text: lesson.hookName,
        from: SerialBytes.toHex(sample),
      ),
      ..._outcomeEntries(probe, out),
      if (!receive && out.error == null) _dryRunEntry(probe, sample, out.bytes),
    ]);
    _emit(state.copyWith(scriptDock: true));
    _notify(SerialNoticeKind.lessonTried);
  }

  LuaScript _addScript(String name, String code) {
    var id = newSerialId('s');
    while (state.scripts.any((s) => s.id == id)) {
      id = newSerialId('s');
    }
    final script = LuaScript(id: id, name: name, code: code, enabled: false);
    _emit(
      state.copyWith(
        scripts: [...state.scripts, script],
        selectedScriptId: id,
        scriptDock: true,
        scriptMeta: {...state.scriptMeta, id: _inspect(script)},
      ),
    );
    _persist();
    return script;
  }

  void renameScript(String id, String name) {
    final value = name.trim();
    if (value.isEmpty) return;
    _replaceScript(id, (item) => item.copyWith(name: value));
    _notify(SerialNoticeKind.scriptSaved, toast: true, hint: false);
  }

  void deleteScript(String id) {
    _engine.forget(id);
    _brokenLogged.remove(id);
    final scripts = state.scripts.where((s) => s.id != id).toList();
    final selected = state.selectedScriptId == id
        ? (scripts.isEmpty ? null : scripts.first.id)
        : state.selectedScriptId;
    _emit(
      state.copyWith(
        scripts: scripts,
        selectedScriptId: selected,
        scriptMeta: {...state.scriptMeta}..remove(id),
      ),
    );
    _persist();
    _notify(SerialNoticeKind.deleted, toast: true, hint: false);
  }

  /// 复制：克隆插到源脚本之后，命名保留 .lua；克隆默认停用、选中并打开编辑区，不复制运行日志。
  void duplicateScript(String id) {
    final source = _scriptById(id);
    if (source == null) return;
    final copy = LuaScript(
      id: _freshId('s', {for (final s in state.scripts) s.id}),
      name: _copyName(source.name, {
        for (final s in state.scripts) s.name,
      }, script: true),
      code: source.code,
      enabled: false,
    );
    _emit(
      state.copyWith(
        scripts: _insertAfterId(state.scripts, id, copy, (s) => s.id),
        selectedScriptId: copy.id,
        scriptDock: true,
        scriptMeta: {...state.scriptMeta, copy.id: _inspect(copy)},
      ),
    );
    _persist();
    _notify(SerialNoticeKind.duplicated, toast: true, hint: false);
  }

  /// 输入即保存；编译检查防抖，避免每次按键都重建虚拟机。
  void setScriptCode(String id, String code) {
    final script = _scriptById(id);
    if (script == null || script.code == code) return;
    _replaceScript(id, (item) => item.copyWith(code: code));
    _scriptDebounce.run(() {
      if (isClosed) return;
      final current = _scriptById(id);
      if (current == null) return;
      _emit(
        state.copyWith(
          scriptMeta: {...state.scriptMeta, id: _inspect(current)},
        ),
      );
    });
  }

  void clearScriptLog() {
    _emit(state.copyWith(scriptLog: const []));
  }

  /// 手动运行：on_receive 用最近收到的一帧；before_send 用发送框内容试算，不发送。
  void runScript(String id) {
    final script = _scriptById(id);
    if (script == null) return;
    final meta = _inspect(script);
    _emit(state.copyWith(scriptMeta: {...state.scriptMeta, id: meta}));
    final error = meta.error;
    if (error != null) {
      _scriptLogs(script, [
        _scriptEntry(script, ScriptLogKind.error, text: error),
      ]);
      return;
    }
    if (meta.hooks.isEmpty) {
      _scriptLogs(script, [_scriptEntry(script, ScriptLogKind.noHook)]);
      return;
    }
    if (meta.hooks.contains(ScriptHook.onReceive)) {
      final rx = _lastRx;
      if (rx == null) {
        _scriptLogs(script, [_scriptEntry(script, ScriptLogKind.noRx)]);
      } else {
        final out = _engine.receive(script.id, script.code, rx);
        _scriptLogs(script, [
          _scriptEntry(
            script,
            ScriptLogKind.manualRx,
            from: SerialBytes.toHex(rx),
          ),
          ..._outcomeEntries(script, out),
        ]);
      }
    }
    if (meta.hooks.contains(ScriptHook.beforeSend)) {
      final sample = _txSample();
      if (sample == null) {
        _scriptLogs(script, [_scriptEntry(script, ScriptLogKind.badTx)]);
        return;
      }
      final out = _engine.beforeSend(script.id, script.code, sample);
      _scriptLogs(script, [
        ..._outcomeEntries(script, out),
        if (out.error == null) _dryRunEntry(script, sample, out.bytes),
      ]);
    }
  }

  /// 当前四类内容，供导出清单显示条数与写文件。
  ConfigPack currentConfig() => ConfigPack(
    quick: state.quick,
    rules: state.rules,
    batch: state.batch,
    scripts: state.scripts,
  );

  Future<void> exportConfig(Set<ConfigPart> parts) => _exportJson(
    suggestedName: ConfigPack.fileName,
    data: currentConfig().toJson(parts),
    done: SerialNoticeKind.exportedConfig,
  );

  /// 选文件并解析；取消、读失败或格式不对时返回 null（后两者已提示）。
  Future<ConfigPack?> pickConfig() async {
    try {
      final text = await _repo.pickText(extensions: const ['json']);
      if (text == null) return null;
      final pack = ConfigPack.fromJson(jsonDecode(text));
      if (pack == null) throw const FormatException('config');
      return pack;
    } on AppException catch (error, stackTrace) {
      _logIo('导入失败', error, stackTrace);
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '导入文件格式不正确',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      _notify(
        SerialNoticeKind.importInvalid,
        toast: true,
        warn: true,
        hint: false,
      );
    }
    return null;
  }

  /// 勾选且文件里有的类别整表替换；其余保持现状。
  void applyConfig(ConfigPack pack, Set<ConfigPart> parts) {
    final use = parts.intersection(pack.parts);
    if (use.isEmpty) return;
    if (use.contains(ConfigPart.batch) && state.batchRun != null) {
      _stopBatch(notify: true);
    }
    final quick = pack.quick;
    final rules = pack.rules;
    final batch = pack.batch;
    final scripts = pack.scripts;
    if (use.contains(ConfigPart.scripts) && scripts != null) {
      for (final old in state.scripts) {
        _engine.forget(old.id);
      }
      _brokenLogged.clear();
    }
    _emit(
      state.copyWith(
        quick: use.contains(ConfigPart.quick) ? quick!.withUniqueKeys() : null,
        rules: use.contains(ConfigPart.rules)
            ? [for (final r in rules!) r.copyWith(hits: 0)]
            : null,
        batch: use.contains(ConfigPart.batch) ? batch : null,
        selectedBatchId: use.contains(ConfigPart.batch)
            ? (batch!.isEmpty ? null : batch.first.id)
            : state.selectedBatchId,
        scripts: use.contains(ConfigPart.scripts) ? scripts : null,
        selectedScriptId: use.contains(ConfigPart.scripts)
            ? (scripts!.isEmpty ? null : scripts.first.id)
            : state.selectedScriptId,
        scriptMeta: use.contains(ConfigPart.scripts) ? const {} : null,
      ),
    );
    if (use.contains(ConfigPart.scripts)) _inspectScripts();
    _persist();
    final now = currentConfig();
    _notify(
      SerialNoticeKind.importedConfig,
      toast: true,
      hint: false,
      args: {
        for (final part in ConfigPart.values)
          if (use.contains(part)) part.name: now.count(part) ?? 0,
      },
    );
  }

  void appendChecksum(Uint8List raw, ChecksumKind kind) {
    final text = SerialBytes.toHex([
      ...raw,
      ...SerialBytes.checksumBytes(raw, kind),
    ]);
    _emit(
      state.copyWith(
        txFormat: DataFormat.hex,
        txText: text,
        fileName: null,
        fileBytes: null,
      ),
    );
    _persist();
    _notify(
      SerialNoticeKind.checksumFilled,
      toast: true,
      hint: false,
      args: {'text': text},
    );
  }

  Future<void> _startLoop(String text, DataFormat format) async {
    final period = state.loopPeriodMs;
    if (period < SerialMetrics.minLoopMs) {
      _notify(
        SerialNoticeKind.periodInvalid,
        toast: true,
        warn: true,
        hint: false,
      );
      return;
    }
    if (!await _transmit(text, format: format, recordHistory: true)) return;
    _loop?.cancel();
    _emit(state.copyWith(looping: true));
    _notify(SerialNoticeKind.loopStarted, args: {'period': period});
    _loop = Timer.periodic(Duration(milliseconds: period), (_) {
      unawaited(() async {
        final ok = await _transmit(text, format: format, recordHistory: false);
        if (!ok) stopLoop();
      }());
    });
  }

  void _stopLoop({required bool notify}) {
    final was = _loop != null || state.looping;
    _loop?.cancel();
    _loop = null;
    if (state.looping) _emit(state.copyWith(looping: false));
    if (notify && was) _notify(SerialNoticeKind.loopStopped);
  }

  void _stopBatch({required bool notify}) {
    final was = _batchTimer != null || state.batchRun != null;
    _batchToken++;
    _batchTimer?.cancel();
    _batchTimer = null;
    if (state.batchRun != null) _emit(state.copyWith(batchRun: null));
    if (notify && was) {
      _sys(SysLogKind.batchStopped, const {});
      _notify(SerialNoticeKind.batchEnded);
    }
  }

  Future<bool> _transmit(
    String text, {
    DataFormat? format,
    ChecksumKind? checksum,
    bool? crlf,
    bool? escape,
    bool? atCrlf,
    bool recordHistory = false,
  }) async {
    if (!state.open) {
      _notify(SerialNoticeKind.portClosedSend, toast: true, warn: true);
      return false;
    }
    final encoded = SerialBytes.encode(
      text: text,
      format: format ?? state.txFormat,
      escape: escape ?? state.escape,
      atCrlf: atCrlf ?? state.atCrlf,
      crlf: crlf ?? state.crlf,
      checksum: checksum ?? state.checksum,
    );
    if (encoded.error == EncodeError.badHex) {
      _notify(SerialNoticeKind.badHex, toast: true, warn: true);
      return false;
    }
    final raw = encoded.bytes;
    if (encoded.error == EncodeError.empty || raw == null || raw.isEmpty) {
      _notify(SerialNoticeKind.emptySend, toast: true, warn: true);
      return false;
    }
    final hooked = _sendHooks(raw);
    final bytes = hooked.bytes;
    if (bytes == null) {
      _sys(hooked.failed ? SysLogKind.scriptFailed : SysLogKind.scriptBlocked, {
        'name': hooked.by,
      });
      if (recordHistory) _remember(text);
      return !hooked.failed;
    }
    try {
      await _repo.write(bytes);
    } on AppException catch (error, stackTrace) {
      _logIo('发送失败', error, stackTrace);
      return false;
    }
    if (recordHistory) _remember(text);
    _push(dir: LogDir.tx, bytes: bytes);
    return true;
  }

  void _onChunk(Uint8List chunk) {
    if (!state.open || isClosed) return;
    _assembler.add(chunk, state.packetTimeoutMs, _onPacket);
  }

  void _onPacket(Uint8List bytes) {
    if (isClosed) return;
    _lastRx = bytes;
    _push(dir: LogDir.rx, bytes: bytes);
    _receiveHooks(bytes);
    _matchRules(bytes);
  }

  void _receiveHooks(Uint8List bytes) {
    for (final script in state.scripts) {
      if (!script.enabled || !_compiles(script)) continue;
      final out = _engine.receive(script.id, script.code, bytes);
      final entries = _outcomeEntries(script, out);
      if (entries.isNotEmpty) _scriptLogs(script, entries);
    }
  }

  /// 按列表顺序串联已启用的 before_send；bytes 为 null 表示被拦截，[failed] 为脚本出错。
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
        entries.add(
          _scriptEntry(
            script,
            ScriptLogKind.blocked,
            from: SerialBytes.toHex(current),
          ),
        );
        _scriptLogs(script, entries);
        return (bytes: null, by: script.name, failed: false);
      }
      if (!_sameBytes(next, current)) {
        entries.add(
          _scriptEntry(
            script,
            ScriptLogKind.changed,
            from: SerialBytes.toHex(current),
            to: SerialBytes.toHex(next),
          ),
        );
      }
      if (entries.isNotEmpty) _scriptLogs(script, entries);
      current = next;
    }
    return (bytes: current, by: '', failed: false);
  }

  /// 编译失败的脚本不参与自动运行；同一版代码的错误只记一次运行日志。
  bool _compiles(LuaScript script) {
    final error = _engine.inspect(script.id, script.code).error;
    if (error == null) return true;
    if (_brokenLogged[script.id] != script.code) {
      _brokenLogged[script.id] = script.code;
      _scriptLogs(script, [
        _scriptEntry(script, ScriptLogKind.error, text: error),
      ]);
    }
    return false;
  }

  ScriptMeta _inspect(LuaScript script) {
    final info = _engine.inspect(script.id, script.code);
    return ScriptMeta(
      hooks: info.hooks,
      error: info.error,
      outputs: state.scriptMeta[script.id]?.outputs ?? 0,
    );
  }

  void _inspectScripts() {
    _engine.retain(state.scripts.map((s) => s.id));
    _emit(
      state.copyWith(
        scriptMeta: {for (final s in state.scripts) s.id: _inspect(s)},
      ),
    );
  }

  List<ScriptLogEntry> _outcomeEntries(LuaScript script, ScriptOutcome out) {
    final error = out.error;
    return [
      for (final text in out.logs)
        _scriptEntry(script, ScriptLogKind.output, text: text),
      if (error != null)
        out.tooLong
            ? _scriptEntry(script, ScriptLogKind.tooLong)
            : _scriptEntry(script, ScriptLogKind.error, text: error),
    ];
  }

  ScriptLogEntry _scriptEntry(
    LuaScript script,
    ScriptLogKind kind, {
    String text = '',
    String from = '',
    String to = '',
  }) => ScriptLogEntry(
    time: DateTime.now(),
    name: script.name,
    kind: kind,
    text: text,
    from: from,
    to: to,
  );

  /// before_send 试算结果：改写后的帧，或拦截。
  ScriptLogEntry _dryRunEntry(
    LuaScript script,
    Uint8List sample,
    Uint8List? next,
  ) => next == null || next.isEmpty
      ? _scriptEntry(
          script,
          ScriptLogKind.dryBlocked,
          from: SerialBytes.toHex(sample),
        )
      : _scriptEntry(
          script,
          ScriptLogKind.dryRun,
          from: SerialBytes.toHex(sample),
          to: SerialBytes.toHex(next),
        );

  void _scriptLogs(LuaScript script, List<ScriptLogEntry> entries) {
    if (entries.isEmpty) return;
    final log = [...state.scriptLog, ...entries];
    if (log.length > SerialMetrics.scriptLogLimit) {
      log.removeRange(0, log.length - SerialMetrics.scriptLogLimit);
    }
    // 教程试跑用的临时脚本不在列表里，不记输出次数
    final known = _scriptById(script.id) != null;
    final meta = state.scriptMeta[script.id] ?? const ScriptMeta();
    _emit(
      state.copyWith(
        scriptLog: log,
        scriptMeta: known
            ? {
                ...state.scriptMeta,
                script.id: meta.copyWith(
                  outputs: meta.outputs + entries.length,
                ),
              }
            : null,
      ),
    );
  }

  Uint8List? _txSample() {
    final file = state.fileBytes;
    if (file != null) return file;
    final bytes = SerialBytes.encode(
      text: state.txText,
      format: state.txFormat,
      escape: state.escape,
      atCrlf: state.atCrlf,
      crlf: state.crlf,
      checksum: state.checksum,
    ).bytes;
    return bytes == null || bytes.isEmpty ? null : bytes;
  }

  LuaScript? _scriptById(String id) {
    for (final script in state.scripts) {
      if (script.id == id) return script;
    }
    return null;
  }

  void _replaceScript(String id, LuaScript Function(LuaScript s) update) {
    _emit(
      state.copyWith(
        scripts: [
          for (final script in state.scripts)
            if (script.id == id) update(script) else script,
        ],
      ),
    );
    _persist();
  }

  void _matchRules(Uint8List bytes) {
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
    _emit(state.copyWith(rules: next));
    _persist();
    for (final (rule, captures) in matched) {
      _sys(SysLogKind.autoReply, {
        'name': rule.name,
        'count': rule.replies.length,
      });
      _scheduleReplies(rule, captures);
    }
  }

  void _scheduleReplies(ReplyRule rule, List<Uint8List?> captures) {
    var wait = 0;
    for (var i = 0; i < rule.replies.length; i++) {
      final reply = rule.replies[i];
      wait += reply.delayMs < 0 ? 0 : reply.delayMs;
      late final Timer timer;
      timer = Timer(Duration(milliseconds: wait), () {
        _replies.remove(timer);
        if (!state.open || isClosed) return;
        final data = SerialBytes.expandReply(reply.data, captures);
        if (data == null) {
          _sys(SysLogKind.replySkipped, {'name': rule.name, 'step': i + 1});
          return;
        }
        unawaited(
          _transmit(
            data,
            format: DataFormat.hex,
            checksum: ChecksumKind.none,
            crlf: false,
            recordHistory: false,
          ),
        );
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

  Future<void> _shutdown() async {
    if (_closing) return;
    _closing = true;
    try {
      _stopLoop(notify: false);
      _stopBatch(notify: false);
      _cancelReplies();
      _pins?.cancel();
      _assembler.flush(_onPacket);
      await _repo.close();
      if (isClosed) return;
      final port = state.portName ?? '';
      _emit(
        state.copyWith(
          open: false,
          pins: const PinLevels(),
          looping: false,
          batchRun: null,
        ),
      );
      _sys(SysLogKind.closed, {'port': port});
      _notify(SerialNoticeKind.portClosed);
    } finally {
      _closing = false;
    }
  }

  void _onPortError(Object error, StackTrace stackTrace) {
    AppLogger.i.error(
      '串口读取中断',
      category: LogCategory.device,
      error: error,
      stackTrace: stackTrace,
    );
    if (!state.open || _closing) return;
    unawaited(() async {
      await _shutdown();
      _notify(
        SerialNoticeKind.openFailed,
        toast: true,
        warn: true,
        hint: false,
        args: {'detail': decodeSerialNativeText('$error')},
      );
    }());
  }

  void _startPins() {
    _pins?.cancel();
    _pins = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!state.open || isClosed) return;
      final pins = _repo.readPins();
      if (pins != state.pins) _emit(state.copyWith(pins: pins));
    });
  }

  Future<void> _commit(SerialConsoleState next, {bool announce = false}) async {
    if (next.open) {
      final link = next.link;
      if (link == null) return;
      try {
        await _repo.apply(link);
      } on AppException catch (error, stackTrace) {
        _logIo('串口参数未生效', error, stackTrace);
        return;
      }
    }
    _emit(next);
    _persist();
    if (announce && next.open) {
      _notify(
        SerialNoticeKind.paramsApplied,
        args: {'conn': next.connectionLabel},
      );
    }
  }

  void _push({
    required LogDir dir,
    Uint8List? bytes,
    SysLogKind? sys,
    Map<String, Object> args = const {},
  }) {
    final line = LogLine(
      no: ++_seq,
      time: DateTime.now(),
      dir: dir,
      bytes: bytes,
      sys: sys,
      args: args,
    );
    final lines = [...state.lines, line];
    if (lines.length > SerialMetrics.logLimit) {
      lines.removeRange(0, lines.length - SerialMetrics.logLimit);
    }
    var rx = state.rxCount;
    var tx = state.txCount;
    var saved = state.savedCount;
    if (dir == LogDir.rx && bytes != null) {
      rx += bytes.length;
      if (state.saveActive) {
        _saveBuf.add('[${fullStamp(line.time)}] ${SerialBytes.toHex(bytes)}');
        saved = _saveBuf.length;
      }
    } else if (dir == LogDir.tx && bytes != null) {
      tx += bytes.length;
    }
    _emit(
      state.copyWith(lines: lines, rxCount: rx, txCount: tx, savedCount: saved),
    );
  }

  void _sys(SysLogKind kind, Map<String, Object> args) {
    _push(dir: LogDir.sys, sys: kind, args: args);
  }

  void _remember(String text) {
    final value = text.trim();
    if (value.isEmpty) return;
    final history = [
      HistoryEntry(text: value, time: DateTime.now()),
      ...state.history.where((item) => item.text != value),
    ].take(SerialMetrics.historyLimit).toList();
    _emit(state.copyWith(history: history));
    _persist();
  }

  void _replaceBatch(String id, BatchJob Function(BatchJob job) update) {
    final batch = [
      for (final job in state.batch)
        if (job.id == id) update(job) else job,
    ];
    _emit(state.copyWith(batch: batch));
    _persist();
  }

  void _replaceRule(String id, ReplyRule Function(ReplyRule rule) update) {
    final rules = [
      for (final rule in state.rules)
        if (rule.id == id) update(rule) else rule,
    ];
    _emit(state.copyWith(rules: rules));
    _persist();
  }

  Future<void> _exportJson({
    required String suggestedName,
    required Object data,
    required SerialNoticeKind done,
  }) async {
    try {
      final path = await _repo.pickSave(
        suggestedName: suggestedName,
        extension: 'json',
      );
      if (path == null) return;
      await _repo.writeText(
        path: path,
        text: const JsonEncoder.withIndent('  ').convert(data),
      );
      _notify(done, toast: true, hint: false);
    } on AppException catch (error, stackTrace) {
      _logIo('导出失败', error, stackTrace);
    }
  }

  String _logDump() {
    final buffer = StringBuffer();
    for (final line in state.lines) {
      final stamp = clockStamp(line.time);
      if (line.dir == LogDir.sys) {
        buffer.writeln('[$stamp] SYS  ${line.sys?.name ?? ''}');
      } else {
        final tag = line.dir == LogDir.rx ? 'RX' : 'TX';
        buffer.writeln(
          '[$stamp] $tag  ${SerialBytes.toHex(line.bytes ?? const [])}',
        );
      }
    }
    return buffer.toString();
  }

  SerialConsoleState _applyWorkspace(SerialWorkspace ws) {
    return state.copyWith(
      portName: ws.portName,
      baud: ws.baud,
      parity: ws.parity,
      dataBits: ws.dataBits,
      stopBits: ws.stopBits,
      flow: ws.flow,
      dtr: ws.dtr,
      rts: ws.rts,
      rxFormat: ws.rxFormat,
      logMode: ws.logMode,
      wrap: ws.wrap,
      hideRx: ws.hideRx,
      autoScroll: ws.autoScroll,
      packetTimeoutMs: ws.packetTimeoutMs,
      txFormat: ws.txFormat,
      escape: ws.escape,
      atCrlf: ws.atCrlf,
      crlf: ws.crlf,
      checksum: ws.checksum,
      clearAfterSend: ws.clearAfterSend,
      loopEnabled: ws.loopEnabled,
      loopPeriodMs: ws.loopPeriodMs,
      txText: ws.txText,
      compact: ws.compact,
      toolsVisible: ws.toolsVisible,
      tab: ws.tab,
      quick: ws.quick,
      rules: ws.rules,
      batch: ws.batch,
      selectedBatchId: ws.selectedBatchId,
      history: ws.history,
      scripts: ws.scripts,
      selectedScriptId: ws.scripts.isEmpty ? null : ws.scripts.first.id,
    );
  }

  void _persist() {
    _persistDebounce.run(() {
      unawaited(_repo.save(state.toWorkspace()));
    });
  }

  void _notify(
    SerialNoticeKind kind, {
    bool toast = false,
    bool warn = false,
    bool hint = true,
    Map<String, Object> args = const {},
  }) {
    final notice = SerialNotice(
      id: ++_notice,
      kind: kind,
      warn: warn,
      args: args,
    );
    if (toast && hint) {
      _emit(state.copyWith(hint: notice, toast: notice));
    } else if (toast) {
      _emit(state.copyWith(toast: notice));
    } else if (hint) {
      _emit(state.copyWith(hint: notice));
    }
  }

  void _emit(SerialConsoleState next) {
    if (!isClosed) emit(next);
  }

  void _logIo(String message, AppException error, StackTrace stackTrace) {
    AppLogger.i.error(
      message,
      category: LogCategory.device,
      error: error,
      stackTrace: stackTrace,
    );
    _notify(
      SerialNoticeKind.configFailed,
      toast: true,
      warn: true,
      hint: false,
      args: {'detail': error.message},
    );
  }
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

T? _byId<T>(List<T> items, String id) {
  for (final item in items) {
    if (item is ReplyRule && item.id == id) return item;
    if (item is BatchJob && item.id == id) return item;
  }
  return null;
}

String _freshId(String prefix, Set<String> taken) {
  var id = newSerialId(prefix);
  while (taken.contains(id)) {
    id = newSerialId(prefix);
  }
  return id;
}

/// 「副本」命名：源名加「副本」，重名时「副本 2」「副本 3」顺延；脚本保留 .lua 扩展名。
String _copyName(String name, Set<String> taken, {bool script = false}) {
  final lua = script && name.toLowerCase().endsWith('.lua');
  final stem = lua ? name.substring(0, name.length - 4) : name;
  String label(int? n) {
    if (!script) return n == null ? '$name 副本' : '$name 副本 $n';
    final suffix = n == null ? '_副本' : '_副本_$n';
    return lua ? '$stem$suffix.lua' : '$stem$suffix';
  }

  var text = label(null);
  for (var n = 2; taken.contains(text); n++) {
    text = label(n);
  }
  return text;
}

/// 克隆插到源条目之后；第二次复制仍紧随源条目，第一次的副本顺移。
List<T> _insertAfterId<T>(
  List<T> list,
  String id,
  T copy,
  String Function(T item) idOf,
) {
  final next = <T>[];
  for (final item in list) {
    next.add(item);
    if (idOf(item) == id) next.add(copy);
  }
  return next;
}
