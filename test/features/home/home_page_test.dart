import 'dart:async';
import 'dart:typed_data';

import 'package:device_debug_tools/app/theme/app_theme.dart';
import 'package:device_debug_tools/features/ble/data/ble_session_factory.dart';
import 'package:device_debug_tools/features/ble/data/ble_workspace_store.dart';
import 'package:device_debug_tools/features/ble/data/idle_ble_gateway.dart';
import 'package:device_debug_tools/features/ble/model/ble_models.dart';
import 'package:device_debug_tools/features/ble/repository/ble_console_repository.dart';
import 'package:device_debug_tools/features/home/data/home_tab_store.dart';
import 'package:device_debug_tools/features/home/page/home_page.dart';
import 'package:device_debug_tools/features/mqtt/data/idle_mqtt_gateway.dart';
import 'package:device_debug_tools/features/mqtt/data/mqtt_file_gateway.dart';
import 'package:device_debug_tools/features/mqtt/data/mqtt_session_factory.dart';
import 'package:device_debug_tools/features/mqtt/data/mqtt_workspace_store.dart';
import 'package:device_debug_tools/features/mqtt/model/mqtt_models.dart';
import 'package:device_debug_tools/features/mqtt/repository/mqtt_console_repository.dart';
import 'package:device_debug_tools/features/serial/data/serial_file_gateway.dart';
import 'package:device_debug_tools/features/serial/data/serial_port_gateway.dart';
import 'package:device_debug_tools/features/serial/data/serial_session_factory.dart';
import 'package:device_debug_tools/features/serial/data/serial_workspace_store.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:device_debug_tools/features/serial/repository/serial_console_repository.dart';
import 'package:device_debug_tools/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.zh);
  });

  testWidgets('新增 BLE 页签后指针事件不触发未布局 hit test', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.light,
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<SerialSessionFactory>.value(
                value: _FakeSerial(),
              ),
              RepositoryProvider<BleSessionFactory>.value(value: _FakeBle()),
              RepositoryProvider<MqttSessionFactory>.value(value: _FakeMqtt()),
              RepositoryProvider<HomeTabStore>.value(value: _MemoryTabs()),
            ],
            child: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('串口设置'), findsOneWidget);

    await tester.tap(find.text('＋ 新增'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('蓝牙 BLE'));
    await tester.pump();
    await tester.pump();

    final gesture = await tester.startGesture(const Offset(240, 240));
    await tester.pump();
    await gesture.moveBy(const Offset(12, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('扫描'), findsWidgets);
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

class _FakeSerial implements SerialSessionFactory {
  @override
  SerialConsoleRepository open(String storageKey) {
    return SerialConsoleRepository(
      ports: _FakePorts(),
      files: _FakeFiles(),
      store: _MemorySerialStore(),
    );
  }
}

class _FakeBle implements BleSessionFactory {
  @override
  BleConsoleRepository open(String storageKey) {
    return BleConsoleRepository(
      gateway: IdleBleGateway(),
      store: _MemoryBleStore(),
      files: _FakeFiles(),
    );
  }
}

class _FakeMqtt implements MqttSessionFactory {
  @override
  MqttConsoleRepository open(String storageKey) {
    return MqttConsoleRepository(
      gateway: IdleMqttGateway(),
      store: _MemoryMqttStore(),
      files: MqttFileGateway(files: _FakeFiles()),
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

class _MemorySerialStore implements SerialWorkspaceStore {
  @override
  SerialWorkspace? read() => null;

  @override
  Future<void> write(SerialWorkspace workspace) async {}
}

class _MemoryBleStore implements BleWorkspaceStore {
  @override
  BleWorkspace? read() => null;

  @override
  Future<void> write(BleWorkspace workspace) async {}
}

class _MemoryMqttStore implements MqttWorkspaceStore {
  @override
  MqttWorkspace? read() => null;

  @override
  Future<void> write(MqttWorkspace workspace) async {}
}
