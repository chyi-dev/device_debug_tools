import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/utils/debounce.dart';
import '../../serial/data/serial_stamp.dart';
import '../../serial/model/serial_models.dart';
import '../../serial/serial_metrics.dart';
import '../data/mqtt_lua_engine.dart';
import '../model/mqtt_models.dart';
import '../model/mqtt_script_lessons.dart';
import '../repository/mqtt_console_repository.dart';
import 'mqtt_console_state.dart';

class MqttConsoleCubit extends Cubit<MqttConsoleState> {
  MqttConsoleCubit({required MqttConsoleRepository repository})
    : _repo = repository,
      super(MqttConsoleState.initial());

  final MqttConsoleRepository _repo;
  final MqttLuaEngine _engine = MqttLuaEngine();
  final Debouncer _persistDebounce = Debouncer(
    duration: const Duration(milliseconds: 400),
  );
  final Debouncer _scriptDebounce = Debouncer(
    duration: const Duration(milliseconds: 300),
  );
  final Map<String, String> _brokenLogged = {};
  MqttScriptMessage? _lastRx;
  StreamSubscription<MqttIncoming>? _msgSub;
  StreamSubscription<bool>? _connSub;
  int _seq = 0;
  int _notice = 0;
  var _wasConnected = false;

  Future<void> start() async {
    final saved = _repo.load();
    if (saved != null) emit(_apply(saved));
    _inspectScripts();
    _msgSub ??= _repo.messages.listen(_onMessage);
    _connSub ??= _repo.connections.listen(_onConnection);
  }

  @override
  Future<void> close() async {
    _persistDebounce.dispose();
    _scriptDebounce.dispose();
    _engine.dispose();
    await _msgSub?.cancel();
    await _connSub?.cancel();
    try {
      await _repo.save(state.toWorkspace());
    } catch (error, stackTrace) {
      AppLogger.i.error(
        '保存 MQTT 工作区失败',
        category: LogCategory.database,
        error: error,
        stackTrace: stackTrace,
      );
    }
    await _repo.close();
    return super.close();
  }

  void patch({
    String? host,
    String? port,
    MqttVersion? version,
    String? clientId,
    String? username,
    String? password,
    MqttScheme? scheme,
    String? wsPath,
    String? caFile,
    String? clientCert,
    String? clientKey,
    String? keepAlive,
    bool? cleanStart,
    String? sessionExpiry,
    bool? autoReconnect,
    String? willTopic,
    String? willPayload,
    int? willQos,
    bool? willRetain,
    String? pubTopic,
    int? pubQos,
    bool? pubRetain,
    String? payload,
    String? draftSubTopic,
    int? draftSubQos,
    String? draftPubName,
    String? draftPubTopic,
    bool? settingsOpen,
    bool? compact,
    bool? toolsVisible,
  }) {
    int? parsedPort;
    if (port != null) {
      parsedPort = int.tryParse(port.trim());
      if (parsedPort == null || parsedPort < 1 || parsedPort > 65535) {
        _notify(MqttNoticeKind.portInvalid, toast: true, warn: true);
        return;
      }
    }
    int? parsedKeep;
    if (keepAlive != null) {
      parsedKeep = int.tryParse(keepAlive.trim());
      if (parsedKeep == null || parsedKeep <= 0) {
        _notify(MqttNoticeKind.keepAliveInvalid, toast: true, warn: true);
        return;
      }
    }
    final nextScheme = scheme ?? state.scheme;
    final switched = scheme != null && scheme != state.scheme;
    final nextPort =
        parsedPort ??
        (switched && state.port == state.scheme.defaultPort
            ? nextScheme.defaultPort
            : null);
    emit(
      state.copyWith(
        host: host,
        port: nextPort,
        version: version,
        clientId: clientId,
        username: username,
        password: password,
        scheme: scheme,
        wsPath: wsPath == null ? null : _storedWsPath(wsPath),
        caFile: caFile,
        clientCert: clientCert,
        clientKey: clientKey,
        keepAlive: parsedKeep,
        cleanStart: cleanStart,
        sessionExpiry: sessionExpiry == null
            ? null
            : int.tryParse(sessionExpiry.trim()) ?? state.sessionExpiry,
        autoReconnect: autoReconnect,
        willTopic: willTopic,
        willPayload: willPayload,
        willQos: willQos,
        willRetain: willRetain,
        pubTopic: pubTopic,
        pubQos: pubQos,
        pubRetain: pubRetain,
        payload: payload,
        draftSubTopic: draftSubTopic,
        draftSubQos: draftSubQos,
        draftPubName: draftPubName,
        draftPubTopic: draftPubTopic,
        settingsOpen: settingsOpen,
        compact: compact,
        toolsVisible: toolsVisible,
      ),
    );
    _persist();
  }

