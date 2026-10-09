import 'dart:async';
import 'dart:typed_data';

import 'package:device_debug_tools/core/exception/app_exception.dart';
import 'package:device_debug_tools/features/serial/cubit/serial_console_cubit.dart';
import 'package:device_debug_tools/features/serial/data/serial_bytes.dart';
import 'package:device_debug_tools/features/serial/data/serial_file_gateway.dart';
import 'package:device_debug_tools/features/serial/data/serial_port_gateway.dart';
import 'package:device_debug_tools/features/serial/data/serial_workspace_store.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:device_debug_tools/features/serial/repository/serial_console_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakePorts ports;
  late SerialConsoleCubit cubit;

  setUp(() async {
    ports = _FakePorts();
    cubit = SerialConsoleCubit(
      repository: SerialConsoleRepository(
        ports: ports,
        files: _FakeFiles(),
        store: _MemoryStore(),
      ),
    );
    await cubit.start();
  });

  tearDown(() async {
    await cubit.close();
  });

  test('串口关闭时发送被拦截且不记历史', () async {
    await cubit.sendFromEditor();
    expect(cubit.state.toast?.kind, SerialNoticeKind.portClosedSend);
    expect(cubit.state.lines.where((line) => line.dir == LogDir.tx), isEmpty);
    expect(cubit.state.history, isEmpty);
  });

  test('发送按钮记入历史，快捷指令不记入', () async {
    cubit.setTxText('A5 01 00 00 01 07');
    cubit.upsertQuick(
      const QuickCommand(
        id: 'q1',
        name: '读取温湿度',
        data: 'A5 01 00 00 01 07',
        format: DataFormat.hex,
        key: 'F1',
      ),
    );
    await cubit.toggleOpen();
    await cubit.sendFromEditor();
    expect(cubit.state.history.single.text, 'A5 01 00 00 01 07');
    expect(cubit.state.txCount, 6);
    final before = cubit.state.history.length;
    await cubit.sendQuick('q1');
    expect(cubit.state.history.length, before);
    expect(ports.written, hasLength(2));
  });

  test('收到匹配帧后按延时自动应答', () async {
    cubit.upsertRule(
      const ReplyRule(
        id: 'r1',
        name: '温湿度回包确认',
        match: MatchMode.prefix,
        pattern: 'A5 5A 03',
        enabled: true,
        hits: 0,
        replies: [
          ReplyStep(data: 'A5 A0 00 A0', delayMs: 80),
          ReplyStep(data: 'A5 A1 01 A2', delayMs: 120),
        ],
      ),
    );
    await cubit.toggleOpen();
    ports.emit(Uint8List.fromList([0xA5, 0x5A, 0x03, 0x11]));
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(cubit.state.rules.firstWhere((rule) => rule.id == 'r1').hits, 1);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(ports.written.map(SerialBytes.toHex), contains('A5 A0 00 A0'));
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(ports.written.map(SerialBytes.toHex), contains('A5 A1 01 A2'));
  });

  test('降级打开成功时端口为打开并提示部分参数', () async {
    ports.openResult = SerialOpenResult.partial;
    await cubit.toggleOpen();
    expect(cubit.state.open, isTrue);
    expect(cubit.state.toast?.kind, SerialNoticeKind.configPartial);
  });

  test('参数全失败时走 configFailed 且端口仍关闭', () async {
    ports.openError = DeviceConfigException('SetCommState failed');
    await cubit.toggleOpen();
    expect(cubit.state.open, isFalse);
    expect(cubit.state.toast?.kind, SerialNoticeKind.configFailed);
  });
}

class _FakePorts implements SerialPortGateway {
  final _incoming = StreamController<Uint8List>.broadcast();
  final written = <Uint8List>[];
  var opened = false;
  SerialOpenResult openResult = SerialOpenResult.full;
  Object? openError;

  void emit(Uint8List bytes) => _incoming.add(bytes);

  @override
  Future<void> apply(SerialLinkConfig config) async {}

  @override
  Future<void> close() async {
    opened = false;
  }

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  bool get isOpen => opened;

  @override
  Future<List<SerialPortInfo>> listPorts() async => const [
        SerialPortInfo(name: 'COM3', label: 'COM3 · test'),
      ];

  @override
  Future<SerialOpenResult> open(SerialLinkConfig config) async {
    final error = openError;
    if (error != null) throw error;
    opened = true;
    return openResult;
  }

  @override
  PinLevels readPins() => const PinLevels(dcd: true);

  @override
  Future<void> write(Uint8List data) async {
    written.add(Uint8List.fromList(data));
  }
}

class _FakeFiles implements SerialFileGateway {
  @override
  Future<PickedBytes?> pickAny() async => null;

  @override
  Future<String?> pickSave({
    required String suggestedName,
    required String extension,
  }) async =>
      null;

  @override
  Future<String?> pickText({required List<String> extensions}) async => null;

  @override
  Future<void> writeText({required String path, required String text}) async {}
}

class _MemoryStore implements SerialWorkspaceStore {
  SerialWorkspace? saved;

  @override
  SerialWorkspace? read() => saved;

  @override
  Future<void> write(SerialWorkspace workspace) async {
    saved = workspace;
  }
}
