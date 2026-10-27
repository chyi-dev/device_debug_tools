import 'package:device_debug_tools/features/mqtt/data/mqtt_connect_plan.dart';
import 'package:device_debug_tools/features/mqtt/model/mqtt_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('旧存档没有 scheme 时按 tls 迁移', () {
    expect(
      MqttWorkspace.fromJson({'tls': true, 'host': 'broker'}).scheme,
      MqttScheme.mqtts,
    );
    expect(MqttWorkspace.fromJson({'host': 'broker'}).scheme, MqttScheme.mqtt);
    expect(
      MqttWorkspace.fromJson({
        'scheme': 'wss',
        'tls': true,
        'wsPath': 'mqtt',
      }).scheme,
      MqttScheme.wss,
    );
    expect(
      MqttWorkspace.fromJson({'scheme': 'ws', 'wsPath': '/mqtt'}).wsPath,
      '/mqtt',
    );
  });

  test('mqtt 与 mqtts 走 TCP', () {
    final plain = MqttConnectPlan.resolve(_link());
    expect(plain.server, '127.0.0.1');
    expect(plain.useWebSocket, isFalse);
    expect(plain.secure, isFalse);
    expect(plain.alternateWebSocket, isFalse);

    final tls = MqttConnectPlan.resolve(_link(scheme: MqttScheme.mqtts));
    expect(tls.server, '127.0.0.1');
    expect(tls.useWebSocket, isFalse);
    expect(tls.secure, isTrue);
    expect(tls.alternateWebSocket, isFalse);
  });

  test('ws 与 wss 走 WebSocket，证书只让 wss 使用 alternate', () {
    final ws = MqttConnectPlan.resolve(
      _link(scheme: MqttScheme.ws, wsPath: 'mqtt', caFile: 'ca.pem'),
    );
    expect(ws.server, 'ws://127.0.0.1/mqtt');
    expect(ws.useWebSocket, isTrue);
    expect(ws.secure, isFalse);
    expect(ws.alternateWebSocket, isFalse);

    final wss = MqttConnectPlan.resolve(
      _link(scheme: MqttScheme.wss, host: 'broker'),
    );
    expect(wss.server, 'wss://broker/');
    expect(wss.secure, isFalse);
    expect(wss.alternateWebSocket, isFalse);

    final custom = MqttConnectPlan.resolve(
      _link(scheme: MqttScheme.wss, clientCert: 'cert.pem'),
    );
    expect(custom.alternateWebSocket, isTrue);
    expect(custom.secure, isFalse);
  });

  test('Broker 前缀原样作为主机名', () {
    final plan = MqttConnectPlan.resolve(_link(host: 'ws://broker'));
    expect(plan.server, 'ws://broker');
    expect(plan.useWebSocket, isFalse);
  });
}

MqttLinkConfig _link({
  MqttScheme scheme = MqttScheme.mqtt,
  String host = '127.0.0.1',
  String wsPath = '',
  String caFile = '',
  String clientCert = '',
}) {
  return MqttLinkConfig(
    host: host,
    port: scheme.defaultPort,
    version: MqttVersion.v311,
    clientId: 'id',
    username: '',
    password: '',
    scheme: scheme,
    wsPath: wsPath,
    caFile: caFile,
    clientCert: clientCert,
    clientKey: '',
    keepAlive: 30,
    cleanStart: true,
    sessionExpiry: 0,
    autoReconnect: false,
    willTopic: '',
    willPayload: '',
    willQos: 0,
    willRetain: false,
  );
}
