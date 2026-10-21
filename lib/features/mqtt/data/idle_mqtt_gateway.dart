import 'dart:async';

import '../model/mqtt_models.dart';
import 'mqtt_gateway.dart';

class IdleMqttGateway implements MqttGateway {
  final _messages = StreamController<MqttIncoming>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();

  @override
  Stream<MqttIncoming> get messages => _messages.stream;

  @override
  Stream<bool> get connections => _connections.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  bool get isConnected => false;

  @override
  Future<void> connect(MqttLinkConfig config) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> subscribe(String topic, int qos) async {}

  @override
  Future<void> unsubscribe(String topic) async {}

  @override
  Future<void> publish({
    required String topic,
    required String payload,
    required int qos,
    required bool retain,
  }) async {}

  @override
  Future<void> dispose() async {
    await _messages.close();
    await _connections.close();
    await _errors.close();
  }
}
