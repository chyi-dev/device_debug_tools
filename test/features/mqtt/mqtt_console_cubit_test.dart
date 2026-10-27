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
}

class _FakeGateway implements MqttGateway {
  final _messages = StreamController<MqttIncoming>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();
  final published = <String>[];
  final subscribed = <String>[];
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
  Future<void> unsubscribe(String topic) async {}

  @override
  Future<void> publish({
    required String topic,
    required String payload,
    required int qos,
    required bool retain,
  }) async {
    published.add(topic);
  }

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
