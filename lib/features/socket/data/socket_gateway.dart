import 'dart:typed_data';

import '../model/socket_models.dart';

abstract class SocketGateway {
  Stream<SocketIncoming> get incoming;

  Stream<List<SocketPeer>> get peers;

  Stream<bool> get openState;

  Stream<String> get errors;

  bool get isOpen;

  List<SocketPeer> get currentPeers;

  Future<void> openTcpClient({required String host, required int port});

  Future<void> openTcpServer({required String host, required int port});

  Future<void> openUdp({required String host, required int port});

  /// [peerId] 为空时：TCP 客户端发往对端；服务端发往全部客户端。
  Future<void> write(Uint8List data, {String? peerId});

  Future<void> writeUdp(
    Uint8List data, {
    required String host,
    required int port,
  });

  Future<void> close();

  Future<void> dispose();
}
