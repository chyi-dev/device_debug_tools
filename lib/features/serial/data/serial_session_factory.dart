import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import '../model/serial_models.dart';
import '../repository/serial_console_repository.dart';
import 'file_selector_gateway.dart';
import 'libserialport_gateway.dart';
import 'serial_file_gateway.dart';
import 'serial_port_gateway.dart';
import 'serial_workspace_store.dart';
import 'win32_serial_gateway.dart';

/// 按工作区键创建一个串口会话。每个页签必须单独持有 Gateway，才能同时打开多个串口。
abstract class SerialSessionFactory {
  SerialConsoleRepository open(String storageKey);
}

class PlatformSerialSessionFactory implements SerialSessionFactory {
  PlatformSerialSessionFactory({
    required Box<dynamic> settings,
    SerialFileGateway? files,
  }) : _settings = settings,
       _files = files ?? FileSelectorGateway();

  final Box<dynamic> _settings;
  final SerialFileGateway _files;

  @override
  SerialConsoleRepository open(String storageKey) {
    return SerialConsoleRepository(
      ports: _ports(),
      files: _files,
      store: SerialWorkspaceStore(_settings, storageKey: storageKey),
    );
  }

  /// 组件测试里没有 serialport.dll，直接枚举会卡住。
  SerialPortGateway _ports() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return _IdleSerialPorts();
    }
    return Platform.isWindows ? Win32SerialGateway() : LibserialportGateway();
  }
}

class _IdleSerialPorts implements SerialPortGateway {
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
