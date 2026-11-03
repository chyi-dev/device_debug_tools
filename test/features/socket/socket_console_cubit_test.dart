import 'dart:async';
import 'dart:typed_data';

import 'package:device_debug_tools/features/serial/data/serial_file_gateway.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:device_debug_tools/features/socket/cubit/socket_console_cubit.dart';
import 'package:device_debug_tools/features/socket/data/socket_file_gateway.dart';
import 'package:device_debug_tools/features/socket/data/socket_gateway.dart';
import 'package:device_debug_tools/features/socket/data/socket_workspace_store.dart';
import 'package:device_debug_tools/features/socket/model/socket_models.dart';
import 'package:device_debug_tools/features/socket/repository/socket_console_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeGateway gateway;
  late SocketConsoleCubit cubit;

  Future<SocketConsoleCubit> openCubit(SocketProtocol protocol) async {
    gateway = _FakeGateway();
    final next = SocketConsoleCubit(
      repository: SocketConsoleRepository(
        gateway: gateway,
        store: _MemoryStore(),
        files: SocketFileGateway(files: _FakeFiles()),
      ),
      protocol: protocol,
    );
    await next.start();
    return next;
  }

  tearDown(() async {
    await cubit.close();
  });

  test('未打开时发送拦截', () async {
    cubit = await openCubit(SocketProtocol.tcp);
    cubit.setTxText('01 02');
    await cubit.sendFromEditor();
    expect(cubit.state.toast?.kind, SocketNoticeKind.closedSend);
    expect(gateway.writes, isEmpty);
  });

  test('TCP 客户端收发与分包', () async {
    cubit = await openCubit(SocketProtocol.tcp);
    cubit.setPacketTimeout(30);
    await cubit.toggleOpen();
    expect(cubit.state.open, isTrue);
    expect(gateway.mode, 'tcpClient');

    cubit.setTxText('AA BB');
    await cubit.sendFromEditor();
    expect(gateway.writes.single.$1, [0xAA, 0xBB]);
    expect(cubit.state.txCount, 2);

    gateway.emitIncoming(Uint8List.fromList([0x01, 0x02]));
    gateway.emitIncoming(Uint8List.fromList([0x03]));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.rxCount, 0);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(cubit.state.rxCount, 3);
    expect(
      cubit.state.lines.where((l) => l.dir == LogDir.rx).single.bytes,
      [0x01, 0x02, 0x03],
    );
  });

  test('TCP 服务端无客户端时发送拦截，应答只回源连接', () async {
    cubit = await openCubit(SocketProtocol.tcp);
    await cubit.setRole(SocketRole.server);
    await cubit.toggleOpen();
    expect(gateway.mode, 'tcpServer');

    cubit.setTxText('01');
    await cubit.sendFromEditor();
    expect(cubit.state.toast?.kind, SocketNoticeKind.noClient);

    gateway.setPeers(const [
      SocketPeer(id: 'a', address: '10.0.0.2:1000'),
      SocketPeer(id: 'b', address: '10.0.0.3:1001'),
    ]);
    await Future<void>.delayed(Duration.zero);

    cubit.upsertRule(
      const ReplyRule(
        id: 'r1',
        name: 'echo',
        match: MatchMode.frame,
        pattern: '11',
        enabled: true,
        hits: 0,
        replies: [ReplyStep(data: '22', delayMs: 0)],
        kind: MatchKind.template,
        format: DataFormat.hex,
        ignoreCase: false,
      ),
    );
    gateway.emitIncoming(
      Uint8List.fromList([0x11]),
      peerId: 'b',
      peerAddress: '10.0.0.3:1001',
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(gateway.writes, isNotEmpty);
    expect(gateway.writes.last.$2, 'b');
    expect(gateway.writes.last.$1, [0x22]);
  });

  test('TCP 服务端手动发送可广播', () async {
    cubit = await openCubit(SocketProtocol.tcp);
    await cubit.setRole(SocketRole.server);
    await cubit.toggleOpen();
    gateway.setPeers(const [
      SocketPeer(id: 'a', address: '10.0.0.2:1000'),
      SocketPeer(id: 'b', address: '10.0.0.3:1001'),
    ]);
    await Future<void>.delayed(Duration.zero);
    cubit.selectPeer(null);
    cubit.setTxText('FF');
    await cubit.sendFromEditor();
    expect(gateway.writes.single.$2, isNull);
    expect(gateway.writes.single.$1, [0xFF]);
  });

  test('UDP 一包一帧，未填远端只收不发', () async {
    cubit = await openCubit(SocketProtocol.udp);
    await cubit.setRemoteHost('');
    await cubit.toggleOpen();
    expect(gateway.mode, 'udp');

    gateway.emitIncoming(
      Uint8List.fromList([0x09]),
      peerAddress: '8.8.8.8:53',
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.rxCount, 1);
    expect(
      cubit.state.lines.where((l) => l.dir == LogDir.rx).single.peer,
      '8.8.8.8:53',
    );

    cubit.setTxText('01');
    await cubit.sendFromEditor();
    expect(cubit.state.toast?.kind, SocketNoticeKind.noRemote);
    expect(gateway.udpWrites, isEmpty);

    await cubit.setRemoteHost('1.1.1.1');
    await cubit.setRemotePort(9999);
    await cubit.sendFromEditor();
    expect(gateway.udpWrites.single.$1, [0x01]);
    expect(gateway.udpWrites.single.$2, '1.1.1.1');
    expect(gateway.udpWrites.single.$3, 9999);
  });

  test('before_send 拦截发送', () async {
    cubit = await openCubit(SocketProtocol.tcp);
    await cubit.toggleOpen();
    cubit.upsertQuick(
      const QuickCommand(
        id: 'q',
        name: 'x',
        data: '01',
        format: DataFormat.hex,
      ),
    );
    cubit.newScript();
    final scriptId = cubit.state.scripts.last.id;
    cubit.setScriptCode(scriptId, '''
function before_send(frame)
  return nil
end
''');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    cubit.toggleScript(scriptId);
    await cubit.sendQuick('q');
    expect(gateway.writes, isEmpty);
    expect(
      cubit.state.lines.any((l) => l.sys == SysLogKind.scriptBlocked),
      isTrue,
    );
  });
}

