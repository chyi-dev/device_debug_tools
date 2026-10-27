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
import '../model/mqtt_models.dart';
import '../repository/mqtt_console_repository.dart';
import 'mqtt_console_state.dart';

class MqttConsoleCubit extends Cubit<MqttConsoleState> {
  MqttConsoleCubit({required MqttConsoleRepository repository})
    : _repo = repository,
      super(MqttConsoleState.initial());

  final MqttConsoleRepository _repo;
  final Debouncer _persistDebounce = Debouncer(
    duration: const Duration(milliseconds: 400),
  );
  StreamSubscription<MqttIncoming>? _msgSub;
  StreamSubscription<bool>? _connSub;
  int _seq = 0;
  int _notice = 0;
  var _wasConnected = false;

  Future<void> start() async {
    final saved = _repo.load();
    if (saved != null) emit(_apply(saved));
    _msgSub ??= _repo.messages.listen(_onMessage);
    _connSub ??= _repo.connections.listen(_onConnection);
  }

  @override
  Future<void> close() async {
    _persistDebounce.dispose();
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
    final nextPort = parsedPort ??
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

  Future<void> subscribe() async {
    if (!state.connected) {
      _notify(MqttNoticeKind.closedSubscribe, toast: true, warn: true);
      return;
    }
    final topic = state.draftSubTopic.trim();
    if (topic.isEmpty) {
      _notify(MqttNoticeKind.needTopic, toast: true, warn: true);
      return;
    }
    if (state.subs.any((item) => item.topic == topic)) {
      _notify(MqttNoticeKind.dupTopic, toast: true, warn: true);
      return;
    }
    try {
      await _repo.subscribe(topic, state.draftSubQos);
    } on AppException catch (error, stackTrace) {
      _logIo('MQTT 订阅失败', error, stackTrace);
      return;
    }
    final item = MqttSubscription(
      id: newSerialId('s'),
      topic: topic,
      qos: state.draftSubQos,
    );
    emit(
      state.copyWith(
        subs: [...state.subs, item],
        draftSubTopic: '',
      ),
    );
    _persist();
    _sys('已订阅 $topic · QoS ${item.qos}');
    _notify(
      MqttNoticeKind.subscribed,
      toast: true,
      args: {'topic': topic, 'qos': item.qos},
    );
  }

  Future<void> unsubscribe(String id) async {
    MqttSubscription? hit;
    for (final item in state.subs) {
      if (item.id == id) hit = item;
    }
    if (hit == null) return;
    if (state.connected) {
      try {
        await _repo.unsubscribe(hit.topic);
      } on AppException catch (error, stackTrace) {
        _logIo('MQTT 退订失败', error, stackTrace);
      }
    }
    emit(
      state.copyWith(subs: [for (final item in state.subs) if (item.id != id) item]),
    );
    _persist();
    _notify(
      MqttNoticeKind.unsubscribed,
      toast: true,
      args: {'topic': hit.topic},
    );
  }

  void addPublishTopic() {
    final name = state.draftPubName.trim();
    final topic = state.draftPubTopic.trim();
    if (name.isEmpty || topic.isEmpty) {
      _notify(MqttNoticeKind.needName, toast: true, warn: true);
      return;
    }
    emit(
      state.copyWith(
        pubTopics: [
          ...state.pubTopics,
          MqttPublishTopic(id: newSerialId('t'), name: name, topic: topic),
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
        quick: [for (final item in state.quick) if (item.id != id) item],
      ),
    );
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
  }) async {
    if (!state.connected) {
      _notify(MqttNoticeKind.closedPublish, toast: true, warn: true);
      return;
    }
    if (topic.trim().isEmpty) {
      _notify(MqttNoticeKind.needPubTopic, toast: true, warn: true);
      return;
    }
    if (payload.isEmpty) {
      _notify(MqttNoticeKind.emptyPayload, toast: true, warn: true);
      return;
    }
    try {
      await _repo.publish(
        topic: topic.trim(),
        payload: payload,
        qos: qos,
        retain: retain,
      );
    } on AppException catch (error, stackTrace) {
      _logIo('MQTT 发布失败', error, stackTrace);
      return;
    }
    _push(
      dir: MqttDir.tx,
      topic: topic.trim(),
      qos: qos,
      retain: retain,
      payload: payload,
    );
  }

  Future<void> _resubscribe() async {
    for (final item in state.subs) {
      try {
        await _repo.subscribe(item.topic, item.qos);
      } on AppException catch (error, stackTrace) {
        _logIo('MQTT 重订阅失败', error, stackTrace);
      }
    }
  }

  void _onMessage(MqttIncoming incoming) {
    _push(
      dir: MqttDir.rx,
      topic: incoming.topic,
      qos: incoming.qos,
      retain: incoming.retain,
      payload: incoming.payload,
    );
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
