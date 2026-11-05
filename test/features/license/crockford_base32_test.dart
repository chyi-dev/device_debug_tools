import 'dart:typed_data';

import 'package:device_debug_tools/features/license/data/crockford_base32.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CrockfordBase32', () {
    test('10 字节编解码往返', () {
      final bytes = Uint8List.fromList(List<int>.generate(10, (i) => i + 1));
      final encoded = CrockfordBase32.encode(bytes);
      expect(encoded.length, 16);
      expect(CrockfordBase32.decode(encoded), bytes);
    });

    test('大小写与易混字符归一', () {
      final bytes = CrockfordBase32.decode('0123456789ABCDEF');
      expect(CrockfordBase32.decode('0123456789abcdef'), bytes);
      expect(
        CrockfordBase32.decode('0O1IL'),
        CrockfordBase32.decode('00111'),
      );
    });
  });
}
