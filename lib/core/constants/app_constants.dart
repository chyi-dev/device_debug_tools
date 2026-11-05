/// 应用级常量，避免 magic number 散落在 UI 与业务中。
abstract final class AppConstants {
  static const int maxLogRetentionDays = 7;
  static const int maxLogFileBytes = 10 * 1024 * 1024; // 10MB
  static const String appDataFolder = 'device_debug_tools';

  /// 更新检查用的公开 GitHub 仓库（owner/repo）。
  static const String githubOwner = 'chyi-dev';
  static const String githubRepo = 'device_debug_tools';
  static const String githubRepoUrl =
      'https://github.com/chyi-dev/device_debug_tools';

  /// 启动静默检查的最小间隔。
  static const Duration updateCheckInterval = Duration(hours: 24);

  /// Windows 安装包文件名：`device_debug_tools-<version>-setup.exe`。
  static String windowsSetupAssetName(String version) =>
      'device_debug_tools-$version-setup.exe';
}
