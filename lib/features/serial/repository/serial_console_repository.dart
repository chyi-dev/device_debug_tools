import 'dart:typed_data';

import '../data/serial_file_gateway.dart';
import '../data/serial_port_gateway.dart';
import '../data/serial_workspace_store.dart';
import '../model/serial_models.dart';

class SerialConsoleRepository {
  SerialConsoleRepository({
    required SerialPortGateway ports,
    required SerialFileGateway files,
    required SerialWorkspaceStore store,
  })  : _ports = ports,
        _files = files,
        _store = store;

  final SerialPortGateway _ports;
  final SerialFileGateway _files;
  final SerialWorkspaceStore _store;

  SerialWorkspace? load() => _store.read();

  Future<void> save(SerialWorkspace workspace) => _store.write(workspace);

  Future<List<SerialPortInfo>> listPorts() => _ports.listPorts();

  Future<SerialOpenResult> open(SerialLinkConfig config) => _ports.open(config);

  Future<void> apply(SerialLinkConfig config) => _ports.apply(config);

  Future<void> write(Uint8List data) => _ports.write(data);

  Stream<Uint8List> get incoming => _ports.incoming;

  PinLevels readPins() => _ports.readPins();

  Future<void> close() => _ports.close();

  bool get isOpen => _ports.isOpen;

  Future<PickedBytes?> pickAny() => _files.pickAny();

  Future<String?> pickText({required List<String> extensions}) =>
      _files.pickText(extensions: extensions);

  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) =>
      _files.pickSave(suggestedName: suggestedName, extension: extension);

  Future<void> writeText({required String path, required String text}) =>
      _files.writeText(path: path, text: text);
}
