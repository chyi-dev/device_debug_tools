import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/storage/storage_keys.dart';
import '../../core/storage/user_prefs_storage.dart';
import '../../features/home/data/home_tab_store.dart';
import '../../features/serial/data/file_selector_gateway.dart';
import '../../features/serial/data/serial_session_factory.dart';

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
        RepositoryProvider<SerialSessionFactory>(
          create: (_) => PlatformSerialSessionFactory(
            settings: Hive.box<dynamic>(StorageKeys.settingsBox),
            files: FileSelectorGateway(),
          ),
        ),
        RepositoryProvider<HomeTabStore>(
          create: (_) =>
              HiveHomeTabStore(Hive.box<dynamic>(StorageKeys.settingsBox)),
        ),
      ],
      child: child,
    );
  }
}
