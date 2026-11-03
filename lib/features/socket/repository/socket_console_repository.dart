import 'dart:typed_data';

import '../../serial/model/serial_models.dart';
import '../data/socket_file_gateway.dart';
import '../data/socket_gateway.dart';
import '../data/socket_workspace_store.dart';
import '../model/socket_models.dart';

class SocketConsoleRepository {
  SocketConsoleRepository({
    required SocketGateway gateway,
    required SocketWorkspaceStore store,
    required SocketFileGateway files,
  }) : _gateway = gateway,
       _store = store,
       _files = files;

  final SocketGateway _gateway;
  final SocketWorkspaceStore _store;
  final SocketFileGateway _files;

  SocketWorkspace? load() => _store.read();

  Future<void> save(SocketWorkspace workspace) => _store.write(workspace);

  Stream<SocketIncoming> get incoming => _gateway.incoming;

  Stream<List<SocketPeer>> get peers => _gateway.peers;

  Stream<bool> get openState => _gateway.openState;

  Stream<String> get errors => _gateway.errors;

  bool get isOpen => _gateway.isOpen;

  List<SocketPeer> get currentPeers => _gateway.currentPeers;

  Future<void> openTcpClient({required String host, required int port}) =>
      _gateway.openTcpClient(host: host, port: port);

  Future<void> openTcpServer({required String host, required int port}) =>
      _gateway.openTcpServer(host: host, port: port);

  Future<void> openUdp({required String host, required int port}) =>
      _gateway.openUdp(host: host, port: port);

  Future<void> write(Uint8List data, {String? peerId}) =>
      _gateway.write(data, peerId: peerId);

  Future<void> writeUdp(
    Uint8List data, {
    required String host,
    required int port,
  }) => _gateway.writeUdp(data, host: host, port: port);

  Future<void> closeTransport() => _gateway.close();

  Future<void> close() => _gateway.dispose();

  Future<PickedBytes?> pickAny() => _files.pickAny();

  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) => _files.pickSave(suggestedName: suggestedName, extension: extension);

  Future<void> writeText({required String path, required String text}) =>
      _files.writeText(path: path, text: text);
}
