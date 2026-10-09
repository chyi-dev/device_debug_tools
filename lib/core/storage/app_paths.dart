import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 应用数据根目录（桌面端使用系统的 Application Support 目录，而非用户“文档”目录）。
abstract final class AppPaths {
  static Directory? _override;

  /// 测试时注入临时目录。
  static void overrideDataDirectory(Directory dir) => _override = dir;

  static Future<Directory> dataDirectory() async {
    final dir = _override ?? await getApplicationSupportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
