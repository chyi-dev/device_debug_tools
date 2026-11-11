import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_debug_tools/app/theme/app_theme.dart';
import 'package:device_debug_tools/core/storage/storage_keys.dart';
import 'package:device_debug_tools/core/storage/user_prefs_storage.dart';
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
import 'package:device_debug_tools/features/socket/data/idle_socket_gateway.dart';
import 'package:device_debug_tools/features/socket/data/socket_file_gateway.dart';
import 'package:device_debug_tools/features/socket/data/socket_session_factory.dart';
import 'package:device_debug_tools/features/socket/data/socket_workspace_store.dart';
import 'package:device_debug_tools/features/socket/model/socket_models.dart';
import 'package:device_debug_tools/features/socket/repository/socket_console_repository.dart';
import 'package:device_debug_tools/features/license/cubit/license_cubit.dart';
import 'package:device_debug_tools/features/license/cubit/license_state.dart';
import 'package:device_debug_tools/features/license/data/device_code_source.dart';
import 'package:device_debug_tools/features/license/repository/license_repository.dart';
import 'package:device_debug_tools/features/mcp/cubit/mcp_cubit.dart';
import 'package:device_debug_tools/features/mcp/data/mcp_settings_store.dart';
import 'package:device_debug_tools/features/mcp/repository/mcp_repository.dart';
import 'package:device_debug_tools/features/update/cubit/update_cubit.dart';
import 'package:device_debug_tools/features/update/repository/update_repository.dart';
import 'package:device_debug_tools/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late UserPrefsStorage prefs;

  setUp(() async {
    await LocaleSettings.setLocale(AppLocale.zh);
    tempDir = await Directory.systemTemp.createTemp('ddt_home_');
    Hive.init(tempDir.path);
    final box = await Hive.openBox<dynamic>(StorageKeys.settingsBox);
    prefs = UserPrefsStorage(box);
  });

  tearDown(() async {
    if (Hive.isBoxOpen(StorageKeys.settingsBox)) {
      await Hive.close();
    }
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('新增 BLE 页签后指针事件不触发未布局 hit test', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final box = Hive.box<dynamic>(StorageKeys.settingsBox);
    final licenseRepo = LicenseRepository(
      settings: box,
      deviceCodes: _FixedDeviceCode('ABCD-EFGH-IJKL-MNOP'),
    );
    // 已激活：不弹支持窗，聚焦页签命中测试。
    final licenseCubit = _ActivatedLicenseCubit(repository: licenseRepo);
    await licenseCubit.start();
    addTearDown(licenseCubit.close);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          theme: AppTheme.light,
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<UserPrefsStorage>.value(value: prefs),
              RepositoryProvider<SerialSessionFactory>.value(
                value: _FakeSerial(),
              ),
              RepositoryProvider<BleSessionFactory>.value(value: _FakeBle()),
              RepositoryProvider<MqttSessionFactory>.value(value: _FakeMqtt()),
              RepositoryProvider<SocketSessionFactory>.value(
                value: _FakeSockets(),
              ),
              RepositoryProvider<HomeTabStore>.value(value: _MemoryTabs()),
              RepositoryProvider<UpdateRepository>(
                create: (_) => UpdateRepository(prefs: prefs),
              ),
              RepositoryProvider<LicenseRepository>.value(value: licenseRepo),
              RepositoryProvider<McpRepository>(
                create: (_) => McpRepository(
                  store: McpSettingsStore(box),
                ),
              ),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => UpdateCubit(
                    repository: context.read<UpdateRepository>(),
                  ),
                ),
                BlocProvider<LicenseCubit>.value(value: licenseCubit),
                BlocProvider(
                  create: (context) => McpCubit(
                    repository: context.read<McpRepository>(),
                  ),
                ),
              ],
              child: const HomePage(),
            ),
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

class _FixedDeviceCode extends DeviceCodeSource {
  _FixedDeviceCode(this.code) : super();

  final String code;

  @override
  Future<String> resolve() async => code;
}

class _ActivatedLicenseCubit extends LicenseCubit {
  _ActivatedLicenseCubit({required super.repository});

  @override
  Future<void> start() async {
    emit(
      LicenseState(
        deviceCode: 'ABCD-EFGH-IJKL-MNOP',
        showUnlicensedBanner: false,
        inTrial: false,
        trialEndsOn: DateTime.utc(2030, 1, 1),
        licenseExpiresOn: DateTime.utc(2030, 1, 1),
        ready: true,
      ),
    );
  }
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

class _FakeSockets implements SocketSessionFactory {
  @override
  SocketConsoleRepository open(
    String storageKey, {
    required SocketProtocol protocol,
  }) {
    return SocketConsoleRepository(
      gateway: IdleSocketGateway(),
      store: _MemorySocketStore(),
      files: SocketFileGateway(files: _FakeFiles()),
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

class _MemorySocketStore implements SocketWorkspaceStore {
  @override
  SocketWorkspace? read() => null;

  @override
  Future<void> write(SocketWorkspace workspace) async {}
}
