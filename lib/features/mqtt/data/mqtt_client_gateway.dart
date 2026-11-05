import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:typed_data/typed_data.dart';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../model/mqtt_models.dart';
import 'mqtt_connect_plan.dart';
import 'mqtt_gateway.dart';

class MqttClientGateway implements MqttGateway {
  final _messages = StreamController<MqttIncoming>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _sub;
  var _connected = false;

  @override
  Stream<MqttIncoming> get messages => _messages.stream;

  @override
  Stream<bool> get connections => _connections.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect(MqttLinkConfig config) async {
    await disconnect();
    final plan = MqttConnectPlan.resolve(config);
    final client = MqttServerClient.withPort(
      plan.server,
      config.clientId,
      config.port,
    );
    client.keepAlivePeriod = config.keepAlive <= 0 ? 30 : config.keepAlive;
    client.autoReconnect = config.autoReconnect;
    client.resubscribeOnAutoReconnect = false;
    client.logging(on: false);
    if (config.version == MqttVersion.v5) {
      // mqtt_client 仅内置 3.1 / 3.1.1；5.0 通过协议号声明，属性（含 Session Expiry）由 Broker 按默认处理。
      Protocol.version = 5;
      Protocol.name = MqttClientConstants.mqttV311ProtocolName;
    } else {
      client.setProtocolV311();
    }
    if (plan.useWebSocket) {
      client.useWebSocket = true;
      client.websocketProtocols = MqttClientConstants.protocolsSingleDefault;
      if (plan.alternateWebSocket) {
        client.useAlternateWebSocketImplementation = true;
        client.securityContext = _security(config);
      }
    } else if (plan.secure) {
      client.secure = true;
      client.securityContext = _security(config);
    }
    client.onConnected = () {
      _connected = true;
      _connections.add(true);
    };
    client.onDisconnected = () {
      _connected = false;
      _connections.add(false);
    };
    client.onAutoReconnected = () {
      _connected = true;
      _connections.add(true);
    };
    final message = MqttConnectMessage().withClientIdentifier(config.clientId);
    if (config.cleanStart) {
      message.startClean();
    }
    if (config.username.isNotEmpty) {
      message.authenticateAs(config.username, config.password);
    }
    if (config.willTopic.trim().isNotEmpty) {
      message.withWillTopic(config.willTopic);
      message.withWillMessage(config.willPayload);
      message.withWillQos(_qos(config.willQos));
      if (config.willRetain) message.withWillRetain();
    }
    client.connectionMessage = message;
    _client = client;
    try {
      await client.connect();
      if (client.connectionStatus?.state != MqttConnectionState.connected) {
        throw DeviceException(
          client.connectionStatus?.returnCode?.toString() ?? 'MQTT 连接失败',
        );
      }
      _connected = true;
      _sub = client.updates?.listen(_onMessage);
    } catch (error, stackTrace) {
      AppLogger.i.error(
        'MQTT 连接失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
      await disconnect();
      throw DeviceException('$error');
    }
  }

  @override
  Future<void> disconnect() async {
    await _sub?.cancel();
    _sub = null;
    final client = _client;
    _client = null;
    _connected = false;
    if (client == null) return;
    try {
      client.disconnect();
    } catch (error, stackTrace) {
      AppLogger.i.error(
        'MQTT 断开失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> subscribe(String topic, int qos) async {
    final client = _client;
    if (client == null || !_connected) {
      throw DeviceException('MQTT 未连接');
    }
    client.subscribe(topic, _qos(qos));
  }

  @override
  Future<void> unsubscribe(String topic) async {
    final client = _client;
    if (client == null || !_connected) return;
    client.unsubscribe(topic);
  }

  @override
  Future<void> publish({
    required String topic,
    required String payload,
    required int qos,
    required bool retain,
  }) async {
    final client = _client;
    if (client == null || !_connected) {
      throw DeviceException('MQTT 未连接');
    }
    final builder = MqttClientPayloadBuilder();
    builder.addUTF8String(payload);
    client.publishMessage(
      topic,
      _qos(qos),
      builder.payload ?? Uint8Buffer(),
      retain: retain,
    );
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _messages.close();
    await _connections.close();
    await _errors.close();
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> events) {
    for (final event in events) {
      final message = event.payload;
      if (message is! MqttPublishMessage) continue;
      final bytes = message.payload.message;
      _messages.add(
        MqttIncoming(
          topic: event.topic,
          payload: utf8.decode(bytes, allowMalformed: true),
          qos: message.header?.qos.index ?? 0,
          retain: message.header?.retain ?? false,
        ),
      );
    }
  }

  SecurityContext _security(MqttLinkConfig config) {
    final context = SecurityContext(withTrustedRoots: config.caFile.isEmpty);
    if (config.caFile.isNotEmpty) {
      context.setTrustedCertificates(config.caFile);
    }
    if (config.clientCert.isNotEmpty && config.clientKey.isNotEmpty) {
      context.useCertificateChain(config.clientCert);
      context.usePrivateKey(config.clientKey);
    }
    return context;
  }
}

MqttQos _qos(int value) => switch (value) {
  1 => MqttQos.atLeastOnce,
  2 => MqttQos.exactlyOnce,
  _ => MqttQos.atMostOnce,
};
