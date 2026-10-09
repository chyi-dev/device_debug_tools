import 'log_category.dart';
import 'log_level.dart';
import 'logger_config.dart';
import 'logger_service.dart';
import 'logger_storage.dart';

/// 全局日志入口，禁止 `print` / `debugPrint`。
class AppLogger {
  AppLogger._();

  static final AppLogger i = AppLogger._();

  LoggerService? _service;

  LoggerService get service => _service ??=
      LoggerService(config: LoggerConfig.forEnvironment(isDev: false));

  void initialize(LoggerConfig config) {
    _service = LoggerService(config: config);
  }

  void updateConfig(LoggerConfig config) {
    service.updateConfig(config);
  }

  void debug(
    String message, {
    LogCategory category = LogCategory.app,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.debug, category, message, error, stackTrace);

  void info(
    String message, {
    LogCategory category = LogCategory.app,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.info, category, message, error, stackTrace);

  void warning(
    String message, {
    LogCategory category = LogCategory.app,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.warning, category, message, error, stackTrace);

  void error(
    String message, {
    LogCategory category = LogCategory.app,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(LogLevel.error, category, message, error, stackTrace);

  void _log(
    LogLevel level,
    LogCategory category,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    service.log(level, category, message, error: error, stackTrace: stackTrace);
  }

  /// 删除历史日志，保留当前运行文件。
  static Future<void> clearLogs() async {
    final current = await LoggerStorage.currentLogFile();
    await LoggerStorage.clearOldLogs(keepFile: current);
  }
}
