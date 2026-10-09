import 'log_level.dart';

class LoggerConfig {
  const LoggerConfig({
    required this.enableConsoleLog,
    required this.enableFileLog,
    required this.minLevel,
  });

  final bool enableConsoleLog;
  final bool enableFileLog;
  final LogLevel minLevel;

  LoggerConfig copyWith({
    bool? enableConsoleLog,
    bool? enableFileLog,
    LogLevel? minLevel,
  }) {
    return LoggerConfig(
      enableConsoleLog: enableConsoleLog ?? this.enableConsoleLog,
      enableFileLog: enableFileLog ?? this.enableFileLog,
      minLevel: minLevel ?? this.minLevel,
    );
  }

  static LoggerConfig forEnvironment({required bool isDev}) {
    if (isDev) {
      return const LoggerConfig(
        enableConsoleLog: true,
        enableFileLog: true,
        minLevel: LogLevel.debug,
      );
    }
    return const LoggerConfig(
      enableConsoleLog: false,
      enableFileLog: false,
      minLevel: LogLevel.warning,
    );
  }
}