  Future<void> pickCa() async {
    final path = await _repo.pickPath(extensions: const ['pem', 'crt', 'cer']);
    if (path != null) patch(caFile: path);
  }

  Future<void> pickCert() async {
    final path = await _repo.pickPath(extensions: const ['pem', 'crt', 'cer']);
    if (path != null) patch(clientCert: path);
  }

  Future<void> pickKey() async {
    final path = await _repo.pickPath(extensions: const ['pem', 'key']);
    if (path != null) patch(clientKey: path);
  }

  Future<void> toggleConnect() async {
    if (state.connecting) return;
    if (state.connected) {
      await _repo.disconnect();
      emit(state.copyWith(connected: false, connecting: false));
      _sys('已断开');
      _notify(MqttNoticeKind.disconnected, toast: true);
      return;
    }
    emit(state.copyWith(connecting: true));
    try {
      await _repo.connect(state.toWorkspace().link);
      if (isClosed) return;
      await _resubscribe();
      emit(state.copyWith(connecting: false, connected: true));
      _sys('已连接 ${state.endpoint}，Client ID ${state.clientId}');
      _notify(
        MqttNoticeKind.connected,
        toast: true,
        args: {'host': state.host, 'port': state.port, 'id': state.clientId},
      );
    } on AppException catch (error, stackTrace) {
      _logIo('MQTT 连接失败', error, stackTrace);
      if (isClosed) return;
      emit(state.copyWith(connecting: false, connected: false));
      _notify(
        MqttNoticeKind.connectFailed,
        toast: true,
        warn: true,
        args: {'detail': error.message},
      );
    } catch (error, stackTrace) {
      _logIo('MQTT 连接失败', error, stackTrace);
      if (isClosed) return;
      emit(state.copyWith(connecting: false, connected: false));
      _notify(
        MqttNoticeKind.connectFailed,
        toast: true,
        warn: true,
        args: {'detail': '$error'},
      );
    }
  }

  Future<void> subscribe({String? topic, int? qos}) async {
    if (!state.connected) {
      _notify(MqttNoticeKind.closedSubscribe, toast: true, warn: true);
      return;
    }
    final nextTopic = (topic ?? state.draftSubTopic).trim();
    final nextQos = (qos ?? state.draftSubQos).clamp(0, 2);
    if (nextTopic.isEmpty) {
      _notify(MqttNoticeKind.needTopic, toast: true, warn: true);
      return;
    }
    if (state.subs.any((item) => item.topic == nextTopic)) {
      _notify(MqttNoticeKind.dupTopic, toast: true, warn: true);
      return;
    }
    try {
      await _repo.subscribe(nextTopic, nextQos);
    } on AppException catch (error, stackTrace) {
      _logIo('MQTT 订阅失败', error, stackTrace);
      return;
    }
    final item = MqttSubscription(
      id: newSerialId('s'),
      topic: nextTopic,
      qos: nextQos,
    );
    emit(state.copyWith(subs: [...state.subs, item], draftSubTopic: ''));
    _persist();
    _sys('已订阅 $nextTopic · QoS ${item.qos}');
    _notify(
      MqttNoticeKind.subscribed,
      toast: true,
      args: {'topic': nextTopic, 'qos': item.qos},
    );
  }

  Future<void> toggleSubscription(String id) async {
    final item = _subscription(id);
    if (item == null) return;
    if (item.subscribed) {
      if (state.connected) {
        try {
          await _repo.unsubscribe(item.topic);
        } on AppException catch (error, stackTrace) {
          _logIo('MQTT 退订失败', error, stackTrace);
          return;
        }
      }
      _replaceSubscription(id, item.copyWith(subscribed: false));
      _notify(
        MqttNoticeKind.unsubscribed,
        toast: true,
        args: {'topic': item.topic},
      );
      return;
    }
    if (!state.connected) {
      _notify(MqttNoticeKind.closedSubscribe, toast: true, warn: true);
      return;
    }
    try {
      await _repo.subscribe(item.topic, item.qos);
    } on AppException catch (error, stackTrace) {
      _logIo('MQTT 订阅失败', error, stackTrace);
      return;
    }
    _replaceSubscription(id, item.copyWith(subscribed: true));
    _sys('已订阅 ${item.topic} · QoS ${item.qos}');
    _notify(
      MqttNoticeKind.subscribed,
      toast: true,
      args: {'topic': item.topic, 'qos': item.qos},
    );
  }

