/// 远端最新 Release 摘要。
class AppRelease {
  const AppRelease({
    required this.version,
    required this.htmlUrl,
    this.body,
    this.windowsSetupUrl,
    this.windowsSetupSize,
    this.windowsSetupName,
  });

  /// 规范化后的 `x.y.z`（无 `v`）。
  final String version;

  /// Release 页面地址。
  final String htmlUrl;

  /// Markdown 说明，可为空。
  final String? body;

  final String? windowsSetupUrl;
  final int? windowsSetupSize;
  final String? windowsSetupName;

  bool get hasWindowsSetup =>
      windowsSetupUrl != null && windowsSetupUrl!.isNotEmpty;
}
