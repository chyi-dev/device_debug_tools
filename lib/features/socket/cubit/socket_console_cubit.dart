import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/utils/debounce.dart';
import '../../serial/data/lua_script_engine.dart';
import '../../serial/data/packet_assembler.dart';
import '../../serial/data/serial_bytes.dart';
import '../../serial/data/serial_stamp.dart';
import '../../serial/model/script_lessons.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../model/socket_models.dart';
import '../repository/socket_console_repository.dart';
import 'socket_console_state.dart';

class SocketConsoleCubit extends Cubit<SocketConsoleState> {
  SocketConsoleCubit({
    required SocketConsoleRepository repository,
    required SocketProtocol protocol,
    LuaScriptEngine? scriptEngine,
  }) : _repo = repository,
       _protocol = protocol,
       _engine = scriptEngine ?? LuaScriptEngine(),
       super(SocketConsoleState.initial(protocol));

  final SocketConsoleRepository _repo;
  final LuaScriptEngine _engine;
  final SocketProtocol _protocol;
  final Debouncer _persistDebounce = Debouncer(
    duration: const Duration(milliseconds: 400),
  );
  final Debouncer _scriptDebounce = Debouncer(
    duration: const Duration(milliseconds: 300),
  );
  final PacketAssembler _assembler = PacketAssembler();
  final Map<String, PacketAssembler> _peerAssemblers = {};
  final List<Timer> _replies = [];
  final List<String> _saveBuf = [];

  /// 自动运行时已记录过编译错误的脚本 id → 代码，同一版代码只记一次。
  final Map<String, String> _brokenLogged = {};
  Uint8List? _lastRx;

