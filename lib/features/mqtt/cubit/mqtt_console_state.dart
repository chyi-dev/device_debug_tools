import '../../serial/model/serial_models.dart';
import '../model/mqtt_models.dart';

const _keep = Object();

class MqttConsoleState {
  const MqttConsoleState({
    required this.host,
    required this.port,
    required this.version,
    required this.clientId,
    required this.username,
    required this.password,
    required this.scheme,
    required this.wsPath,
    required this.caFile,
    required this.clientCert,
    required this.clientKey,
    required this.keepAlive,
    required this.cleanStart,
    required this.sessionExpiry,
    required this.autoReconnect,
    required this.willTopic,
    required this.willPayload,
    required this.willQos,
    required this.willRetain,
    required this.connected,
    required this.connecting,
    required this.settingsOpen,
    required this.pubTopic,
    required this.pubQos,
    required this.pubRetain,
    required this.payload,
    required this.draftSubTopic,
    required this.draftSubQos,
    required this.draftPubName,
    required this.draftPubTopic,
    required this.subs,
    required this.pubTopics,
    required this.quick,
    required this.history,
    required this.scripts,
    required this.toolTab,
    required this.selectedScriptId,
    required this.scriptDock,
    required this.scriptTutorial,
    required this.openLesson,
    required this.scriptMeta,
    required this.scriptLog,
    required this.lines,
    required this.rxCount,
    required this.txCount,
    required this.compact,
    required this.toolsVisible,
    required this.hint,
    required this.toast,
  });

  factory MqttConsoleState.initial() {
    final ws = MqttWorkspace.defaults();
    return MqttConsoleState(
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
      connected: false,
      connecting: false,
      settingsOpen: ws.settingsOpen,
      pubTopic: ws.pubTopic,
      pubQos: ws.pubQos,
      pubRetain: ws.pubRetain,
      payload: ws.payload,
      draftSubTopic: '',
      draftSubQos: 0,
      draftPubName: '',
      draftPubTopic: '',
      subs: ws.subs,
      pubTopics: ws.pubTopics,
      quick: ws.quick,
      history: ws.history,
      scripts: ws.scripts,
      toolTab: ws.toolTab,
      selectedScriptId: ws.selectedScriptId,
      scriptDock: ws.scriptDock,
      scriptTutorial: false,
      openLesson: null,
      scriptMeta: const {},
      scriptLog: const [],
      lines: const [],
      rxCount: 0,
      txCount: 0,
      compact: ws.compact,
      toolsVisible: ws.toolsVisible,
      hint: const MqttNotice(id: 0, kind: MqttNoticeKind.ready),
      toast: null,
    );
  }

  final String host;
  final int port;
  final MqttVersion version;
  final String clientId;
  final String username;
  final String password;
  final MqttScheme scheme;
  final String wsPath;
  final String caFile;
  final String clientCert;
  final String clientKey;
  final int keepAlive;
  final bool cleanStart;
  final int sessionExpiry;
  final bool autoReconnect;
  final String willTopic;
  final String willPayload;
  final int willQos;
  final bool willRetain;
  final bool connected;
  final bool connecting;
  final bool settingsOpen;
  final String pubTopic;
  final int pubQos;
  final bool pubRetain;
  final String payload;
  final String draftSubTopic;
  final int draftSubQos;
  final String draftPubName;
  final String draftPubTopic;
  final List<MqttSubscription> subs;
  final List<MqttPublishTopic> pubTopics;
  final List<MqttQuickCommand> quick;
  final List<MqttHistoryEntry> history;
  final List<LuaScript> scripts;
  final MqttToolTab toolTab;
  final String? selectedScriptId;
  final bool scriptDock;
  final bool scriptTutorial;
  final String? openLesson;
  final Map<String, MqttScriptMeta> scriptMeta;
  final List<MqttScriptLogEntry> scriptLog;
  final List<MqttLogLine> lines;
  final int rxCount;
  final int txCount;
  final bool compact;
  final bool toolsVisible;
  final MqttNotice hint;
  final MqttNotice? toast;

  LuaScript? get selectedScript {
    final id = selectedScriptId;
    if (id == null) return null;
    for (final script in scripts) {
      if (script.id == id) return script;
    }
    return null;
  }

  /// 脚本页签且未收起时停靠。没有选中脚本时只在已有运行日志（样例试跑）时出现。
  bool get scriptDockVisible =>
      toolTab == MqttToolTab.script &&
      scriptDock &&
      (selectedScript != null || scriptLog.isNotEmpty);

  String get endpoint =>
      mqttEndpoint(scheme: scheme, host: host, port: port, wsPath: wsPath);

