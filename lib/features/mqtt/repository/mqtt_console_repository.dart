import '../data/mqtt_file_gateway.dart';
import '../data/mqtt_gateway.dart';
import '../data/mqtt_workspace_store.dart';
import '../model/mqtt_models.dart';

class MqttConsoleRepository {
  MqttConsoleRepository({
    required MqttGateway gateway,
    required MqttWorkspaceStore store,
    required MqttFileGateway files,
  }) : _gateway = gateway,
       _store = store,
       _files = files;

  final MqttGateway _gateway;
  final MqttWorkspaceStore _store;
  final MqttFileGateway _files;

  MqttGateway get gateway => _gateway;

  MqttWorkspace? load() => _store.read();

  Future<void> save(MqttWorkspace workspace) => _store.write(workspace);

  Stream<MqttIncoming> get messages => _gateway.messages;

  Stream<bool> get connections => _gateway.connections;

  Stream<String> get errors => _gateway.errors;

  bool get isConnected => _gateway.isConnected;

  Future<void> connect(MqttLinkConfig config) => _gateway.connect(config);

  Future<void> disconnect() => _gateway.disconnect();

  Future<void> subscribe(String topic, int qos) =>
      _gateway.subscribe(topic, qos);

  Future<void> unsubscribe(String topic) => _gateway.unsubscribe(topic);

  Future<void> publish({
    required String topic,
    required String payload,
    required int qos,
    required bool retain,
  }) => _gateway.publish(
    topic: topic,
    payload: payload,
    qos: qos,
    retain: retain,
  );

  Future<String?> pickPath({List<String> extensions = const []}) =>
      _files.pickPath(extensions: extensions);

  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) => _files.pickSave(suggestedName: suggestedName, extension: extension);

  Future<void> writeText({required String path, required String text}) =>
      _files.writeText(path: path, text: text);

  Future<void> close() => _gateway.dispose();
}
