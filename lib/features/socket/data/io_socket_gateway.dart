import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../model/socket_models.dart';
import 'socket_gateway.dart';

class IoSocketGateway implements SocketGateway {
  final _incoming = StreamController<SocketIncoming>.broadcast();
  final _peers = StreamController<List<SocketPeer>>.broadcast();
  final _open = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();

  Socket? _client;
  ServerSocket? _server;
  RawDatagramSocket? _udp;
  final Map<String, Socket> _clients = {};
  final Map<String, StreamSubscription<List<int>>> _clientSubs = {};
  StreamSubscription<List<int>>? _clientSub;
  StreamSubscription<RawSocketEvent>? _udpSub;
  StreamSubscription<Socket>? _acceptSub;
  var _seq = 0;
  var _opened = false;

  @override
  Stream<SocketIncoming> get incoming => _incoming.stream;

  @override
  Stream<List<SocketPeer>> get peers => _peers.stream;

  @override
  Stream<bool> get openState => _open.stream;

  @override
  Stream<String> get errors => _errors.stream;

  @override
  bool get isOpen => _opened;

  @override
  List<SocketPeer> get currentPeers => [
    for (final entry in _clients.entries)
      SocketPeer(id: entry.key, address: _addr(entry.value)),
  ];

  @override
  Future<void> openTcpClient({required String host, required int port}) async {
    await close();
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );
      _client = socket;
      _opened = true;
      _open.add(true);
      _clientSub = socket.listen(
        (chunk) {
          if (chunk.isEmpty) return;
          _incoming.add(
            SocketIncoming(
              bytes: Uint8List.fromList(chunk),
              peerAddress: _addr(socket),
            ),
          );
        },
        onError: (Object error, StackTrace stack) {
          _emitError('TCP 客户端读写失败', error, stack);
          unawaited(close());
        },
        onDone: () => unawaited(close()),
        cancelOnError: true,
      );
    } catch (error, stack) {
      AppLogger.i.error(
        'TCP 客户端连接失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stack,
      );
      throw DeviceException(_describe(error));
    }
  }

  @override
  Future<void> openTcpServer({required String host, required int port}) async {
    await close();
    try {
      final address = _parseBind(host);
      final server = await ServerSocket.bind(address, port);
      _server = server;
      _opened = true;
      _open.add(true);
      _publishPeers();
      _acceptSub = server.listen(
        _onAccept,
        onError: (Object error, StackTrace stack) {
          _emitError('TCP 服务端监听失败', error, stack);
          unawaited(close());
        },
        onDone: () => unawaited(close()),
        cancelOnError: true,
      );
    } catch (error, stack) {
      AppLogger.i.error(
        'TCP 服务端打开失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stack,
      );
      throw DeviceException(_describe(error));
    }
  }

  @override
  Future<void> openUdp({required String host, required int port}) async {
    await close();
    try {
      final address = _parseBind(host);
      final udp = await RawDatagramSocket.bind(address, port);
      _udp = udp;
      _opened = true;
      _open.add(true);
      _udpSub = udp.listen(
        (event) {
          if (event != RawSocketEvent.read) return;
          final datagram = udp.receive();
          if (datagram == null || datagram.data.isEmpty) return;
          final peer = '${datagram.address.address}:${datagram.port}';
          _incoming.add(
            SocketIncoming(
              bytes: Uint8List.fromList(datagram.data),
              peerAddress: peer,
            ),
          );
        },
        onError: (Object error, StackTrace stack) {
          _emitError('UDP 读写失败', error, stack);
          unawaited(close());
        },
        onDone: () => unawaited(close()),
        cancelOnError: true,
      );
    } catch (error, stack) {
      AppLogger.i.error(
        'UDP 绑定失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stack,
      );
      throw DeviceException(_describe(error));
    }
  }

  @override
  Future<void> write(Uint8List data, {String? peerId}) async {
    if (!_opened) throw DeviceException('连接未打开');
    final client = _client;
    if (client != null) {
      client.add(data);
      await client.flush();
      return;
    }
    if (_server != null) {
      if (peerId != null) {
        final socket = _clients[peerId];
        if (socket == null) throw DeviceException('客户端已断开');
        socket.add(data);
        await socket.flush();
        return;
      }
      if (_clients.isEmpty) throw DeviceException('没有已连接的客户端');
      for (final socket in _clients.values) {
        socket.add(data);
        await socket.flush();
      }
      return;
    }
    throw DeviceException('当前不是 TCP 连接');
  }

  @override
  Future<void> writeUdp(
    Uint8List data, {
    required String host,
    required int port,
  }) async {
    final udp = _udp;
    if (udp == null || !_opened) throw DeviceException('UDP 未打开');
    try {
      final address = InternetAddress(host);
      final sent = udp.send(data, address, port);
      if (sent != data.length) {
        throw DeviceException('UDP 发送不完整');
      }
    } catch (error, stack) {
      if (error is AppException) rethrow;
      AppLogger.i.error(
        'UDP 发送失败',
        category: LogCategory.device,
        error: error,
        stackTrace: stack,
      );
      throw DeviceException(_describe(error));
    }
  }

  @override
  Future<void> close() async {
    final wasOpen = _opened;
    _opened = false;
    await _clientSub?.cancel();
    _clientSub = null;
    await _acceptSub?.cancel();
    _acceptSub = null;
    await _udpSub?.cancel();
    _udpSub = null;
    for (final sub in _clientSubs.values) {
      await sub.cancel();
    }
    _clientSubs.clear();
    for (final socket in _clients.values) {
      await socket.close();
    }
    _clients.clear();
    await _client?.close();
    _client = null;
    await _server?.close();
    _server = null;
    _udp?.close();
    _udp = null;
    if (wasOpen) {
      _open.add(false);
      _publishPeers();
    }
  }

  @override
  Future<void> dispose() async {
    await close();
    await _incoming.close();
    await _peers.close();
    await _open.close();
    await _errors.close();
  }

  void _onAccept(Socket socket) {
    final id = 'peer-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
    _clients[id] = socket;
    _publishPeers();
    _clientSubs[id] = socket.listen(
      (chunk) {
        if (chunk.isEmpty) return;
        _incoming.add(
          SocketIncoming(
            bytes: Uint8List.fromList(chunk),
            peerId: id,
            peerAddress: _addr(socket),
          ),
        );
      },
      onError: (Object error, StackTrace stack) {
        _emitError('TCP 客户端连接异常', error, stack);
        unawaited(_dropClient(id));
      },
      onDone: () => unawaited(_dropClient(id)),
      cancelOnError: true,
    );
  }

  Future<void> _dropClient(String id) async {
    final sub = _clientSubs.remove(id);
    await sub?.cancel();
    final socket = _clients.remove(id);
    await socket?.close();
    _publishPeers();
  }

  void _publishPeers() {
    if (!_peers.isClosed) _peers.add(currentPeers);
  }

  void _emitError(String title, Object error, StackTrace stack) {
    AppLogger.i.error(
      title,
      category: LogCategory.device,
      error: error,
      stackTrace: stack,
    );
    if (!_errors.isClosed) _errors.add(_describe(error));
  }

  InternetAddress _parseBind(String host) {
    final trimmed = host.trim();
    if (trimmed.isEmpty || trimmed == '0.0.0.0' || trimmed == '*') {
      return InternetAddress.anyIPv4;
    }
    if (trimmed == '::' || trimmed == '[::]') {
      return InternetAddress.anyIPv6;
    }
    return InternetAddress(trimmed);
  }

  String _addr(Socket socket) =>
      '${socket.remoteAddress.address}:${socket.remotePort}';

  String _describe(Object error) {
    if (error is SocketException) {
      final message = error.message.trim();
      final os = error.osError?.message.trim();
      if (os != null && os.isNotEmpty) return os;
      if (message.isNotEmpty) return message;
    }
    return '$error';
  }
}
