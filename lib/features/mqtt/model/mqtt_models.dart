enum MqttVersion { v311, v5 }

enum MqttScheme {
  mqtt,
  mqtts,
  ws,
  wss;

  int get defaultPort => switch (this) {
    MqttScheme.mqtt => 1883,
    MqttScheme.mqtts => 8883,
    MqttScheme.ws => 8083,
    MqttScheme.wss => 8084,
  };

  bool get webSocket => this == MqttScheme.ws || this == MqttScheme.wss;

  bool get showsCertificates =>
      this == MqttScheme.mqtts || this == MqttScheme.wss;
}

/// 空路径与 `/` 都表示根路径。其余缺前导 `/` 时补上。
String normalizeWsPath(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '/') return '/';
  return trimmed.startsWith('/') ? trimmed : '/$trimmed';
}

String mqttEndpoint({
  required MqttScheme scheme,
  required String host,
  required int port,
  String wsPath = '',
}) {
  if (scheme.webSocket) {
    return '${scheme.name}://$host:$port${normalizeWsPath(wsPath)}';
  }
  return '${scheme.name}://$host:$port';
}

enum MqttNoticeKind {
  ready,
  connected,
  disconnected,
  connectFailed,
  closed,
  closedPublish,
  closedSubscribe,
  needTopic,
  dupTopic,
  subscribed,
  unsubscribed,
  filled,
  needPubTopic,
  emptyPayload,
  needName,
  logSaved,
  cleared,
  quickSaved,
  deleted,
  portInvalid,
  keepAliveInvalid,
}

class MqttNotice {
  const MqttNotice({
    required this.id,
    required this.kind,
    this.warn = false,
    this.args = const {},
  });

  final int id;
  final MqttNoticeKind kind;
  final bool warn;
  final Map<String, Object> args;
}

class MqttSubscription {
  const MqttSubscription({
    required this.id,
    required this.topic,
    required this.qos,
    this.retain = false,
  });

  final String id;
  final String topic;
  final int qos;
  final bool retain;

  Map<String, Object> toJson() => {
    'id': id,
    'topic': topic,
    'qos': qos,
    'retain': retain,
  };

  static MqttSubscription? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final topic = raw['topic']?.toString() ?? '';
    if (topic.isEmpty) return null;
    return MqttSubscription(
      id: raw['id']?.toString().isNotEmpty == true
          ? raw['id'].toString()
          : 's${DateTime.now().microsecondsSinceEpoch}',
      topic: topic,
      qos: _int(raw['qos'], 0),
      retain: raw['retain'] == true,
    );
  }
}

class MqttPublishTopic {
  const MqttPublishTopic({
    required this.id,
    required this.name,
    required this.topic,
  });

  final String id;
  final String name;
  final String topic;

  Map<String, Object> toJson() => {'id': id, 'name': name, 'topic': topic};

  static MqttPublishTopic? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final topic = raw['topic']?.toString() ?? '';
    if (topic.isEmpty) return null;
    return MqttPublishTopic(
      id: raw['id']?.toString().isNotEmpty == true
          ? raw['id'].toString()
          : 't${DateTime.now().microsecondsSinceEpoch}',
      name: raw['name']?.toString() ?? topic,
      topic: topic,
    );
  }
}

class MqttQuickCommand {
  const MqttQuickCommand({
    required this.id,
    required this.name,
    required this.data,
    this.key = '',
    this.inherit = true,
    this.topic = '',
    this.qos = 0,
    this.retain = false,
  });

  final String id;
  final String name;
  final String data;
  final String key;
  final bool inherit;
  final String topic;
  final int qos;
  final bool retain;

  MqttQuickCommand copyWith({
    bool? inherit,
    String? topic,
    int? qos,
    bool? retain,
  }) => MqttQuickCommand(
    id: id,
    name: name,
    data: data,
    key: key,
    inherit: inherit ?? this.inherit,
    topic: topic ?? this.topic,
    qos: qos ?? this.qos,
    retain: retain ?? this.retain,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'data': data,
    'key': key,
    'inherit': inherit,
    'topic': topic,
    'qos': qos,
    'retain': retain,
  };

  static MqttQuickCommand? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return MqttQuickCommand(
      id: raw['id']?.toString().isNotEmpty == true
          ? raw['id'].toString()
          : 'q${DateTime.now().microsecondsSinceEpoch}',
      name: raw['name']?.toString() ?? '',
      data: raw['data']?.toString() ?? '',
      key: raw['key']?.toString() ?? '',
      inherit: raw['inherit'] != false,
      topic: raw['topic']?.toString() ?? '',
      qos: _int(raw['qos'], 0),
      retain: raw['retain'] == true,
    );
  }
}

enum MqttDir { rx, tx, sys }

class MqttLogLine {
  const MqttLogLine({
    required this.no,
    required this.time,
    required this.dir,
    this.topic = '',
    this.qos = 0,
    this.retain = false,
    this.payload = '',
  });

  final int no;
  final DateTime time;
  final MqttDir dir;
  final String topic;
  final int qos;
  final bool retain;
  final String payload;
}

class MqttIncoming {
  const MqttIncoming({
    required this.topic,
    required this.payload,
    required this.qos,
    required this.retain,
  });

  final String topic;
  final String payload;
  final int qos;
  final bool retain;
}

class MqttLinkConfig {
  const MqttLinkConfig({
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
  });

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

