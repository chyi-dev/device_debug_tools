import 'package:device_debug_tools/core/constants/app_constants.dart';
import 'package:device_debug_tools/features/update/model/app_release.dart';
import 'package:device_debug_tools/features/update/model/sem_ver.dart';
import 'package:flutter_test/flutter_test.dart';

/// 覆盖「已是最新 / 有更新 / 有无 setup.exe」判定逻辑（不访问网络）。
void main() {
  AppRelease release({
    required String version,
    String? setupUrl,
  }) {
    return AppRelease(
      version: version,
      htmlUrl: 'https://github.com/chyi-dev/device_debug_tools/releases/tag/v$version',
      windowsSetupUrl: setupUrl,
      windowsSetupName: setupUrl == null
          ? null
          : AppConstants.windowsSetupAssetName(version),
      windowsSetupSize: setupUrl == null ? null : 100,
    );
  }

  test('远端不新于当前 → 已是最新', () {
    expect(SemVer.isNewer('1.0.0', '1.0.0'), isFalse);
    expect(SemVer.isNewer('1.0.0', '1.0.1'), isFalse);
  });

  test('远端更新且有 setup → 可安装', () {
    final remote = release(
      version: '1.1.0',
      setupUrl: 'https://example.com/setup.exe',
    );
    expect(SemVer.isNewer(remote.version, '1.0.0'), isTrue);
    expect(remote.hasWindowsSetup, isTrue);
  });

  test('远端更新但无 setup → 只能打开发布页', () {
    final remote = release(version: '1.1.0');
    expect(SemVer.isNewer(remote.version, '1.0.0'), isTrue);
    expect(remote.hasWindowsSetup, isFalse);
  });
}
