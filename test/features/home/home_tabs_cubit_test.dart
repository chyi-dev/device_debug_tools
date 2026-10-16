import 'dart:async';
import 'dart:typed_data';

import 'package:device_debug_tools/core/storage/storage_keys.dart';
import 'package:device_debug_tools/features/home/cubit/home_tabs_cubit.dart';
import 'package:device_debug_tools/features/home/data/home_tab_store.dart';
import 'package:device_debug_tools/features/home/model/connection_kind.dart';
import 'package:device_debug_tools/features/home/model/home_tab.dart';
import 'package:device_debug_tools/features/serial/data/serial_file_gateway.dart';
import 'package:device_debug_tools/features/serial/data/serial_port_gateway.dart';
import 'package:device_debug_tools/features/serial/data/serial_session_factory.dart';
import 'package:device_debug_tools/features/serial/data/serial_workspace_store.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:device_debug_tools/features/serial/repository/serial_console_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _MemoryTabs tabs;
  late _FakeSessions sessions;
  late HomeTabsCubit cubit;

  setUp(() async {
    tabs = _MemoryTabs();
    sessions = _FakeSessions();
    cubit = HomeTabsCubit(sessions: sessions, tabs: tabs);
    await cubit.start();
  });

  tearDown(() async {
    await cubit.close();
  });

  test('启动时只有一个串口页签，并读取原工作区', () {
    expect(cubit.state.tabs, hasLength(1));
    expect(cubit.state.tabs.single.kind, ConnectionKind.serial);
    expect(cubit.state.tabs.single.storageKey, StorageKeys.serialWorkspace);
    expect(cubit.state.activeId, cubit.state.tabs.single.id);
  });

  test('同类型可以再新增一个串口页签', () async {
    final first = cubit.state.activeId;
    final result = await cubit.add(ConnectionKind.serial);
    expect(result, HomeTabAddResult.opened);
    expect(cubit.state.tabs, hasLength(2));
    expect(cubit.state.tabs.map((tab) => tab.kind).toSet(), {
      ConnectionKind.serial,
    });
    expect(
      cubit.state.tabs.last.storageKey,
      isNot(StorageKeys.serialWorkspace),
    );
    expect(cubit.state.activeId, isNot(first));
    expect(sessions.opened, [
      StorageKeys.serialWorkspace,
      cubit.state.tabs.last.storageKey,
    ]);
  });

  test('未实现的协议不能创建页签', () async {
    expect(await cubit.add(ConnectionKind.ble), HomeTabAddResult.unsupported);
    expect(await cubit.add(ConnectionKind.mqtt), HomeTabAddResult.unsupported);
    expect(
      await cubit.add(ConnectionKind.webSocket),
      HomeTabAddResult.unsupported,
    );
    expect(cubit.state.tabs, hasLength(1));
  });

  test('关闭后再新增串口，仍然加载原来的工作区', () async {
    final id = cubit.state.tabs.single.id;
    await cubit.closeTab(id);
    expect(cubit.state.tabs, isEmpty);
    expect(await cubit.add(ConnectionKind.serial), HomeTabAddResult.opened);
    expect(cubit.state.tabs, hasLength(1));
    expect(cubit.state.tabs.single.storageKey, StorageKeys.serialWorkspace);
  });

  test('重命名写入页签记录，空名称则清除', () async {
    final id = cubit.state.tabs.single.id;
    await cubit.rename(id, '  工位 A  ');
    expect(cubit.state.tabs.single.label, '工位 A');
    expect(tabs.saved?.tabs.single.label, '工位 A');
    expect(cubit.state.tabs, hasLength(1));

    await cubit.rename(id, '   ');
    expect(cubit.state.tabs.single.label, isNull);
    expect(tabs.saved?.tabs.single.label, isNull);
    expect(cubit.state.tabs, hasLength(1));

    final legacy = HomeTab.fromJson({
      'id': 'old',
      'kind': 'serial',
      'storageKey': StorageKeys.serialWorkspace,
    });
    expect(legacy?.label, isNull);
  });
}

class _MemoryTabs implements HomeTabStore {
  HomeTabsSnapshot? saved;

  @override
  HomeTabsSnapshot? read() => saved;

  @override
  Future<void> write(HomeTabsSnapshot snapshot) async {
    saved = snapshot;
  }
}

class _FakeSessions implements SerialSessionFactory {
  final List<String> opened = [];

  @override
  SerialConsoleRepository open(String storageKey) {
    opened.add(storageKey);
    return SerialConsoleRepository(
      ports: _FakePorts(),
      files: _FakeFiles(),
      store: _MemoryWorkspace(),
    );
  }
}

class _FakePorts implements SerialPortGateway {
  final _incoming = StreamController<Uint8List>.broadcast();

  @override
  Future<void> apply(SerialLinkConfig config) async {}

  @override
  Future<void> close() async {}

  @override
  Stream<Uint8List> get incoming => _incoming.stream;

  @override
  bool get isOpen => false;

  @override
  Future<List<SerialPortInfo>> listPorts() async => const [];

  @override
  Future<SerialOpenResult> open(SerialLinkConfig config) async =>
      SerialOpenResult.full;

  @override
  PinLevels readPins() => const PinLevels();

  @override
  Future<void> write(Uint8List data) async {}
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

class _MemoryWorkspace implements SerialWorkspaceStore {
  @override
  SerialWorkspace? read() => null;

  @override
  Future<void> write(SerialWorkspace workspace) async {}
}
