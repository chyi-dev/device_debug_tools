import 'dart:io';

import 'package:hive/hive.dart';

import '../repository/mqtt_console_repository.dart';
import 'idle_mqtt_gateway.dart';
import 'mqtt_client_gateway.dart';
import 'mqtt_file_gateway.dart';
import 'mqtt_gateway.dart';
import 'mqtt_workspace_store.dart';

abstract class MqttSessionFactory {
  MqttConsoleRepository open(String storageKey);
}

class PlatformMqttSessionFactory implements MqttSessionFactory {
  PlatformMqttSessionFactory({
    required Box<dynamic> settings,
    MqttFileGateway? files,
  }) : _settings = settings,
       _files = files ?? MqttFileGateway();

  final Box<dynamic> _settings;
  final MqttFileGateway _files;

  @override
  MqttConsoleRepository open(String storageKey) {
    return MqttConsoleRepository(
      gateway: _gateway(),
      store: HiveMqttWorkspaceStore(_settings, storageKey: storageKey),
      files: _files,
    );
  }

  MqttGateway _gateway() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return IdleMqttGateway();
    }
    return MqttClientGateway();
  }
}
