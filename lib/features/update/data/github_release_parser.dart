import '../../../core/constants/app_constants.dart';
import '../model/app_release.dart';
import '../model/sem_ver.dart';

/// 解析 GitHub `/releases/latest` JSON；纯函数，便于单测。
AppRelease? parseGithubRelease(Map<String, dynamic> json) {
  final tag = json['tag_name'] as String?;
  final htmlUrl = json['html_url'] as String?;
  if (tag == null || htmlUrl == null) return null;
  final version = SemVer.normalize(tag);
  if (version == null) return null;

  final body = json['body'] as String?;
  final assets = json['assets'];
  String? setupUrl;
  int? setupSize;
  String? setupName;
  final expected = AppConstants.windowsSetupAssetName(version);
  if (assets is List) {
    for (final raw in assets) {
      if (raw is! Map) continue;
      final name = raw['name'] as String?;
      final url = raw['browser_download_url'] as String?;
      if (name == null || url == null) continue;
      if (name == expected) {
        setupName = name;
        setupUrl = url;
        final size = raw['size'];
        if (size is int) {
          setupSize = size;
        } else if (size is num) {
          setupSize = size.toInt();
        }
        break;
      }
    }
  }

  return AppRelease(
    version: version,
    htmlUrl: htmlUrl,
    body: body?.trim().isEmpty == true ? null : body?.trim(),
    windowsSetupUrl: setupUrl,
    windowsSetupSize: setupSize,
    windowsSetupName: setupName,
  );
}
