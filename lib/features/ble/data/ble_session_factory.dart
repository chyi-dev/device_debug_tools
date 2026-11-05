import 'dart:io';

import 'package:hive/hive.dart';

import '../../serial/data/file_selector_gateway.dart';
import '../../serial/data/serial_file_gateway.dart';
import '../repository/ble_console_repository.dart';
import 'ble_gateway.dart';
import 'ble_workspace_store.dart';
import 'idle_ble_gateway.dart';
import 'universal_ble_gateway.dart';

abstract class BleSessionFactory {
  BleConsoleRepository open(String storageKey);
}

class PlatformBleSessionFactory implements BleSessionFactory {
  PlatformBleSessionFactory({
    required Box<dynamic> settings,
    SerialFileGateway? files,
  }) : _settings = settings,
       _files = files ?? FileSelectorGateway();

  final Box<dynamic> _settings;
  final SerialFileGateway _files;

  @override
  BleConsoleRepository open(String storageKey) {
    return BleConsoleRepository(
      gateway: _gateway(),
      store: HiveBleWorkspaceStore(_settings, storageKey: storageKey),
      files: _files,
    );
  }

  BleGateway _gateway() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return IdleBleGateway();
    }
    return UniversalBleGateway();
  }
}
