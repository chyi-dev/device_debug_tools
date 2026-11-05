import 'package:device_debug_tools/features/update/model/sem_ver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SemVer', () {
    test('解析 v 前缀与 +build', () {
      expect(SemVer.tryParse('v1.2.3'), const SemVer(1, 2, 3));
      expect(SemVer.tryParse('1.0.0+42'), const SemVer(1, 0, 0));
      expect(SemVer.normalize('V2.0.1'), '2.0.1');
    });

    test('比较新旧', () {
      expect(SemVer.isNewer('1.1.0', '1.0.9'), isTrue);
      expect(SemVer.isNewer('v1.0.0', '1.0.0'), isFalse);
      expect(SemVer.isNewer('1.0.0', '1.0.1'), isFalse);
      expect(SemVer.isNewer('2.0.0', '1.9.9'), isTrue);
    });

    test('非法输入', () {
      expect(SemVer.tryParse(''), isNull);
      expect(SemVer.tryParse('abc'), isNull);
      expect(SemVer.isNewer('bad', '1.0.0'), isFalse);
    });
  });
}
