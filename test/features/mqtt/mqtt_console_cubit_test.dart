import 'dart:async';

import 'package:device_debug_tools/features/mqtt/cubit/mqtt_console_cubit.dart';
import 'package:device_debug_tools/features/mqtt/data/mqtt_file_gateway.dart';
import 'package:device_debug_tools/features/mqtt/data/mqtt_gateway.dart';
import 'package:device_debug_tools/features/mqtt/data/mqtt_workspace_store.dart';
import 'package:device_debug_tools/features/mqtt/model/mqtt_models.dart';
import 'package:device_debug_tools/features/mqtt/repository/mqtt_console_repository.dart';
import 'package:device_debug_tools/features/serial/data/serial_file_gateway.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeGateway gateway;
  late MqttConsoleCubit cubit;

  setUp(() async {
    gateway = _FakeGateway();
    cubit = MqttConsoleCubit(
      repository: MqttConsoleRepository(
        gateway: gateway,
        store: _MemoryStore(),
        files: MqttFileGateway(files: _FakeFiles()),
      ),
    );
    await cubit.start();
  });

  tearDown(() async {
    await cubit.close();
  });

  test('未连接时发布和订阅拦截', () async {
    cubit.patch(draftSubTopic: 'device/status', pubTopic: 'cmd', payload: '1');
    await cubit.subscribe();
    expect(cubit.state.toast?.kind, MqttNoticeKind.closedSubscribe);
    await cubit.publish();
    expect(cubit.state.toast?.kind, MqttNoticeKind.closedPublish);
    expect(gateway.published, isEmpty);
    expect(gateway.subscribed, isEmpty);
  });

  test('填入主题只改发送区，不发布', () async {
    cubit.patch(draftPubName: '灯', draftPubTopic: 'device/demo/command');
    cubit.addPublishTopic();
    final id = cubit.state.pubTopics.single.id;
    cubit.fillTopic(id);
    expect(cubit.state.pubTopic, 'device/demo/command');
    expect(gateway.published, isEmpty);
    expect(cubit.state.toast?.kind, MqttNoticeKind.filled);
  });

  test('默认端口随协议切换，自定义端口保留', () {
    expect(cubit.state.port, 1883);
    cubit.patch(scheme: MqttScheme.ws);
    expect(cubit.state.scheme, MqttScheme.ws);
    expect(cubit.state.port, 8083);
    expect(cubit.state.endpoint, 'ws://127.0.0.1:8083/');
    cubit.patch(port: '9000');
    cubit.patch(scheme: MqttScheme.wss);
    expect(cubit.state.port, 9000);
    expect(cubit.state.endpoint, 'wss://127.0.0.1:9000/');
  });

  test('路径补前导斜杠，Broker 原样保留', () {
    cubit.patch(wsPath: 'mqtt', host: 'ws://broker');
    expect(cubit.state.wsPath, '/mqtt');
    expect(cubit.state.host, 'ws://broker');
    expect(cubit.state.scheme, MqttScheme.mqtt);
  });

  test('重连后按列表重新订阅', () async {
    await cubit.toggleConnect();
    cubit.patch(draftSubTopic: 'device/+/telemetry', draftSubQos: 1);
    await cubit.subscribe();
    cubit.patch(draftSubTopic: 'device/status');
    await cubit.subscribe();
    expect(gateway.subscribed, ['device/+/telemetry', 'device/status']);
    gateway.subscribed.clear();
    gateway.emitConnection(false);
    await Future<void>.delayed(Duration.zero);
    gateway.emitConnection(true);
    await Future<void>.delayed(Duration.zero);
    expect(gateway.subscribed, ['device/+/telemetry', 'device/status']);
  });

  test('退订只切换状态，重连不恢复已退订', () async {
    await cubit.toggleConnect();
    cubit.patch(draftSubTopic: 'device/status', draftSubQos: 1);
    await cubit.subscribe();
    final id = cubit.state.subs.single.id;
    await cubit.toggleSubscription(id);
    expect(cubit.state.subs, hasLength(1));
    expect(cubit.state.subs.single.subscribed, isFalse);
    expect(gateway.unsubscribed, ['device/status']);
    gateway.subscribed.clear();
    gateway.emitConnection(false);
    await Future<void>.delayed(Duration.zero);
    gateway.emitConnection(true);
    await Future<void>.delayed(Duration.zero);
    expect(gateway.subscribed, isEmpty);
    await cubit.toggleSubscription(id);
    expect(cubit.state.subs.single.subscribed, isTrue);
    expect(gateway.subscribed, ['device/status']);
    await cubit.deleteSubscription(id);
    expect(cubit.state.subs, isEmpty);
    expect(gateway.unsubscribed, ['device/status', 'device/status']);
  });

  test('旧工作区没有脚本时读成空列表', () {
    final workspace = MqttWorkspace.fromJson({'tls': true});
    expect(workspace.scheme, MqttScheme.mqtts);
    expect(workspace.scripts, isEmpty);
    expect(workspace.history, isEmpty);
    expect(workspace.toolTab, MqttToolTab.subs);
  });

  test('before_publish 返回 nil 时不发布', () async {
    await cubit.toggleConnect();
    cubit.newScript();
    final id = cubit.state.scripts.single.id;
    cubit.setScriptCode(
      id,
      'function before_publish(msg)\n  return nil\nend\n',
    );
    cubit.toggleScript(id);
    cubit.patch(pubTopic: 'a/b', payload: 'hi');
    await cubit.publish();
    expect(gateway.published, isEmpty);
    expect(
      cubit.state.lines.any(
        (line) => line.dir == MqttDir.sys && line.payload.contains('拦截'),
      ),
      isTrue,
    );
    expect(cubit.state.history, isEmpty);
  });

  test('before_publish 改写 payload 后再发布', () async {
    await cubit.toggleConnect();
    cubit.newScript();
    final id = cubit.state.scripts.single.id;
    cubit.setScriptCode(
      id,
      'function before_publish(msg)\n'
      '  msg.payload = "next"\n'
      '  return msg\n'
      'end\n',
    );
    cubit.toggleScript(id);
    cubit.patch(pubTopic: 'a/b', payload: 'hi');
    await cubit.publish();
    expect(gateway.published, ['a/b']);
    expect(gateway.payloads, ['next']);
    expect(cubit.state.history.single.payload, 'next');
  });

  test('只有发布按钮记入历史，填入写回发布框', () async {
    await cubit.toggleConnect();
    cubit.patch(pubTopic: 'a/b', payload: 'hi', pubQos: 1, pubRetain: true);
    await cubit.publish();
    await cubit.publish();
    expect(cubit.state.history, hasLength(1));
    cubit.saveQuick(const MqttQuickCommand(id: 'q1', name: '灯', data: 'on'));
    await cubit.publishQuick('q1');
    expect(cubit.state.history, hasLength(1));
    expect(gateway.payloads, ['hi', 'hi', 'on']);
    cubit.patch(pubTopic: 'x', payload: 'y', pubQos: 0, pubRetain: false);
    cubit.fillHistory(0);
    expect(cubit.state.pubTopic, 'a/b');
    expect(cubit.state.payload, 'hi');
    expect(cubit.state.pubQos, 1);
    expect(cubit.state.pubRetain, isTrue);
    await cubit.resendHistory(0);
    expect(gateway.payloads.where((item) => item == 'hi'), hasLength(3));
    final restored = MqttWorkspace.fromJson(cubit.state.toWorkspace().toJson());
    expect(restored.history.single.topic, 'a/b');
    cubit.removeHistory(0);
    expect(cubit.state.history, isEmpty);
  });

  test('on_message 把主题记进运行日志', () async {
    cubit.newScript();
    final id = cubit.state.scripts.single.id;
    cubit.setScriptCode(
      id,
      'function on_message(msg)\n  log(msg.topic)\nend\n',
    );
    cubit.toggleScript(id);
    gateway.emitMessage(
      const MqttIncoming(
        topic: 'device/status',
        payload: 'online',
        qos: 1,
        retain: false,
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(
      cubit.state.scriptLog.map((entry) => entry.text),
      contains('device/status'),
    );
  });
}

class _FakeGateway implements MqttGateway {
  final _messages = StreamController<MqttIncoming>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();
  final published = <String>[];
  final payloads = <String>[];
  final subscribed = <String>[];
  final unsubscribed = <String>[];
  var _connected = false;

  @override
  Stream<MqttIncoming> get messages => _messages.stream;

  @override
  Stream<bool> get connections => _connections.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  bool get isConnected => _connected;

  void emitConnection(bool value) {
    _connected = value;
    _connections.add(value);
  }

  @override
  Future<void> connect(MqttLinkConfig config) async {
    _connected = true;
    _connections.add(true);
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _connections.add(false);
  }

  @override
  Future<void> subscribe(String topic, int qos) async {
    subscribed.add(topic);
  }

  @override
  Future<void> unsubscribe(String topic) async {
    unsubscribed.add(topic);
  }

  @override
  Future<void> publish({
    required String topic,
    required String payload,
    required int qos,
    required bool retain,
  }) async {
    published.add(topic);
    payloads.add(payload);
  }

  void emitMessage(MqttIncoming message) => _messages.add(message);

  @override
  Future<void> dispose() async {
    await _messages.close();
    await _connections.close();
    await _errors.close();
  }
}

class _MemoryStore implements MqttWorkspaceStore {
  @override
  MqttWorkspace? read() => null;

  @override
  Future<void> write(MqttWorkspace workspace) async {}
}

class _FakeFiles implements SerialFileGateway {
  @override
  Future<PickedBytes?> pickAny() async => null;

  @override
  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) async => null;

  @override
  Future<String?> pickText({required List<String> extensions}) async => null;

  @override
  Future<void> writeText({required String path, required String text}) async {}
}
