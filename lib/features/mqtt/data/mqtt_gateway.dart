import '../model/mqtt_models.dart';

abstract class MqttGateway {
  Stream<MqttIncoming> get messages;

  Stream<bool> get connections;

  Stream<String> get errors;

  bool get isConnected;

  Future<void> connect(MqttLinkConfig config);

  Future<void> disconnect();

  Future<void> subscribe(String topic, int qos);

  Future<void> unsubscribe(String topic);

  Future<void> publish({
    required String topic,
    required String payload,
    required int qos,
    required bool retain,
  });

  Future<void> dispose();
}
