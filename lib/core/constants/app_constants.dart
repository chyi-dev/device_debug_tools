/// 应用级常量，避免 magic number 散落在 UI 与业务中。
abstract final class AppConstants {
  static const int maxLogRetentionDays = 7;
  static const int maxLogFileBytes = 10 * 1024 * 1024; // 10MB
  static const String appDataFolder = 'device_debug_tools';
}
