import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/storage/user_prefs_storage.dart';
import '../data/github_release_client.dart';
import '../data/update_launcher.dart';
import '../model/app_release.dart';
import '../model/sem_ver.dart';

/// 更新检查结果。
sealed class UpdateCheckOutcome {
  const UpdateCheckOutcome();
}

class UpdateCheckUpToDate extends UpdateCheckOutcome {
  const UpdateCheckUpToDate({required this.currentVersion});

  final String currentVersion;
}

class UpdateCheckAvailable extends UpdateCheckOutcome {
  const UpdateCheckAvailable({
    required this.currentVersion,
    required this.release,
    required this.canInstall,
  });

  final String currentVersion;
  final AppRelease release;

  /// Windows 且附件存在时可直接下载安装。
  final bool canInstall;
}

/// 编排版本读取、远端检查、下载与启动。
class UpdateRepository {
  UpdateRepository({
    required UserPrefsStorage prefs,
    GithubReleaseClient? client,
  }) : _prefs = prefs,
       _client = client ?? GithubReleaseClient();

  final UserPrefsStorage _prefs;
  final GithubReleaseClient _client;

  Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return SemVer.normalize(info.version) ?? info.version;
  }

  bool shouldSilentCheck({DateTime? now}) {
    final last = _prefs.readUpdateLastCheckAt();
    if (last == null) return true;
    final at = now ?? DateTime.now();
    return at.difference(last) >= AppConstants.updateCheckInterval;
  }

  bool isDismissed(String version) =>
      _prefs.readUpdateDismissedVersion() == SemVer.normalize(version);

  Future<void> markChecked({DateTime? now}) =>
      _prefs.saveUpdateLastCheckAt(now ?? DateTime.now());

  Future<void> dismissVersion(String version) async {
    final normalized = SemVer.normalize(version) ?? version;
    await _prefs.saveUpdateDismissedVersion(normalized);
  }

  Future<UpdateCheckOutcome> checkLatest() async {
    try {
      final current = await currentVersion();
      final release = await _client.fetchLatest();
      await markChecked();
      if (!SemVer.isNewer(release.version, current)) {
        return UpdateCheckUpToDate(currentVersion: current);
      }
      final canInstall = Platform.isWindows && release.hasWindowsSetup;
      return UpdateCheckAvailable(
        currentVersion: current,
        release: release,
        canInstall: canInstall,
      );
    } on AppException {
      rethrow;
    } catch (e, s) {
      AppLogger.i.error(
        '检查更新失败',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
      throw NetworkException('检查更新失败：$e');
    }
  }

  Future<File> downloadWindowsSetup(
    AppRelease release, {
    DownloadProgress? onProgress,
  }) async {
    final url = release.windowsSetupUrl;
    final name = release.windowsSetupName;
    if (url == null || name == null) {
      throw NetworkException('当前 Release 没有 Windows 安装包');
    }
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'device_debug_tools_update', name));
    try {
      return await _client.downloadAsset(
        url: Uri.parse(url),
        destination: file,
        expectedSize: release.windowsSetupSize,
        onProgress: onProgress,
      );
    } on AppException {
      rethrow;
    } catch (e, s) {
      AppLogger.i.error(
        '下载安装包失败',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
      throw NetworkException('下载安装包失败：$e');
    }
  }

  Future<void> openReleasePage(AppRelease release) =>
      UpdateLauncher.openUrl(release.htmlUrl);

  Future<void> launchInstallerAndExit(File installer) async {
    await UpdateLauncher.startInstaller(installer.path);
    exit(0);
  }

  void dispose() => _client.close();
}
