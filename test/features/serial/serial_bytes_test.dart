import 'dart:convert';
import 'dart:typed_data';

import 'package:device_debug_tools/features/serial/data/packet_assembler.dart';
import 'package:device_debug_tools/features/serial/data/serial_bytes.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HEX 解析忽略空白和 0x 前缀', () {
    expect(SerialBytes.parseHex('A5 01 0x00'), Uint8List.fromList([0xA5, 0x01, 0x00]));
    expect(SerialBytes.parseHex('A5 0'), isNull);
    expect(SerialBytes.parseHex(''), isNull);
  });

  test('转义符与 UTF-8', () {
    expect(
      SerialBytes.textBytes(r'A\r\n\x41\x[42 43]', escape: true),
      Uint8List.fromList([0x41, 0x0D, 0x0A, 0x41, 0x42, 0x43]),
    );
    expect(
      SerialBytes.textBytes('温', escape: false),
      utf8.encode('温'),
    );
  });

  test('AT 指令与 CRLF 不重复追加', () {
    final once = SerialBytes.encode(
      text: 'AT',
      format: DataFormat.ascii,
      escape: true,
      atCrlf: true,
      crlf: false,
      checksum: ChecksumKind.none,
    );
    expect(once.bytes, Uint8List.fromList([0x41, 0x54, 0x0D, 0x0A]));

    final twice = SerialBytes.encode(
      text: 'AT\r\n',
      format: DataFormat.ascii,
      escape: true,
      atCrlf: true,
      crlf: true,
      checksum: ChecksumKind.none,
    );
    expect(twice.bytes, Uint8List.fromList([0x41, 0x54, 0x0D, 0x0A]));
  });

  test('校验算法与设计稿一致', () {
    final bytes = utf8.encode('123456789');
    expect(SerialBytes.sum8(const [1, 2, 3]), 6);
    expect(SerialBytes.xor8(const [1, 2, 3]), 0);
    expect(SerialBytes.lrc(const [1, 2, 3]), 0xFA);
    expect(SerialBytes.crc16(bytes), [0x37, 0x4B]);
    expect(SerialBytes.crc32(bytes), [0xCB, 0xF4, 0x39, 0x26]);
    expect(
      SerialBytes.toHex(SerialBytes.checksumBytes(const [0xA5, 0x01], ChecksumKind.sum)),
      'A6',
    );
  });

  test('自动应答按前缀、整帧、包含匹配', () {
    final frame = Uint8List.fromList([0xA5, 0x5A, 0x03, 0x01]);
    bool match(MatchMode mode, String pattern) => SerialBytes.ruleMatches(
          ReplyRule(
            id: 'r',
            name: 'n',
            match: mode,
            pattern: pattern,
            enabled: true,
            hits: 0,
            replies: const [],
          ),
          frame,
        );
    expect(match(MatchMode.prefix, 'A5 5A'), isTrue);
    expect(match(MatchMode.frame, 'A5 5A 03 01'), isTrue);
    expect(match(MatchMode.frame, 'A5 5A'), isFalse);
    expect(match(MatchMode.contains, '5A 03'), isTrue);
    expect(match(MatchMode.prefix, 'EE'), isFalse);
  });

  testWidgets('分包超时窗口内的字节合并为一条', (tester) async {
    final assembler = PacketAssembler();
    Uint8List? got;
    assembler.add([1, 2], 20, (bytes) => got = bytes);
    assembler.add([3], 20, (bytes) => got = bytes);
    await tester.pump(const Duration(milliseconds: 19));
    expect(got, isNull);
    await tester.pump(const Duration(milliseconds: 1));
    expect(got, Uint8List.fromList([1, 2, 3]));
    assembler.dispose();
  });
}