  StreamSubscription<SocketIncoming>? _incomingSub;
  StreamSubscription<List<SocketPeer>>? _peersSub;
  StreamSubscription<bool>? _openSub;
  StreamSubscription<String>? _errorsSub;
  Timer? _loop;
  Timer? _batchTimer;
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
    _incomingSub ??= _repo.incoming.listen(_onIncoming, onError: _onStreamError);
    _peersSub ??= _repo.peers.listen(_onPeers);
    _openSub ??= _repo.openState.listen(_onOpenState);
    _errorsSub ??= _repo.errors.listen(_onGatewayError);
  }

  @override
  Future<void> close() async {
    _persistDebounce.dispose();
    _scriptDebounce.dispose();
    _engine.dispose();
    _stopLoop(notify: false);
    _stopBatch(notify: false);
    _cancelReplies();
    _disposeAssemblers();
    await _incomingSub?.cancel();
    await _peersSub?.cancel();
    await _openSub?.cancel();
    await _errorsSub?.cancel();
    _incomingSub = null;
    _peersSub = null;
    _openSub = null;
    _errorsSub = null;
    await _repo.close();
    try {
      await _repo.save(state.toWorkspace());
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '保存 Socket 工作区失败',
        category: LogCategory.database,
        error: error,
        stackTrace: stackTrace,
      );
    }
    return super.close();
  }

  Future<void> setRole(SocketRole role) async {
    if (!state.isTcp || role == state.role) return;
    if (state.open) await _shutdown();
    _emit(
      state.copyWith(
        role: role,
        peers: const [],
        selectedPeerId: null,
      ),
    );
    _persist();
    _notify(SocketNoticeKind.roleChanged);
  }

  Future<void> setHost(String host) async {
    final value = host.trim();
    if (value.isEmpty) {
      _notify(
        SocketNoticeKind.hostInvalid,
        toast: true,
        warn: true,
        hint: false,
      );
      return;
    }
    if (value == state.host) return;
    if (state.open) await _shutdown();
    _emit(state.copyWith(host: value));
    _persist();
  }

  Future<void> setPort(int port) async {
    if (!_validPort(port)) {
      _notify(
        SocketNoticeKind.portInvalid,
        toast: true,
        warn: true,
        hint: false,
      );
      return;
    }
    if (port == state.port) return;
    if (state.open) await _shutdown();
    _emit(state.copyWith(port: port));
    _persist();
  }

  Future<void> setRemoteHost(String host) async {
    final value = host.trim();
    if (value == state.remoteHost) return;
    _emit(state.copyWith(remoteHost: value));
    _persist();
  }

  Future<void> setRemotePort(int port) async {
    if (!_validPort(port)) {
      _notify(
        SocketNoticeKind.portInvalid,
        toast: true,
        warn: true,
        hint: false,
      );
      return;
    }
    if (port == state.remotePort) return;
    _emit(state.copyWith(remotePort: port));
    _persist();
  }

  void selectPeer(String? peerId) {
    if (peerId == state.selectedPeerId) return;
    if (peerId != null && state.peers.every((p) => p.id != peerId)) return;
    _emit(state.copyWith(selectedPeerId: peerId));
    _persist();
  }

  Future<void> toggleOpen() async {
    if (state.busy) return;
    if (state.open) {
      await _shutdown();
      return;
    }
    if (!_validHost(state.host)) {
      _notify(
        SocketNoticeKind.hostInvalid,
        toast: true,
        warn: true,
      );
      return;
    }
    if (!_validPort(state.port)) {
      _notify(
        SocketNoticeKind.portInvalid,
        toast: true,
        warn: true,
      );
      return;
    }
    _emit(state.copyWith(busy: true));
    try {
      if (state.isUdp) {
        await _repo.openUdp(host: state.host, port: state.port);
      } else if (state.isTcpServer) {
        await _repo.openTcpServer(host: state.host, port: state.port);
      } else {
        await _repo.openTcpClient(host: state.host, port: state.port);
      }
      if (isClosed) return;
      _emit(
        state.copyWith(
          open: true,
          busy: false,
          peers: _repo.currentPeers,
        ),
      );
      _sys(SysLogKind.opened, {'endpoint': state.endpoint});
      _notify(SocketNoticeKind.opened);
    } on AppException catch (error, stackTrace) {
      AppLogger.i.error(
        '打开 Socket 失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      if (!isClosed) _emit(state.copyWith(busy: false));
      _notify(
        SocketNoticeKind.openFailed,
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
        SocketNoticeKind.timeoutInvalid,
        toast: true,
        warn: true,
        hint: false,
      );
      return;
    }
    _emit(state.copyWith(packetTimeoutMs: ms));
    _persist();
  }

  Future<void> setSaveRx(bool on) async {
    if (on) {
      _saveBuf.clear();
      final tag = state.isUdp ? 'udp' : 'tcp';
      final name = 'recv-$tag-${fileStamp(DateTime.now())}.log';
      _emit(state.copyWith(saveActive: true, saveName: name, savedCount: 0));
      _notify(SocketNoticeKind.saveStarted, toast: true);
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
        SocketNoticeKind.saveWritten,
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
        SocketNoticeKind.fileLoaded,
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
        SocketNoticeKind.periodInvalid,
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
    _notify(SocketNoticeKind.recvCleared);
  }

  Future<void> saveLog() async {
    final tag = state.isUdp ? 'udp' : 'tcp';
    final path = await _repo.pickSave(
      suggestedName:
          'socket-$tag-${DateTime.now().millisecondsSinceEpoch}.log',
      extension: 'log',
    );
    if (path == null) return;
    try {
      await _repo.writeText(path: path, text: _logDump());
      _notify(SocketNoticeKind.logSaved, toast: true, hint: false);
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
    final next = tab == ToolTab.calc ? ToolTab.quick : tab;
    _emit(state.copyWith(tab: next, toolsVisible: true));
    _persist();
  }

  Future<void> sendQuick(String id) async {
    final command = state.quick.commandById(id);
    if (command == null || !command.enabled) return;
    await _transmit(
      command.data,
      format: command.format,
      checksum: ChecksumKind.none,
      crlf: false,
      recordHistory: false,
    );
  }

  void toggleQuick(String id) {
    final command = state.quick.commandById(id);
    if (command == null) return;
    _replaceQuick(command.copyWith(enabled: !command.enabled));
  }

  void _replaceQuick(QuickCommand command) {
    final quick = <QuickNode>[
      for (final node in state.quick)
        switch (node) {
          QuickCommand() => node.id == command.id ? command : node,
          QuickFolder() => node.copyWith(
            commands: [
              for (final item in node.commands)
                if (item.id == command.id) command else item,
            ],
          ),
        },
    ];
    _emit(state.copyWith(quick: quick));
    _persist();
  }

  Future<void> sendQuickByKey(String key) async {
    final command = state.quick.commands.where((item) => item.key == key);
    if (command.isEmpty) return;
    await sendQuick(command.first.id);
  }

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
    _notify(SocketNoticeKind.quickSaved, toast: true, hint: false);
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
    _notify(SocketNoticeKind.deleted, toast: true, hint: false);
  }

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
    _notify(SocketNoticeKind.duplicated, toast: true, hint: false);
  }

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
    _notify(SocketNoticeKind.folderSaved, toast: true, hint: false);
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

  void deleteFolder(String id) {
    _emit(
      state.copyWith(
        quick: state.quick
            .where((node) => !(node is QuickFolder && node.id == id))
            .toList(),
      ),
    );
    _persist();
    _notify(SocketNoticeKind.deleted, toast: true, hint: false);
  }

  Future<void> runBatch(String id) async {
    if (!state.open) {
      _notify(SocketNoticeKind.closedBatch, toast: true, warn: true);
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
          _notify(SocketNoticeKind.batchEnded);
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
        SocketNoticeKind.batchRunning,
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
        _notify(SocketNoticeKind.batchEnded);
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
    _notify(SocketNoticeKind.batchSaved, toast: true, hint: false);
  }

  void deleteBatch(String id) {
    final batch = state.batch.where((item) => item.id != id).toList();
    final selected = state.selectedBatchId == id
        ? (batch.isEmpty ? null : batch.first.id)
        : state.selectedBatchId;
    _emit(state.copyWith(batch: batch, selectedBatchId: selected));
    _persist();
    _notify(SocketNoticeKind.deleted, toast: true, hint: false);
  }

  void selectBatch(String id) {
    _emit(state.copyWith(selectedBatchId: id));
    _persist();
  }

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
    _notify(SocketNoticeKind.duplicated, toast: true, hint: false);
  }

  void setBatchRepeat(String id, int repeat) {
    if (repeat <= 0) {
      _notify(
        SocketNoticeKind.repeatInvalid,
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
      SocketNoticeKind.ruleToggled,
      args: {'name': rule.name, 'enabled': enabled},
    );
  }

  Future<void> fireRule(String id) async {
    final rule = _byId(state.rules, id);
    if (rule == null) return;
    if (!state.open) {
      _notify(SocketNoticeKind.closedRule, toast: true, warn: true);
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
    _notify(SocketNoticeKind.ruleSaved, toast: true, hint: false);
  }

  void deleteRule(String id) {
    _emit(
      state.copyWith(
        rules: state.rules.where((item) => item.id != id).toList(),
      ),
    );
    _persist();
    _notify(SocketNoticeKind.deleted, toast: true, hint: false);
  }

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
    _notify(SocketNoticeKind.duplicated, toast: true, hint: false);
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
    _notify(SocketNoticeKind.deleted, toast: true, hint: false);
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
      SocketNoticeKind.scriptToggled,
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

  void toggleLesson(String key) {
    _emit(state.copyWith(openLesson: state.openLesson == key ? null : key));
  }

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
      SocketNoticeKind.lessonCreated,
      args: {'lesson': lesson.key, 'name': script.name},
    );
  }

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
    _notify(SocketNoticeKind.lessonTried);
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

  bool importScriptFromMcp({
    required String name,
    required String code,
    required bool enabled,
  }) {
    if (state.scripts.any((s) => s.name == name)) return false;
    final script = _addScript(name, code);
    if (enabled) {
      _replaceScript(script.id, (item) => item.copyWith(enabled: true));
    }
    return true;
  }

  bool importReplyFromMcp(ReplyRule rule) {
    if (state.rules.any((r) => r.name == rule.name)) return false;
    upsertRule(rule);
    return true;
  }

  bool importQuickFromMcp({
    required String name,
    required String data,
    required DataFormat format,
    required bool enabled,
  }) {
    if (hasQuickNamed(name)) return false;
    upsertQuick(
      QuickCommand(
        id: _freshId('q', {for (final c in state.quick.commands) c.id}),
        name: name,
        data: data,
        format: format,
        enabled: enabled,
      ),
    );
    return true;
  }

  bool hasScriptNamed(String name) => state.scripts.any((s) => s.name == name);

  bool hasReplyNamed(String name) => state.rules.any((r) => r.name == name);

  bool hasQuickNamed(String name) =>
      state.quick.commands.any((c) => c.name == name);

  bool setScriptEnabledByName(String name, bool enabled) {
    for (final script in state.scripts) {
      if (script.name != name) continue;
      if (script.enabled != enabled) {
        _replaceScript(script.id, (item) => item.copyWith(enabled: enabled));
      }
      return true;
    }
    return false;
  }

  bool setReplyEnabledByName(String name, bool enabled) {
    for (final rule in state.rules) {
      if (rule.name != name) continue;
      if (rule.enabled != enabled) {
        _replaceRule(rule.id, (item) => item.copyWith(enabled: enabled));
      }
      return true;
    }
    return false;
  }

  bool setQuickEnabledByName(String name, bool enabled) {
    final hits = state.quick.commands.where((c) => c.name == name);
    if (hits.isEmpty) return false;
    final hit = hits.first;
    if (hit.enabled != enabled) {
      _replaceQuick(hit.copyWith(enabled: enabled));
    }
    return true;
  }

  Future<bool> sendFromMcp(String text, {DataFormat format = DataFormat.hex}) {
    return _transmit(text, format: format, recordHistory: true);
  }

  List<Map<String, String>> mcpLogSnapshot() {
    return [
      for (final line in state.lines)
        {
          'time': fullStamp(line.time),
          'dir': line.dir.name,
          'body': line.dir == LogDir.sys
              ? '${line.sys?.name ?? ''}${line.args.isEmpty ? '' : ' ${line.args}'}'
              : (line.bytes == null ? '' : SerialBytes.toHex(line.bytes!)),
        },
    ];
  }

  void noteMcpRejected(String detail) {
    _sys(SysLogKind.mcpRejected, {'detail': detail});
  }

  void renameScript(String id, String name) {
    final value = name.trim();
    if (value.isEmpty) return;
    _replaceScript(id, (item) => item.copyWith(name: value));
    _notify(SocketNoticeKind.scriptSaved, toast: true, hint: false);
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
    _notify(SocketNoticeKind.deleted, toast: true, hint: false);
  }

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
    _notify(SocketNoticeKind.duplicated, toast: true, hint: false);
  }

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

  void _onIncoming(SocketIncoming message) {
    if (!state.open || isClosed) return;
    if (state.isUdp) {
      _onPacket(message.bytes, peerAddress: message.peerAddress);
      return;
    }
    if (state.isTcpServer) {
      final peerId = message.peerId;
      if (peerId == null) return;
      _peerAssembler(peerId).add(
        message.bytes,
        state.packetTimeoutMs,
        (bytes) => _onPacket(
          bytes,
          peerId: peerId,
          peerAddress: message.peerAddress,
        ),
      );
      return;
    }
    _assembler.add(message.bytes, state.packetTimeoutMs, (bytes) {
      _onPacket(bytes, peerAddress: message.peerAddress);
    });
  }

  void _onPeers(List<SocketPeer> peers) {
    if (isClosed) return;
    final old = {for (final p in state.peers) p.id: p};
    final nextIds = peers.map((p) => p.id).toSet();
    for (final id in old.keys) {
      if (!nextIds.contains(id)) {
        _peerAssemblers.remove(id)?.dispose();
        if (state.open) {
          _notify(
            SocketNoticeKind.peerLeft,
            args: {'address': old[id]?.address ?? id},
          );
        }
      }
    }
    for (final peer in peers) {
      if (!old.containsKey(peer.id) && state.open) {
        _notify(
          SocketNoticeKind.peerJoined,
          args: {'address': peer.address},
        );
      }
    }
    var selected = state.selectedPeerId;
    if (selected != null && !nextIds.contains(selected)) {
      selected = null;
    }
    _emit(state.copyWith(peers: peers, selectedPeerId: selected));
  }

  void _onOpenState(bool open) {
    if (!open && state.open && !_closing) {
      unawaited(_shutdown(remote: true));
    }
  }

  void _onGatewayError(String message) {
    AppLogger.i.error(
      'Socket 传输错误',
      category: LogCategory.device,
      error: message,
    );
    if (!state.open || _closing) return;
    unawaited(() async {
      await _shutdown(remote: true);
      _notify(
        SocketNoticeKind.openFailed,
        toast: true,
        warn: true,
        hint: false,
        args: {'detail': message},
      );
    }());
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    AppLogger.i.error(
      'Socket 数据流中断',
      category: LogCategory.device,
      error: error,
      stackTrace: stackTrace,
    );
    if (!state.open || _closing) return;
    unawaited(() async {
      await _shutdown(remote: true);
      _notify(
        SocketNoticeKind.openFailed,
        toast: true,
        warn: true,
        hint: false,
        args: {'detail': '$error'},
      );
    }());
  }

  Future<void> _startLoop(String text, DataFormat format) async {
    final period = state.loopPeriodMs;
    if (period < SerialMetrics.minLoopMs) {
      _notify(
        SocketNoticeKind.periodInvalid,
        toast: true,
        warn: true,
        hint: false,
      );
      return;
    }
    if (!await _transmit(text, format: format, recordHistory: true)) return;
    _loop?.cancel();
    _emit(state.copyWith(looping: true));
    _notify(SocketNoticeKind.loopStarted, args: {'period': period});
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
    if (notify && was) _notify(SocketNoticeKind.loopStopped);
  }

  void _stopBatch({required bool notify}) {
    final was = _batchTimer != null || state.batchRun != null;
    _batchToken++;
    _batchTimer?.cancel();
    _batchTimer = null;
    if (state.batchRun != null) _emit(state.copyWith(batchRun: null));
    if (notify && was) {
      _sys(SysLogKind.batchStopped, const {});
      _notify(SocketNoticeKind.batchEnded);
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
    String? peerId,
    String? udpHost,
    int? udpPort,
  }) async {
    if (!state.open) {
      _notify(SocketNoticeKind.closedSend, toast: true, warn: true);
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
      _notify(SocketNoticeKind.badHex, toast: true, warn: true);
      return false;
    }
    final raw = encoded.bytes;
    if (encoded.error == EncodeError.empty || raw == null || raw.isEmpty) {
      _notify(SocketNoticeKind.emptySend, toast: true, warn: true);
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
    final txPeer = _txPeerLabel(peerId);
    try {
      if (state.isUdp) {
        final host = (udpHost ?? state.remoteHost).trim();
        final port = udpPort ?? state.remotePort;
        if (host.isEmpty || !_validPort(port)) {
          _notify(SocketNoticeKind.noRemote, toast: true, warn: true);
          return false;
        }
        await _repo.writeUdp(bytes, host: host, port: port);
      } else {
        final target = peerId ?? state.selectedPeerId;
        if (state.isTcpServer &&
            target == null &&
            _repo.currentPeers.isEmpty) {
          _notify(SocketNoticeKind.noClient, toast: true, warn: true);
          return false;
        }
        await _repo.write(bytes, peerId: target);
      }
    } on AppException catch (error, stackTrace) {
      _logIo('发送失败', error, stackTrace);
      return false;
    }
    if (recordHistory) _remember(text);
    _push(dir: LogDir.tx, bytes: bytes, peer: txPeer);
    return true;
  }

  void _onPacket(
    Uint8List bytes, {
    String? peerId,
    String? peerAddress,
  }) {
    if (isClosed) return;
    _lastRx = bytes;
    _push(dir: LogDir.rx, bytes: bytes, peer: peerAddress);
    _receiveHooks(bytes);
    _matchRules(bytes, peerId: peerId, peerAddress: peerAddress);
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

  void _matchRules(
    Uint8List bytes, {
    String? peerId,
    String? peerAddress,
  }) {
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
      _scheduleReplies(
        rule,
        captures,
        peerId: peerId,
        peerAddress: peerAddress,
      );
    }
  }

  void _scheduleReplies(
    ReplyRule rule,
    List<Uint8List?> captures, {
    String? peerId,
    String? peerAddress,
  }) {
    final udp = _parsePeerAddress(peerAddress);
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
            peerId: peerId,
            udpHost: udp?.host,
            udpPort: udp?.port,
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

  Future<void> _shutdown({bool remote = false}) async {
    if (_closing) return;
    _closing = true;
    try {
      _stopLoop(notify: false);
      _stopBatch(notify: false);
      _cancelReplies();
      _flushAssemblers();
      await _repo.closeTransport();
      if (isClosed) return;
      _emit(
        state.copyWith(
          open: false,
          busy: false,
          looping: false,
          batchRun: null,
          peers: const [],
          selectedPeerId: null,
        ),
      );
      if (!remote) {
        _sys(SysLogKind.closed, {'endpoint': state.endpoint});
        _notify(SocketNoticeKind.closed);
      }
    } finally {
      _closing = false;
    }
  }

  void _flushAssemblers() {
    if (state.isTcpServer) {
      for (final entry in _peerAssemblers.entries) {
        final peerId = entry.key;
        final peer = state.peers
            .where((p) => p.id == peerId)
            .map((p) => p.address)
            .firstOrNull;
        entry.value.flush(
          (bytes) => _onPacket(
            bytes,
            peerId: peerId,
            peerAddress: peer,
          ),
        );
      }
      return;
    }
    if (state.isTcp) {
      _assembler.flush(
        (bytes) => _onPacket(bytes),
      );
    }
  }

  PacketAssembler _peerAssembler(String peerId) =>
      _peerAssemblers.putIfAbsent(peerId, PacketAssembler.new);

  void _disposeAssemblers() {
    _assembler.dispose();
    for (final assembler in _peerAssemblers.values) {
      assembler.dispose();
    }
    _peerAssemblers.clear();
  }

  void _push({
    required LogDir dir,
    Uint8List? bytes,
    SysLogKind? sys,
    Map<String, Object> args = const {},
    String? peer,
  }) {
    final line = SocketLogLine(
      no: ++_seq,
      time: DateTime.now(),
      dir: dir,
      bytes: bytes,
      sys: sys,
      args: args,
      peer: peer,
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
        final peerTag = peer == null ? '' : ' [$peer]';
        _saveBuf.add(
          '[${fullStamp(line.time)}]$peerTag ${SerialBytes.toHex(bytes)}',
        );
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

  String _logDump() {
    final buffer = StringBuffer();
    for (final line in state.lines) {
      final stamp = clockStamp(line.time);
      if (line.dir == LogDir.sys) {
        buffer.writeln('[$stamp] SYS  ${line.sys?.name ?? ''}');
      } else {
        final tag = line.dir == LogDir.rx ? 'RX' : 'TX';
        final peer = line.peer == null ? '' : ' ${line.peer}';
        buffer.writeln(
          '[$stamp] $tag$peer ${SerialBytes.toHex(line.bytes ?? const [])}',
        );
      }
    }
    return buffer.toString();
  }

  SocketConsoleState _applyWorkspace(SocketWorkspace ws) {
    return state.copyWith(
      role: _protocol == SocketProtocol.udp ? state.role : ws.role,
      host: ws.host,
      port: ws.port,
      remoteHost: ws.remoteHost,
      remotePort: ws.remotePort,
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
    SocketNoticeKind kind, {
    bool toast = false,
    bool warn = false,
    bool hint = true,
    Map<String, Object> args = const {},
  }) {
    final notice = SocketNotice(
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

  void _emit(SocketConsoleState next) {
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
      SocketNoticeKind.openFailed,
      toast: true,
      warn: true,
      hint: false,
      args: {'detail': error.message},
    );
  }

  bool _validPort(int port) => port > 0 && port <= 65535;

  bool _validHost(String host) => host.trim().isNotEmpty;

  String? _txPeerLabel(String? peerId) {
    if (!state.isTcpServer) return null;
    final id = peerId ?? state.selectedPeerId;
    if (id == null) return 'ALL';
    for (final peer in state.peers) {
      if (peer.id == id) return peer.address;
    }
    return id;
  }

  ({String host, int port})? _parsePeerAddress(String? address) {
    if (address == null || address.isEmpty) return null;
    final index = address.lastIndexOf(':');
    if (index <= 0) return null;
    final host = address.substring(0, index);
    final port = int.tryParse(address.substring(index + 1));
    if (port == null || !_validPort(port)) return null;
    return (host: host, port: port);
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
