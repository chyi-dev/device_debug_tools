import 'dart:async';
import 'dart:typed_data';

import 'package:device_debug_tools/features/ble/cubit/ble_console_cubit.dart';
import 'package:device_debug_tools/features/ble/data/ble_gateway.dart';
import 'package:device_debug_tools/features/ble/data/ble_workspace_store.dart';
import 'package:device_debug_tools/features/ble/model/ble_models.dart';
import 'package:device_debug_tools/features/ble/repository/ble_console_repository.dart';
import 'package:device_debug_tools/features/serial/data/serial_file_gateway.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeGateway gateway;
  late BleConsoleCubit cubit;

  const write = BleCharacteristicInfo(
    uuid: 'FFF2',
    serviceUuid: 'FFF0',
    name: 'RX Write',
    canWrite: true,
    canWriteWithoutResponse: true,
  );
  const notify = BleCharacteristicInfo(
    uuid: 'FFF1',
    serviceUuid: 'FFF0',
    name: 'TX Notify',
    canNotify: true,
  );

  setUp(() async {
    gateway = _FakeGateway(
      services: [
        const BleServiceInfo(
          uuid: 'FFF0',
          name: '透传',
          characteristics: [notify, write],
        ),
      ],
    );
    cubit = BleConsoleCubit(
      repository: BleConsoleRepository(
        gateway: gateway,
        store: _MemoryStore(),
        files: _FakeFiles(),
      ),
      scanDuration: Duration.zero,
    );
    await cubit.start();
  });

  tearDown(() async {
    await cubit.close();
  });

  test('未钉 Write 时发送拦截', () async {
    gateway.emitDevice(
      const BleDeviceInfo(id: 'a', name: 'Sensor-A4', address: 'AA'),
    );
    await cubit.scan();
    cubit.selectDevice('a');
    await cubit.toggleConnect();
    expect(cubit.state.connected, isTrue);
    await cubit.sendFromEditor();
    expect(cubit.state.toast?.kind, BleNoticeKind.noWrite);
    expect(gateway.writes, isEmpty);
  });

  test('钉住 Write 后可以发送；未钉 Notify 给出提示', () async {
    gateway.emitDevice(
      const BleDeviceInfo(id: 'a', name: 'Sensor-A4', address: 'AA'),
    );
    await cubit.scan();
    cubit.selectDevice('a');
    await cubit.toggleConnect();
    await cubit.pinWrite(write);
    cubit.setTxText('A5 01');
    await cubit.sendFromEditor();
    expect(gateway.writes, isNotEmpty);
    expect(cubit.state.toast?.kind, BleNoticeKind.sentNoNotify);
  });

  test('钉住 Notify 后回包进入日志', () async {
    gateway.emitDevice(
      const BleDeviceInfo(id: 'a', name: 'Sensor-A4', address: 'AA'),
    );
    await cubit.scan();
    cubit.selectDevice('a');
    await cubit.toggleConnect();
    await cubit.pinNotify(notify);
    await cubit.pinWrite(write);
    cubit.setTxText('A5 01');
    await cubit.sendFromEditor();
    gateway.emitNotify(
      BleNotifyEvent(
        deviceId: 'a',
        serviceUuid: 'FFF0',
        characteristicUuid: 'FFF1',
        value: Uint8List.fromList([0xA5, 0x5A]),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.lines.any((line) => line.dir == LogDir.rx), isTrue);
  });

  test('旧工作区校验页签回落到快捷指令', () {
    final workspace = BleWorkspace.fromJson({'tab': 'calc'});
    expect(workspace.tab, ToolTab.quick);
    cubit.setTab(ToolTab.calc);
    expect(cubit.state.tab, ToolTab.quick);
  });
}

class _FakeGateway implements BleGateway {
  _FakeGateway({required this.services});

  final List<BleServiceInfo> services;
  final writes = <Uint8List>[];
  BleDeviceInfo? pending;
  final _scans = StreamController<BleDeviceInfo>.broadcast();
  final _notifications = StreamController<BleNotifyEvent>.broadcast();
  final _connections = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();

  @override
  Stream<BleDeviceInfo> get scans => _scans.stream;

  @override
  Stream<BleNotifyEvent> get notifications => _notifications.stream;

  @override
  Stream<bool> get connections => _connections.stream;

  @override
  Stream<String> get errors => _errors.stream;

  void emitDevice(BleDeviceInfo device) {
    pending = device;
    _scans.add(device);
  }

  void emitNotify(BleNotifyEvent event) => _notifications.add(event);

  @override
  Future<bool> adapterReady() async => true;

  @override
  Future<void> startScan() async {
    final device = pending;
    if (device != null) _scans.add(device);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<void> stopScan() async {}

  @override
  Future<int> connect(String deviceId, {required int mtu}) async => mtu;

  @override
  Future<void> disconnect() async {}

  @override
  Future<List<BleServiceInfo>> discover() async => services;

  @override
  Future<void> setNotify({
    required String serviceUuid,
    required String characteristicUuid,
    required bool enable,
  }) async {}

  @override
  Future<void> write({
    required String serviceUuid,
    required String characteristicUuid,
    required Uint8List data,
    required bool withResponse,
  }) async {
    writes.add(data);
  }

  @override
  Future<void> dispose() async {
    await _scans.close();
    await _notifications.close();
    await _connections.close();
    await _errors.close();
  }
}

class _MemoryStore implements BleWorkspaceStore {
  @override
  BleWorkspace? read() => null;

  @override
  Future<void> write(BleWorkspace workspace) async {}
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
