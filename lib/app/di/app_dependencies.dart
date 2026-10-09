import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/storage_keys.dart';
import '../../core/storage/user_prefs_storage.dart';
import '../../features/serial/data/file_selector_gateway.dart';
import '../../features/serial/data/libserialport_gateway.dart';
import '../../features/serial/data/serial_port_gateway.dart';
import '../../features/serial/data/serial_workspace_store.dart';
import '../../features/serial/data/win32_serial_gateway.dart';
import '../../features/serial/repository/serial_console_repository.dart';

/// 全局依赖提供者；新增全局 Repository / Service 在此注册。
class AppDependencies extends StatelessWidget {
  const AppDependencies({
    super.key,
    required this.userPrefsStorage,
    required this.child,
  });

  final UserPrefsStorage userPrefsStorage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UserPrefsStorage>.value(value: userPrefsStorage),
        RepositoryProvider<SerialConsoleRepository>(
          create: (_) => SerialConsoleRepository(
            ports: _serialPorts(),
            files: FileSelectorGateway(),
            store: SerialWorkspaceStore(
              Hive.box<dynamic>(StorageKeys.settingsBox),
            ),
          ),
        ),
      ],
      child: child,
    );
  }
}

SerialPortGateway _serialPorts() =>
    Platform.isWindows ? Win32SerialGateway() : LibserialportGateway();
