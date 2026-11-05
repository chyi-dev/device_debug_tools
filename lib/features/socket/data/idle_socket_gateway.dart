import 'dart:async';
import 'dart:typed_data';

import '../model/socket_models.dart';
import 'socket_gateway.dart';

class IdleSocketGateway implements SocketGateway {
  final _incoming = StreamController<SocketIncoming>.broadcast();
  final _peers = StreamController<List<SocketPeer>>.broadcast();
  final _open = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();

  @override
  Stream<SocketIncoming> get incoming => _incoming.stream;

  @override
  Stream<List<SocketPeer>> get peers => _peers.stream;

  @override
  Stream<bool> get openState => _open.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  bool get isOpen => false;

  @override
  List<SocketPeer> get currentPeers => const [];

  @override
  Future<void> openTcpClient({required String host, required int port}) async {}

  @override
  Future<void> openTcpServer({required String host, required int port}) async {}

  @override
  Future<void> openUdp({required String host, required int port}) async {}

  @override
  Future<void> write(Uint8List data, {String? peerId}) async {}

  @override
  Future<void> writeUdp(
    Uint8List data, {
    required String host,
    required int port,
  }) async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> dispose() async {
    await _incoming.close();
    await _peers.close();
    await _open.close();
    await _errors.close();
  }
}
