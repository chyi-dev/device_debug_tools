import 'dart:io';

import 'package:hive/hive.dart';

import '../model/socket_models.dart';
import '../repository/socket_console_repository.dart';
import 'idle_socket_gateway.dart';
import 'io_socket_gateway.dart';
import 'socket_file_gateway.dart';
import 'socket_gateway.dart';
import 'socket_workspace_store.dart';

abstract class SocketSessionFactory {
  SocketConsoleRepository open(String storageKey, {required SocketProtocol protocol});
}

class PlatformSocketSessionFactory implements SocketSessionFactory {
  PlatformSocketSessionFactory({
    required Box<dynamic> settings,
    SocketFileGateway? files,
  }) : _settings = settings,
       _files = files ?? SocketFileGateway();

  final Box<dynamic> _settings;
  final SocketFileGateway _files;

  @override
  SocketConsoleRepository open(
    String storageKey, {
    required SocketProtocol protocol,
  }) {
    return SocketConsoleRepository(
      gateway: _gateway(),
      store: SocketWorkspaceStore(_settings, storageKey: storageKey),
      files: _files,
    );
  }

  SocketGateway _gateway() {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return IdleSocketGateway();
    }
    return IoSocketGateway();
  }
}