  bool get hasCustomCerts =>
      caFile.isNotEmpty || clientCert.isNotEmpty || clientKey.isNotEmpty;
}

class MqttWorkspace {
  const MqttWorkspace({
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
    required this.pubTopic,
    required this.pubQos,
    required this.pubRetain,
    required this.payload,
    required this.settingsOpen,
    required this.compact,
    required this.toolsVisible,
    required this.subs,
    required this.pubTopics,
    required this.quick,
  });

  factory MqttWorkspace.defaults() => MqttWorkspace(
    host: '127.0.0.1',
    port: 1883,
    version: MqttVersion.v5,
    clientId: 'ddt-desktop-01',
    username: '',
    password: '',
    scheme: MqttScheme.mqtt,
    wsPath: '',
    caFile: '',
    clientCert: '',
    clientKey: '',
    keepAlive: 30,
    cleanStart: true,
    sessionExpiry: 3600,
    autoReconnect: true,
    willTopic: '',
    willPayload: '',
    willQos: 0,
    willRetain: false,
    pubTopic: '',
    pubQos: 0,
    pubRetain: false,
    payload: '',
    settingsOpen: false,
    compact: false,
    toolsVisible: true,
    subs: const [],
    pubTopics: const [],
    quick: const [],
  );

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
  final String pubTopic;
  final int pubQos;
  final bool pubRetain;
  final String payload;
  final bool settingsOpen;
  final bool compact;
  final bool toolsVisible;
  final List<MqttSubscription> subs;
  final List<MqttPublishTopic> pubTopics;
  final List<MqttQuickCommand> quick;

  MqttLinkConfig get link => MqttLinkConfig(
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
  );

  Map<String, Object> toJson() => {
    'host': host,
    'port': port,
    'version': version.name,
    'clientId': clientId,
    'username': username,
    'password': password,
    'scheme': scheme.name,
    'wsPath': wsPath,
    'caFile': caFile,
    'clientCert': clientCert,
    'clientKey': clientKey,
    'keepAlive': keepAlive,
    'cleanStart': cleanStart,
    'sessionExpiry': sessionExpiry,
    'autoReconnect': autoReconnect,
    'willTopic': willTopic,
    'willPayload': willPayload,
    'willQos': willQos,
    'willRetain': willRetain,
    'pubTopic': pubTopic,
    'pubQos': pubQos,
    'pubRetain': pubRetain,
    'payload': payload,
    'settingsOpen': settingsOpen,
    'compact': compact,
    'toolsVisible': toolsVisible,
    'subs': subs.map((item) => item.toJson()).toList(),
    'pubTopics': pubTopics.map((item) => item.toJson()).toList(),
    'quick': quick.map((item) => item.toJson()).toList(),
  };

  static MqttWorkspace fromJson(Object raw) {
    final map = raw is Map ? raw : const {};
    final subs = <MqttSubscription>[];
    final pubs = <MqttPublishTopic>[];
    final quick = <MqttQuickCommand>[];
    final subsRaw = map['subs'];
    if (subsRaw is List) {
      for (final item in subsRaw) {
        final sub = MqttSubscription.fromJson(item);
        if (sub != null) subs.add(sub);
      }
    }
    final pubsRaw = map['pubTopics'];
    if (pubsRaw is List) {
      for (final item in pubsRaw) {
        final topic = MqttPublishTopic.fromJson(item);
        if (topic != null) pubs.add(topic);
      }
    }
    final quickRaw = map['quick'];
    if (quickRaw is List) {
      for (final item in quickRaw) {
        final command = MqttQuickCommand.fromJson(item);
        if (command != null) quick.add(command);
      }
    }
    return MqttWorkspace(
      host: map['host']?.toString() ?? '127.0.0.1',
      port: _int(map['port'], 1883),
      version: MqttVersion.values.asNameMap()[map['version']?.toString()] ??
          MqttVersion.v5,
      clientId: map['clientId']?.toString() ?? 'ddt-desktop-01',
      username: map['username']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      scheme: _scheme(map),
      wsPath: map['wsPath']?.toString() ?? '',
      caFile: map['caFile']?.toString() ?? '',
      clientCert: map['clientCert']?.toString() ?? '',
      clientKey: map['clientKey']?.toString() ?? '',
      keepAlive: _int(map['keepAlive'], 30),
      cleanStart: map['cleanStart'] != false,
      sessionExpiry: _int(map['sessionExpiry'], 3600),
      autoReconnect: map['autoReconnect'] != false,
      willTopic: map['willTopic']?.toString() ?? '',
      willPayload: map['willPayload']?.toString() ?? '',
      willQos: _int(map['willQos'], 0),
      willRetain: map['willRetain'] == true,
      pubTopic: map['pubTopic']?.toString() ?? '',
      pubQos: _int(map['pubQos'], 0),
      pubRetain: map['pubRetain'] == true,
      payload: map['payload']?.toString() ?? '',
      settingsOpen: map['settingsOpen'] == true,
      compact: map['compact'] == true,
      toolsVisible: map['toolsVisible'] != false,
      subs: subs,
      pubTopics: pubs,
      quick: quick,
    );
  }
}

int _int(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

MqttScheme _scheme(Map<dynamic, dynamic> map) {
  final named = MqttScheme.values.asNameMap()[map['scheme']?.toString()];
  if (named != null) return named;
  return map['tls'] == true ? MqttScheme.mqtts : MqttScheme.mqtt;
}
