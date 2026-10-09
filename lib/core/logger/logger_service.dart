import 'dart:async';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:logger/logger.dart' as pkg;

import 'log_category.dart';
import 'log_level.dart';
import 'logger_config.dart';
import 'logger_storage.dart';

class LoggerService {
  LoggerService({required LoggerConfig config}) : _config = config;

  static final _timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  LoggerConfig _config;
  final _pkg = pkg.Logger(
    filter: pkg.ProductionFilter(),
    printer: pkg.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 3,
      lineLength: 120,
      colors: false,
      printEmojis: false,
    ),
    level: pkg.Level.all,
  );
  final _writeLock = _Lock();

  LoggerConfig get config => _config;

  void updateConfig(LoggerConfig config) {
    _config = config;
  }

  Future<void> log(
    LogLevel level,
    LogCategory category,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (!_config.minLevel.covers(level)) return;

    final ts = _timeFormat.format(DateTime.now());
    final line =
        '[$ts][${level.name.toUpperCase()}][${category.label}] $message';

    if (_config.enableConsoleLog) {
      _pkg.log(level.asPkg, line, error: error, stackTrace: stackTrace);
    }

    if (_config.enableFileLog) {
      await _writeLock.synchronized(() async {
        try {
          await LoggerStorage.pruneByRetention();
          final file = await LoggerStorage.currentLogFile();
          await LoggerStorage.enforceSizeLimit(file);
          final full =
              error != null ? '$line\n$error\n$stackTrace\n' : '$line\n';
          await file.writeAsString(full, mode: FileMode.append, flush: true);
        } catch (_) {
          // 日志系统自身异常不能再向外抛出，否则会导致递归记录。
        }
      });
    }
  }
}

extension on LogLevel {
  pkg.Level get asPkg => switch (this) {
        LogLevel.debug => pkg.Level.debug,
        LogLevel.info => pkg.Level.info,
        LogLevel.warning => pkg.Level.warning,
        LogLevel.error => pkg.Level.error,
      };
}

/// 串行化异步写入，避免并发写同一日志文件。
class _Lock {
  Future<void> _last = Future.value();

  Future<T> synchronized<T>(Future<T> Function() fn) {
    final result = _last.then((_) => fn());
    _last = result.then((_) {}, onError: (_) {});
    return result;
  }
}