  Future<void> updateSubscription(
    String id, {
    required String topic,
    required int qos,
  }) async {
    final item = _subscription(id);
    if (item == null) return;
    final nextTopic = topic.trim();
    final nextQos = qos.clamp(0, 2);
    if (nextTopic.isEmpty) {
      _notify(MqttNoticeKind.needTopic, toast: true, warn: true);
      return;
    }
    if (state.subs.any((other) => other.id != id && other.topic == nextTopic)) {
      _notify(MqttNoticeKind.dupTopic, toast: true, warn: true);
      return;
    }
    final changed = item.topic != nextTopic || item.qos != nextQos;
    if (item.subscribed && state.connected && changed) {
      try {
        await _repo.unsubscribe(item.topic);
        await _repo.subscribe(nextTopic, nextQos);
      } on AppException catch (error, stackTrace) {
        _logIo('MQTT 修改订阅失败', error, stackTrace);
        try {
          await _repo.subscribe(item.topic, item.qos);
        } on AppException catch (restoreError, restoreStack) {
          _logIo('MQTT 恢复原订阅失败', restoreError, restoreStack);
        }
        return;
      }
    }
    _replaceSubscription(id, item.copyWith(topic: nextTopic, qos: nextQos));
  }

  Future<void> deleteSubscription(String id) async {
    final item = _subscription(id);
    if (item == null) return;
    if (item.subscribed && state.connected) {
      try {
        await _repo.unsubscribe(item.topic);
      } on AppException catch (error, stackTrace) {
        _logIo('MQTT 退订失败', error, stackTrace);
      }
    }
    emit(
      state.copyWith(
        subs: [
          for (final current in state.subs)
            if (current.id != id) current,
        ],
      ),
    );
    _persist();
    _notify(MqttNoticeKind.deleted, toast: true);
  }

