import 'package:device_debug_tools/features/update/data/github_release_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseGithubRelease', () {
    test('解析 tag、说明与 Windows 安装包', () {
      final release = parseGithubRelease({
        'tag_name': 'v1.2.0',
        'html_url':
            'https://github.com/chyi-dev/device_debug_tools/releases/tag/v1.2.0',
        'body': '## 修复\n- bug',
        'assets': [
          {
            'name': 'notes.txt',
            'browser_download_url': 'https://example.com/notes.txt',
            'size': 10,
          },
          {
            'name': 'device_debug_tools-1.2.0-setup.exe',
            'browser_download_url':
                'https://github.com/chyi-dev/device_debug_tools/releases/download/v1.2.0/device_debug_tools-1.2.0-setup.exe',
            'size': 12345678,
          },
        ],
      });

      expect(release, isNotNull);
      expect(release!.version, '1.2.0');
      expect(release.hasWindowsSetup, isTrue);
      expect(release.windowsSetupName, 'device_debug_tools-1.2.0-setup.exe');
      expect(release.windowsSetupSize, 12345678);
      expect(release.body, contains('修复'));
    });

    test('无匹配安装包时仍返回 Release', () {
      final release = parseGithubRelease({
        'tag_name': '1.0.0',
        'html_url': 'https://github.com/chyi-dev/device_debug_tools/releases/tag/1.0.0',
        'body': '',
        'assets': [
          {
            'name': 'device_debug_tools-1.0.0.zip',
            'browser_download_url': 'https://example.com/a.zip',
            'size': 1,
          },
        ],
      });

      expect(release, isNotNull);
      expect(release!.version, '1.0.0');
      expect(release.hasWindowsSetup, isFalse);
      expect(release.body, isNull);
    });

    test('缺字段返回 null', () {
      expect(parseGithubRelease({'tag_name': 'v1.0.0'}), isNull);
      expect(
        parseGithubRelease({
          'tag_name': 'not-a-version',
          'html_url': 'https://example.com',
        }),
        isNull,
      );
    });
  });
}