class _FakeGateway implements SocketGateway {
  final _incoming = StreamController<SocketIncoming>.broadcast();
  final _peers = StreamController<List<SocketPeer>>.broadcast();
  final _open = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();
  final writes = <(List<int>, String?)>[];
  final udpWrites = <(List<int>, String, int)>[];
  var _opened = false;
  String? mode;
  List<SocketPeer> _peerList = const [];

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
  List<SocketPeer> get currentPeers => _peerList;

  void emitIncoming(
    Uint8List bytes, {
    String? peerId,
    String? peerAddress,
  }) {
    _incoming.add(
      SocketIncoming(bytes: bytes, peerId: peerId, peerAddress: peerAddress),
    );
  }

  void setPeers(List<SocketPeer> peers) {
    _peerList = peers;
    _peers.add(peers);
  }

  @override
  Future<void> openTcpClient({required String host, required int port}) async {
    mode = 'tcpClient';
    _opened = true;
    _open.add(true);
  }

  @override
  Future<void> openTcpServer({required String host, required int port}) async {
    mode = 'tcpServer';
    _opened = true;
    _open.add(true);
  }

  @override
  Future<void> openUdp({required String host, required int port}) async {
    mode = 'udp';
    _opened = true;
    _open.add(true);
  }

  @override
  Future<void> write(Uint8List data, {String? peerId}) async {
    writes.add((data.toList(), peerId));
  }

  @override
  Future<void> writeUdp(
    Uint8List data, {
    required String host,
    required int port,
  }) async {
    udpWrites.add((data.toList(), host, port));
  }

  @override
  Future<void> close() async {
    _opened = false;
    _peerList = const [];
    _open.add(false);
    _peers.add(const []);
  }

  @override
  Future<void> dispose() async {
    await close();
    await _incoming.close();
    await _peers.close();
    await _open.close();
    await _errors.close();
  }
}

class _MemoryStore implements SocketWorkspaceStore {
  @override
  SocketWorkspace? read() => null;

  @override
  Future<void> write(SocketWorkspace workspace) async {}
}

class _FakeFiles implements SerialFileGateway {
  @override
  Future<PickedBytes?> pickAny() async => null;

  @override
  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) async => null;

  @override
  Future<String?> pickText({required List<String> extensions}) async => null;

  @override
  Future<void> writeText({required String path, required String text}) async {}
}