  MqttSubscription? _subscription(String id) {
    for (final item in state.subs) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _replaceSubscription(String id, MqttSubscription next) {
    emit(
      state.copyWith(
        subs: [
          for (final item in state.subs)
            if (item.id == id) next else item,
        ],
      ),
    );
    _persist();
  }

  void addPublishTopic({String? name, String? topic}) {
    final nextName = (name ?? state.draftPubName).trim();
    final nextTopic = (topic ?? state.draftPubTopic).trim();
    if (nextName.isEmpty || nextTopic.isEmpty) {
      _notify(MqttNoticeKind.needName, toast: true, warn: true);
      return;
    }
    emit(
      state.copyWith(
        pubTopics: [
          ...state.pubTopics,
          MqttPublishTopic(
            id: newSerialId('t'),
            name: nextName,
            topic: nextTopic,
          ),
        ],
        draftPubName: '',
        draftPubTopic: '',
      ),
    );
    _persist();
  }

  void fillTopic(String id) {
    for (final item in state.pubTopics) {
      if (item.id == id) {
        emit(state.copyWith(pubTopic: item.topic));
        _persist();
        _notify(
          MqttNoticeKind.filled,
          toast: true,
          args: {'topic': item.topic},
        );
        return;
      }
    }
  }

  void deletePublishTopic(String id) {
    emit(
      state.copyWith(
        pubTopics: [
          for (final item in state.pubTopics)
            if (item.id != id) item,
        ],
      ),
    );
    _persist();
    _notify(MqttNoticeKind.deleted, toast: true);
  }

  Future<void> publish() async {
    await _publish(
      topic: state.pubTopic,
      payload: state.payload,
      qos: state.pubQos,
      retain: state.pubRetain,
      recordHistory: true,
    );
  }

  Future<void> publishQuick(String id) async {
    for (final item in state.quick) {
      if (item.id == id) {
        await _publish(
          topic: item.inherit ? state.pubTopic : item.topic,
          payload: item.data,
          qos: item.inherit ? state.pubQos : item.qos,
          retain: item.inherit ? state.pubRetain : item.retain,
        );
        return;
      }
    }
  }

  void sendQuickByKey(String key) {
    for (final item in state.quick) {
      if (item.key == key) {
        unawaited(publishQuick(item.id));
        return;
      }
    }
  }

  void saveQuick(MqttQuickCommand command) {
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
    _notify(MqttNoticeKind.quickSaved, toast: true);
  }

  void deleteQuick(String id) {
    emit(
      state.copyWith(
        quick: [
          for (final item in state.quick)
            if (item.id != id) item,
        ],
      ),
    );
    _persist();
    _notify(MqttNoticeKind.deleted, toast: true);
  }

  void duplicateQuick(String id) {
    final index = state.quick.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final source = state.quick[index];
    final copy = MqttQuickCommand(
      id: newSerialId('q'),
      name: _copyQuickName(source.name),
      data: source.data,
      inherit: source.inherit,
      topic: source.topic,
      qos: source.qos,
      retain: source.retain,
    );
    final quick = [...state.quick]..insert(index + 1, copy);
    emit(state.copyWith(quick: quick));
    _persist();
  }

  Future<void> resendHistory(int index) async {
    if (index < 0 || index >= state.history.length) return;
    final item = state.history[index];
    await _publish(
      topic: item.topic,
      payload: item.payload,
      qos: item.qos,
      retain: item.retain,
      recordHistory: true,
    );
  }

  void fillHistory(int index) {
    if (index < 0 || index >= state.history.length) return;
    final item = state.history[index];
    emit(
      state.copyWith(
        pubTopic: item.topic,
        payload: item.payload,
        pubQos: item.qos,
        pubRetain: item.retain,
      ),
    );
    _persist();
  }

  void removeHistory(int index) {
    if (index < 0 || index >= state.history.length) return;
    final history = [...state.history]..removeAt(index);
    emit(state.copyWith(history: history));
    _persist();
  }

  void clearHistory() {
    emit(state.copyWith(history: const []));
    _persist();
    _notify(MqttNoticeKind.deleted, toast: true);
  }

  void clearLog() {
    emit(state.copyWith(lines: const [], rxCount: 0, txCount: 0));
    _notify(MqttNoticeKind.cleared, toast: true);
  }

  void resetCounters() {
    emit(state.copyWith(rxCount: 0, txCount: 0));
  }

  Future<void> saveLog() async {
    final path = await _repo.pickSave(
      suggestedName: 'mqtt_${fileStamp(DateTime.now())}.txt',
      extension: 'txt',
    );
    if (path == null) return;
    final buffer = StringBuffer();
    for (final line in state.lines) {
      if (line.dir == MqttDir.sys) {
        buffer.writeln('[${fullStamp(line.time)}]# ${line.payload}');
      } else {
        final tag = line.dir == MqttDir.rx ? 'RECV' : 'PUB';
        buffer.writeln(
          '[${fullStamp(line.time)}]# $tag [${line.topic}] QoS${line.qos}${line.retain ? ' RETAIN' : ''}>',
        );
        buffer.writeln(line.payload);
      }
    }
    await _repo.writeText(path: path, text: buffer.toString());
    _notify(MqttNoticeKind.logSaved, toast: true);
  }

  Future<void> _publish({
    required String topic,
    required String payload,
    required int qos,
    required bool retain,
    bool recordHistory = false,
  }) async {
    if (!state.connected) {
      _notify(MqttNoticeKind.closedPublish, toast: true, warn: true);
      return;
    }
    final hooked = _publishHooks(
      MqttScriptMessage(
        topic: topic.trim(),
        payload: payload,
        qos: qos,
        retain: retain,
      ),
    );
    final message = hooked.message;
    if (message == null) {
      _sys(
        hooked.failed ? '脚本「${hooked.by}」出错，发布已取消' : '脚本「${hooked.by}」拦截了发布',
      );
      return;
    }
    final nextTopic = message.topic.trim();
    if (nextTopic.isEmpty) {
      _notify(MqttNoticeKind.needPubTopic, toast: true, warn: true);
      return;
    }
    if (message.payload.isEmpty) {
      _notify(MqttNoticeKind.emptyPayload, toast: true, warn: true);
      return;
    }
    try {
      await _repo.publish(
        topic: nextTopic,
        payload: message.payload,
        qos: message.qos,
        retain: message.retain,
      );
    } on AppException catch (error, stackTrace) {
      _logIo('MQTT 发布失败', error, stackTrace);
      return;
    }
    _push(
      dir: MqttDir.tx,
      topic: nextTopic,
      qos: message.qos,
      retain: message.retain,
      payload: message.payload,
    );
    if (recordHistory) {
      _remember(
        MqttHistoryEntry(
          topic: nextTopic,
          payload: message.payload,
          qos: message.qos,
          retain: message.retain,
          time: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _resubscribe() async {
    for (final item in state.subs.where((item) => item.subscribed)) {
      try {
        await _repo.subscribe(item.topic, item.qos);
      } on AppException catch (error, stackTrace) {
        _logIo('MQTT 重订阅失败', error, stackTrace);
      }
    }
  }

  void _onMessage(MqttIncoming incoming) {
    final message = MqttScriptMessage(
      topic: incoming.topic,
      payload: incoming.payload,
      qos: incoming.qos,
      retain: incoming.retain,
    );
    _lastRx = message;
    _push(
      dir: MqttDir.rx,
      topic: incoming.topic,
      qos: incoming.qos,
      retain: incoming.retain,
      payload: incoming.payload,
    );
    _messageHooks(message);
  }

  void _onConnection(bool connected) {
    if (isClosed) return;
    if (connected && _wasConnected == false && state.connected) {
      unawaited(_resubscribe());
    }
    _wasConnected = connected;
    if (!connected && state.connected) {
      emit(state.copyWith(connected: false, connecting: false));
      _sys('已断开');
    } else if (connected && !state.connected) {
      emit(state.copyWith(connected: true, connecting: false));
      unawaited(_resubscribe());
    }
  }

  void setTab(MqttToolTab tab) {
    if (state.toolTab == tab) return;
    emit(state.copyWith(toolTab: tab));
    _persist();
  }

  void selectScript(String id) {
    emit(state.copyWith(selectedScriptId: id, scriptDock: true));
    _persist();
  }

  void setScriptDock(bool on) {
    if (state.scriptDock == on) return;
    emit(state.copyWith(scriptDock: on));
    _persist();
  }

  void toggleScript(String id) {
    final script = _scriptById(id);
    if (script == null) return;
    _replaceScript(id, (item) => item.copyWith(enabled: !script.enabled));
  }

  void newScript() => _addScript(_nextScriptName(), _scriptTemplate);

  void setScriptTutorial(bool on) {
    if (state.scriptTutorial == on) return;
    emit(state.copyWith(scriptTutorial: on));
  }

  void toggleLesson(String key) {
    emit(state.copyWith(openLesson: state.openLesson == key ? null : key));
  }

  void newScriptFromLesson(MqttScriptLesson lesson) {
    final names = state.scripts.map((item) => item.name).toSet();
    final stem = lesson.fileName.replaceFirst(RegExp(r'\.lua$'), '');
    var name = lesson.fileName;
    for (var n = 2; names.contains(name); n++) {
      name = '${stem}_$n.lua';
    }
    _addScript(name, lesson.code);
    emit(state.copyWith(scriptTutorial: false, toolTab: MqttToolTab.script));
  }

  /// 把这课的样例消息交给代码，输出写进运行日志，不发布。
  void tryLesson(MqttScriptLesson lesson) {
    final probe = LuaScript(
      id: 'lesson:${lesson.key}',
      name: lesson.fileName,
      code: lesson.code,
      enabled: false,
    );
    final out = lesson.hook == MqttScriptHook.onMessage
        ? _engine.onMessage(probe.id, probe.code, lesson.sample)
        : _engine.beforePublish(probe.id, probe.code, lesson.sample);
    _engine.forget(probe.id);
    _scriptLogs(probe, [
      _entry(
        probe,
        MqttScriptLogKind.lessonTry,
        text: lesson.hookName,
        from: lesson.sample.label,
      ),
      ..._outcomeEntries(probe, out),
      if (lesson.hook == MqttScriptHook.beforePublish && out.error == null)
        _dryEntry(probe, lesson.sample, out.message),
    ]);
    emit(state.copyWith(scriptDock: true, toolTab: MqttToolTab.script));
  }

  void renameScript(String id, String name) {
    final value = name.trim();
    if (value.isEmpty) return;
    _replaceScript(id, (item) => item.copyWith(name: value));
  }

  void duplicateScript(String id) {
    final source = _scriptById(id);
    if (source == null) return;
    final copy = LuaScript(
      id: newSerialId('s'),
      name: _copyScriptName(source.name),
      code: source.code,
      enabled: false,
    );
    final scripts = [...state.scripts];
    final index = scripts.indexWhere((item) => item.id == id);
    scripts.insert(index < 0 ? scripts.length : index + 1, copy);
    emit(
      state.copyWith(
        scripts: scripts,
        selectedScriptId: copy.id,
        scriptDock: true,
        scriptMeta: {...state.scriptMeta, copy.id: _inspect(copy)},
      ),
    );
    _persist();
  }

  void deleteScript(String id) {
    _engine.forget(id);
    _brokenLogged.remove(id);
    final scripts = [
      for (final item in state.scripts)
        if (item.id != id) item,
    ];
    final selected = state.selectedScriptId == id
        ? (scripts.isEmpty ? null : scripts.first.id)
        : state.selectedScriptId;
    final meta = {...state.scriptMeta}..remove(id);
    emit(
      state.copyWith(
        scripts: scripts,
        selectedScriptId: selected,
        scriptDock: selected != null && state.scriptDock,
        scriptMeta: meta,
      ),
    );
    _persist();
  }

  void setScriptCode(String id, String code) {
    final script = _scriptById(id);
    if (script == null || script.code == code) return;
    _replaceScript(id, (item) => item.copyWith(code: code));
    _scriptDebounce.run(() {
      if (isClosed) return;
      final current = _scriptById(id);
      if (current == null) return;
      emit(
        state.copyWith(
          scriptMeta: {...state.scriptMeta, id: _inspect(current)},
        ),
      );
    });
  }

  void clearScriptLog() => emit(state.copyWith(scriptLog: const []));

  /// 手动运行。on_message 用最近一封；before_publish 用发布框试算，不发布。
  void runScript(String id) {
    final script = _scriptById(id);
    if (script == null) return;
    final meta = _inspect(script);
    emit(state.copyWith(scriptMeta: {...state.scriptMeta, id: meta}));
    final error = meta.error;
    if (error != null) {
      _scriptLogs(script, [
        _entry(script, MqttScriptLogKind.error, text: error),
      ]);
      return;
    }
    if (meta.hooks.isEmpty) {
      _scriptLogs(script, [_entry(script, MqttScriptLogKind.noHook)]);
      return;
    }
    if (meta.hooks.contains(MqttScriptHook.onMessage)) {
      final rx = _lastRx;
      if (rx == null) {
        _scriptLogs(script, [_entry(script, MqttScriptLogKind.noRx)]);
      } else {
        final out = _engine.onMessage(script.id, script.code, rx);
        _scriptLogs(script, [
          _entry(script, MqttScriptLogKind.manualRx, from: rx.label),
          ..._outcomeEntries(script, out),
        ]);
      }
    }
    if (meta.hooks.contains(MqttScriptHook.beforePublish)) {
      if (state.pubTopic.trim().isEmpty || state.payload.isEmpty) {
        _scriptLogs(script, [_entry(script, MqttScriptLogKind.badTx)]);
        return;
      }
      final sample = MqttScriptMessage(
        topic: state.pubTopic.trim(),
        payload: state.payload,
        qos: state.pubQos,
        retain: state.pubRetain,
      );
      final out = _engine.beforePublish(script.id, script.code, sample);
      _scriptLogs(script, [
        ..._outcomeEntries(script, out),
        if (out.error == null) _dryEntry(script, sample, out.message),
      ]);
    }
  }

  void _push({
    required MqttDir dir,
    String topic = '',
    int qos = 0,
    bool retain = false,
    required String payload,
  }) {
    final lines = [...state.lines];
    lines.add(
      MqttLogLine(
        no: ++_seq,
        time: DateTime.now(),
        dir: dir,
        topic: topic,
        qos: qos,
        retain: retain,
        payload: payload,
      ),
    );
    if (lines.length > SerialMetrics.logLimit) {
      lines.removeRange(0, lines.length - SerialMetrics.logLimit);
    }
    var rx = state.rxCount;
    var tx = state.txCount;
    final n = utf8.encode(payload).length;
    if (dir == MqttDir.rx) rx += n;
    if (dir == MqttDir.tx) tx += n;
    emit(state.copyWith(lines: lines, rxCount: rx, txCount: tx));
  }

  void _sys(String text) => _push(dir: MqttDir.sys, payload: text);

  void _messageHooks(MqttScriptMessage message) {
    for (final script in state.scripts) {
      if (!script.enabled || !_compiles(script)) continue;
      if (!_engine
          .inspect(script.id, script.code)
          .hooks
          .contains(MqttScriptHook.onMessage)) {
        continue;
      }
      final out = _engine.onMessage(script.id, script.code, message);
      final entries = _outcomeEntries(script, out);
      if (entries.isNotEmpty) _scriptLogs(script, entries);
    }
  }

  ({MqttScriptMessage? message, String by, bool failed}) _publishHooks(
    MqttScriptMessage message,
  ) {
    var current = message;
    for (final script in state.scripts) {
      if (!script.enabled || !_compiles(script)) continue;
      if (!_engine
          .inspect(script.id, script.code)
          .hooks
          .contains(MqttScriptHook.beforePublish)) {
        continue;
      }
      final out = _engine.beforePublish(script.id, script.code, current);
      final entries = _outcomeEntries(script, out);
      if (out.error != null) {
        _scriptLogs(script, entries);
        return (message: null, by: script.name, failed: true);
      }
      final next = out.message;
      if (next == null) {
        entries.add(
          _entry(script, MqttScriptLogKind.blocked, from: current.label),
        );
        _scriptLogs(script, entries);
        return (message: null, by: script.name, failed: false);
      }
      if (next.topic != current.topic ||
          next.payload != current.payload ||
          next.qos != current.qos ||
          next.retain != current.retain) {
        entries.add(
          _entry(
            script,
            MqttScriptLogKind.changed,
            from: current.label,
            to: next.label,
          ),
        );
      }
      if (entries.isNotEmpty) _scriptLogs(script, entries);
      current = next;
    }
    return (message: current, by: '', failed: false);
  }

  bool _compiles(LuaScript script) {
    final error = _engine.inspect(script.id, script.code).error;
    if (error == null) return true;
    if (_brokenLogged[script.id] != script.code) {
      _brokenLogged[script.id] = script.code;
      _scriptLogs(script, [
        _entry(script, MqttScriptLogKind.error, text: error),
      ]);
    }
    return false;
  }

  MqttScriptMeta _inspect(LuaScript script) {
    final info = _engine.inspect(script.id, script.code);
    return MqttScriptMeta(
      hooks: info.hooks,
      error: info.error,
      outputs: state.scriptMeta[script.id]?.outputs ?? 0,
    );
  }

  void _inspectScripts() {
    _engine.retain(state.scripts.map((item) => item.id));
    emit(
      state.copyWith(
        scriptMeta: {for (final item in state.scripts) item.id: _inspect(item)},
      ),
    );
  }

  LuaScript _addScript(String name, String code) {
    var id = newSerialId('s');
    while (state.scripts.any((item) => item.id == id)) {
      id = newSerialId('s');
    }
    final script = LuaScript(id: id, name: name, code: code, enabled: false);
    emit(
      state.copyWith(
        scripts: [...state.scripts, script],
        selectedScriptId: id,
        scriptDock: true,
        toolTab: MqttToolTab.script,
        scriptMeta: {...state.scriptMeta, id: _inspect(script)},
      ),
    );
    _persist();
    return script;
  }

  void _replaceScript(String id, LuaScript Function(LuaScript item) update) {
    emit(
      state.copyWith(
        scripts: [
          for (final item in state.scripts)
            if (item.id == id) update(item) else item,
        ],
      ),
    );
    _persist();
  }

  LuaScript? _scriptById(String id) {
    for (final item in state.scripts) {
      if (item.id == id) return item;
    }
    return null;
  }

  String _nextScriptName() {
    final names = state.scripts.map((item) => item.name).toSet();
    var n = state.scripts.length + 1;
    while (names.contains('script$n.lua')) {
      n++;
    }
    return 'script$n.lua';
  }

  void _remember(MqttHistoryEntry entry) {
    final history = [
      entry,
      ...state.history.where((item) => !item.sameAs(entry)),
    ].take(SerialMetrics.historyLimit).toList();
    emit(state.copyWith(history: history));
    _persist();
  }

  String _copyQuickName(String source) {
    final names = state.quick.map((item) => item.name).toSet();
    var name = '${source}_副本';
    if (!names.contains(name)) return name;
    for (var n = 2; ; n++) {
      name = '${source}_副本 $n';
      if (!names.contains(name)) return name;
    }
  }

  String _copyScriptName(String source) {
    final lua = source.toLowerCase().endsWith('.lua');
    final stem = lua ? source.substring(0, source.length - 4) : source;
    final ext = lua ? '.lua' : '';
    final names = state.scripts.map((item) => item.name).toSet();
    var name = '${stem}_副本$ext';
    if (!names.contains(name)) return name;
    for (var n = 2; ; n++) {
      name = '${stem}_副本 $n$ext';
      if (!names.contains(name)) return name;
    }
  }

  List<MqttScriptLogEntry> _outcomeEntries(
    LuaScript script,
    MqttScriptOutcome out,
  ) {
    final error = out.error;
    return [
      for (final text in out.logs)
        _entry(script, MqttScriptLogKind.output, text: text),
      if (error != null)
        out.tooLong
            ? _entry(script, MqttScriptLogKind.tooLong)
            : _entry(script, MqttScriptLogKind.error, text: error),
    ];
  }

  MqttScriptLogEntry _dryEntry(
    LuaScript script,
    MqttScriptMessage sample,
    MqttScriptMessage? next,
  ) => next == null
      ? _entry(script, MqttScriptLogKind.dryBlocked, from: sample.label)
      : _entry(
          script,
          MqttScriptLogKind.dryRun,
          from: sample.label,
          to: next.label,
        );

  MqttScriptLogEntry _entry(
    LuaScript script,
    MqttScriptLogKind kind, {
    String text = '',
    String from = '',
    String to = '',
  }) => MqttScriptLogEntry(
    time: DateTime.now(),
    name: script.name,
    kind: kind,
    text: text,
    from: from,
    to: to,
  );

  void _scriptLogs(LuaScript script, List<MqttScriptLogEntry> entries) {
    if (entries.isEmpty) return;
    final logs = [...state.scriptLog, ...entries];
    if (logs.length > SerialMetrics.scriptLogLimit) {
      logs.removeRange(0, logs.length - SerialMetrics.scriptLogLimit);
    }
    final meta = state.scriptMeta[script.id] ?? _inspect(script);
    final bumped = entries.any((item) => item.kind == MqttScriptLogKind.output);
    emit(
      state.copyWith(
        scriptLog: logs,
        scriptMeta: {
          ...state.scriptMeta,
          script.id: bumped ? meta.copyWith(outputs: meta.outputs + 1) : meta,
        },
      ),
    );
  }

  static const _scriptTemplate =
      'function on_message(msg)\n'
      '  log(msg.topic, msg.payload)\n'
      'end\n';

  MqttConsoleState _apply(MqttWorkspace ws) {
    return state.copyWith(
      host: ws.host,
      port: ws.port,
      version: ws.version,
      clientId: ws.clientId,
      username: ws.username,
      password: ws.password,
      scheme: ws.scheme,
      wsPath: ws.wsPath,
      caFile: ws.caFile,
      clientCert: ws.clientCert,
      clientKey: ws.clientKey,
      keepAlive: ws.keepAlive,
      cleanStart: ws.cleanStart,
      sessionExpiry: ws.sessionExpiry,
      autoReconnect: ws.autoReconnect,
      willTopic: ws.willTopic,
      willPayload: ws.willPayload,
      willQos: ws.willQos,
      willRetain: ws.willRetain,
      pubTopic: ws.pubTopic,
      pubQos: ws.pubQos,
      pubRetain: ws.pubRetain,
      payload: ws.payload,
      settingsOpen: ws.settingsOpen,
      compact: ws.compact,
      toolsVisible: ws.toolsVisible,
      subs: ws.subs,
      pubTopics: ws.pubTopics,
      quick: ws.quick,
      history: ws.history,
      scripts: ws.scripts,
      toolTab: ws.toolTab,
      selectedScriptId: ws.selectedScriptId,
      scriptDock: ws.scriptDock,
    );
  }

  String _storedWsPath(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '/') return '';
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  void _persist() {
    _persistDebounce.run(() {
      unawaited(_repo.save(state.toWorkspace()));
    });
  }

  void _notify(
    MqttNoticeKind kind, {
    bool toast = false,
    bool warn = false,
    Map<String, Object> args = const {},
  }) {
    final notice = MqttNotice(
      id: ++_notice,
      kind: kind,
      warn: warn,
      args: args,
    );
    emit(state.copyWith(hint: notice, toast: toast ? notice : state.toast));
  }

  void _logIo(String message, Object error, StackTrace stackTrace) {
    AppLogger.i.error(
      message,
      category: LogCategory.device,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
