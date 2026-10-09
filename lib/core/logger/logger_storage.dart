import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../constants/app_constants.dart';
import '../storage/app_paths.dart';

/// 日志文件落盘与清理。
abstract final class LoggerStorage {
  static final _fileDateFormat = DateFormat('yyyy_MM_dd');
  static final _fileNamePattern = RegExp(r'app_(\d{4})_(\d{2})_(\d{2})\.log');

  static Future<Directory> logsDirectory() async {
    final base = await AppPaths.dataDirectory();
    final dir = Directory(p.join(base.path, 'logs'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String logFileNameFor(DateTime date) =>
      'app_${_fileDateFormat.format(date)}.log';

  static Future<File> currentLogFile() async {
    final dir = await logsDirectory();
    return File(p.join(dir.path, logFileNameFor(DateTime.now())));
  }

  /// 超过单文件上限时，将当前文件改名为 `.bak`，覆盖上一份备份。
  static Future<void> enforceSizeLimit(File file) async {
    if (!await file.exists()) return;
    if (await file.length() <= AppConstants.maxLogFileBytes) return;
    final backup = File('${file.path}.bak');
    if (await backup.exists()) await backup.delete();
    await file.rename(backup.path);
  }

  static Future<void> pruneByRetention() async {
    final dir = await logsDirectory();
    final now = DateTime.now();
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final m = _fileNamePattern.firstMatch(p.basename(entity.path));
      if (m == null) continue;
      final day = DateTime(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
      if (now.difference(day).inDays > AppConstants.maxLogRetentionDays) {
        await entity.delete();
      }
    }
  }

  /// 删除历史日志文件，保留 [keepFile]。
  static Future<void> clearOldLogs({File? keepFile}) async {
    final dir = await logsDirectory();
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      if (entity.path == keepFile?.path) continue;
      if (entity.path.endsWith('.log')) {
        await entity.delete();
      }
    }
  }
}
