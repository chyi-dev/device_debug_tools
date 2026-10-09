enum LogLevel {
  debug,
  info,
  warning,
  error,
}

extension LogLevelX on LogLevel {
  bool covers(LogLevel other) => index <= other.index;
}