  MqttConsoleState copyWith({
    String? host,
    int? port,
    MqttVersion? version,
    String? clientId,
    String? username,
    String? password,
    MqttScheme? scheme,
    String? wsPath,
    String? caFile,
    String? clientCert,
    String? clientKey,
    int? keepAlive,
    bool? cleanStart,
    int? sessionExpiry,
    bool? autoReconnect,
    String? willTopic,
    String? willPayload,
    int? willQos,
    bool? willRetain,
    bool? connected,
    bool? connecting,
    bool? settingsOpen,
    String? pubTopic,
    int? pubQos,
    bool? pubRetain,
    String? payload,
    String? draftSubTopic,
    int? draftSubQos,
    String? draftPubName,
    String? draftPubTopic,
    List<MqttSubscription>? subs,
    List<MqttPublishTopic>? pubTopics,
    List<MqttQuickCommand>? quick,
    List<MqttHistoryEntry>? history,
    List<LuaScript>? scripts,
    MqttToolTab? toolTab,
    Object? selectedScriptId = _keep,
    bool? scriptDock,
    bool? scriptTutorial,
    Object? openLesson = _keep,
    Map<String, MqttScriptMeta>? scriptMeta,
    List<MqttScriptLogEntry>? scriptLog,
    List<MqttLogLine>? lines,
    int? rxCount,
    int? txCount,
    bool? compact,
    bool? toolsVisible,
    MqttNotice? hint,
    Object? toast = _keep,
  }) {
    return MqttConsoleState(
      host: host ?? this.host,
      port: port ?? this.port,
      version: version ?? this.version,
      clientId: clientId ?? this.clientId,
      username: username ?? this.username,
      password: password ?? this.password,
      scheme: scheme ?? this.scheme,
      wsPath: wsPath ?? this.wsPath,
      caFile: caFile ?? this.caFile,
      clientCert: clientCert ?? this.clientCert,
      clientKey: clientKey ?? this.clientKey,
      keepAlive: keepAlive ?? this.keepAlive,
      cleanStart: cleanStart ?? this.cleanStart,
      sessionExpiry: sessionExpiry ?? this.sessionExpiry,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      willTopic: willTopic ?? this.willTopic,
      willPayload: willPayload ?? this.willPayload,
      willQos: willQos ?? this.willQos,
      willRetain: willRetain ?? this.willRetain,
      connected: connected ?? this.connected,
      connecting: connecting ?? this.connecting,
      settingsOpen: settingsOpen ?? this.settingsOpen,
      pubTopic: pubTopic ?? this.pubTopic,
      pubQos: pubQos ?? this.pubQos,
      pubRetain: pubRetain ?? this.pubRetain,
      payload: payload ?? this.payload,
      draftSubTopic: draftSubTopic ?? this.draftSubTopic,
      draftSubQos: draftSubQos ?? this.draftSubQos,
      draftPubName: draftPubName ?? this.draftPubName,
      draftPubTopic: draftPubTopic ?? this.draftPubTopic,
      subs: subs ?? this.subs,
      pubTopics: pubTopics ?? this.pubTopics,
      quick: quick ?? this.quick,
      history: history ?? this.history,
      scripts: scripts ?? this.scripts,
      toolTab: toolTab ?? this.toolTab,
      selectedScriptId: identical(selectedScriptId, _keep)
          ? this.selectedScriptId
          : selectedScriptId as String?,
      scriptDock: scriptDock ?? this.scriptDock,
      scriptTutorial: scriptTutorial ?? this.scriptTutorial,
      openLesson: identical(openLesson, _keep)
          ? this.openLesson
          : openLesson as String?,
      scriptMeta: scriptMeta ?? this.scriptMeta,
      scriptLog: scriptLog ?? this.scriptLog,
      lines: lines ?? this.lines,
      rxCount: rxCount ?? this.rxCount,
      txCount: txCount ?? this.txCount,
      compact: compact ?? this.compact,
      toolsVisible: toolsVisible ?? this.toolsVisible,
      hint: hint ?? this.hint,
      toast: identical(toast, _keep) ? this.toast : toast as MqttNotice?,
    );
  }

  MqttWorkspace toWorkspace() => MqttWorkspace(
    host: host,
    port: port,
    version: version,
    clientId: clientId,
    username: username,
    password: password,
    scheme: scheme,
    wsPath: wsPath,
    caFile: caFile,
    clientCert: clientCert,
    clientKey: clientKey,
    keepAlive: keepAlive,
    cleanStart: cleanStart,
    sessionExpiry: sessionExpiry,
    autoReconnect: autoReconnect,
    willTopic: willTopic,
    willPayload: willPayload,
    willQos: willQos,
    willRetain: willRetain,
    pubTopic: pubTopic,
    pubQos: pubQos,
    pubRetain: pubRetain,
    payload: payload,
    settingsOpen: settingsOpen,
    compact: compact,
    toolsVisible: toolsVisible,
    subs: subs,
    pubTopics: pubTopics,
    quick: quick,
    history: history,
    scripts: scripts,
    toolTab: toolTab,
    selectedScriptId: selectedScriptId,
    scriptDock: scriptDock,
  );
}
