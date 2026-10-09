import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import '../logger/app_logger.dart';
import '../logger/log_category.dart';
import 'app_paths.dart';
import 'storage_keys.dart';

Future<void> initHive() async {
  final base = await AppPaths.dataDirectory();
  Hive.init(p.join(base.path, 'hive'));
  await Hive.openBox<dynamic>(StorageKeys.settingsBox);
  await Hive.openBox<dynamic>(StorageKeys.cacheBox);
  AppLogger.i.info('Hive initialized', category: LogCategory.database);
}
