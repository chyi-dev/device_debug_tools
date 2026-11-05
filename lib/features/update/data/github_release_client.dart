import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../../../core/exception/app_exception.dart';
import '../../../i18n/i18n.dart';
import '../model/app_release.dart';
import 'github_release_parser.dart';

typedef DownloadProgress = void Function(int received, int? total);

/// 匿名访问 GitHub Releases API 与附件下载。
class GithubReleaseClient {
  GithubReleaseClient({
    HttpClient? httpClient,
    this.owner = AppConstants.githubOwner,
    this.repo = AppConstants.githubRepo,
    this.timeout = const Duration(seconds: 20),
  }) : _http = httpClient ?? HttpClient();

  final HttpClient _http;
  final String owner;
  final String repo;
  final Duration timeout;

  Uri get _latestUri => Uri.https(
    'api.github.com',
    '/repos/$owner/$repo/releases/latest',
  );

  Future<AppRelease> fetchLatest() async {
    final request = await _http.getUrl(_latestUri).timeout(timeout);
    request.headers.set(HttpHeaders.userAgentHeader, 'device_debug_tools');
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final response = await request.close().timeout(timeout);
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      if (response.statusCode == HttpStatus.notFound) {
        throw NetworkException(t.update.noRelease);
      }
      throw NetworkException(
        t.update.checkFailed(code: response.statusCode),
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw NetworkException('GitHub Releases 响应格式无效');
    }
    final release = parseGithubRelease(decoded);
    if (release == null) {
      throw NetworkException('无法解析最新 Release');
    }
    return release;
  }

  /// 下载附件到 [destination]，按 [expectedSize] 核对长度（若提供）。
  Future<File> downloadAsset({
    required Uri url,
    required File destination,
    int? expectedSize,
    DownloadProgress? onProgress,
  }) async {
    await destination.parent.create(recursive: true);
    final request = await _http.getUrl(url).timeout(timeout);
    request.followRedirects = true;
    request.maxRedirects = 5;
    request.headers.set(HttpHeaders.userAgentHeader, 'device_debug_tools');
    final response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      throw NetworkException(
        '下载安装包失败（HTTP ${response.statusCode}）',
      );
    }
    final total = response.contentLength >= 0
        ? response.contentLength
        : expectedSize;
    final sink = destination.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.timeout(timeout)) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
      await sink.close();
    } catch (e) {
      await sink.close();
      if (await destination.exists()) {
        await destination.delete();
      }
      if (e is NetworkException) rethrow;
      throw NetworkException('下载安装包失败：$e');
    }
    if (expectedSize != null && received != expectedSize) {
      if (await destination.exists()) {
        await destination.delete();
      }
      throw NetworkException(
        '安装包大小不符（期望 $expectedSize，实际 $received）',
      );
    }
    return destination;
  }

  void close() => _http.close(force: true);
}
