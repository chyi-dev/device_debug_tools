import 'dart:io';

import '../../../core/exception/app_exception.dart';

/// 启动安装包或用系统浏览器打开 URL。
abstract final class UpdateLauncher {
  static Future<void> openUrl(String url) async {
    try {
      if (Platform.isWindows) {
        await Process.start(
          'cmd',
          ['/c', 'start', '', url],
          mode: ProcessStartMode.detached,
        );
      } else if (Platform.isMacOS) {
        await Process.start(
          'open',
          [url],
          mode: ProcessStartMode.detached,
        );
      } else {
        await Process.start(
          'xdg-open',
          [url],
          mode: ProcessStartMode.detached,
        );
      }
    } catch (e) {
      throw NetworkException('无法打开链接：$e');
    }
  }

  /// 以独立进程启动安装程序（不阻塞、不捕获输出）。
  static Future<void> startInstaller(String path) async {
    try {
      await Process.start(
        path,
        const [],
        mode: ProcessStartMode.detached,
      );
    } catch (e) {
      throw NetworkException('无法启动安装程序：$e');
    }
  }
}
