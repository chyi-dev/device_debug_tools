import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/logger/app_logger.dart';
import '../../core/logger/log_category.dart';
import '../../core/logger/logger_config.dart';
import '../../core/storage/hive_storage.dart';
import '../../core/storage/storage_keys.dart';
import '../../core/storage/user_prefs_storage.dart';
import '../../core/widgets/app_loading.dart';
import '../../env/app_env.dart';
import '../../i18n/i18n.dart';
import '../app.dart';
import '../cubit/app_cubit.dart';
import '../di/app_dependencies.dart';

Future<void> bootstrap({bool isDev = false}) async {
  WidgetsFlutterBinding.ensureInitialized();
  appIsDev = isDev;

  await initHive();
  final userPrefsStorage =
      UserPrefsStorage(Hive.box<dynamic>(StorageKeys.settingsBox));

  var loggerConfig = LoggerConfig.forEnvironment(isDev: isDev);
  final fileLogPref = userPrefsStorage.readEnableFileLog();
  if (fileLogPref != null) {
    loggerConfig = loggerConfig.copyWith(enableFileLog: fileLogPref);
  }
  AppLogger.i.initialize(loggerConfig);

  await LocaleSettings.setLocale(
    AppCubit.localeFromTag(userPrefsStorage.readLocale()),
  );

  configureEasyLoading();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.i.error(
      details.exceptionAsString(),
      category: LogCategory.ui,
      stackTrace: details.stack,
    );
  };

  AppLogger.i.info('Bootstrap completed (isDev=$isDev)');

  runApp(buildAppRoot(userPrefsStorage: userPrefsStorage));
}

/// 应用根组件树，测试中可直接复用。
Widget buildAppRoot({required UserPrefsStorage userPrefsStorage}) {
  return AppDependencies(
    userPrefsStorage: userPrefsStorage,
    child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AppCubit(userPrefsStorage: userPrefsStorage),
        ),
      ],
      child: TranslationProvider(child: const MyApp()),
    ),
  );
}
