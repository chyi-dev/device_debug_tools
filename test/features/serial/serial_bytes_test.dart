import 'dart:convert';
import 'dart:typed_data';

import 'package:device_debug_tools/features/serial/data/packet_assembler.dart';
import 'package:device_debug_tools/features/serial/data/serial_bytes.dart';
import 'package:device_debug_tools/features/serial/model/serial_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HEX 解析忽略空白和 0x 前缀', () {
    expect(
      SerialBytes.parseHex('A5 01 0x00'),
      Uint8List.fromList([0xA5, 0x01, 0x00]),
    );
    expect(SerialBytes.parseHex('A5 0'), isNull);
    expect(SerialBytes.parseHex(''), isNull);
  });

  test('转义符与 UTF-8', () {
    expect(
      SerialBytes.textBytes(r'A\r\n\x41\x[42 43]', escape: true),
      Uint8List.fromList([0x41, 0x0D, 0x0A, 0x41, 0x42, 0x43]),
    );
    expect(SerialBytes.textBytes('温', escape: false), utf8.encode('温'));
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
      SerialBytes.toHex(
        SerialBytes.checksumBytes(const [0xA5, 0x01], ChecksumKind.sum),
      ),
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

  group('自动应答增强匹配', () {
    ReplyRule rule(
      String pattern, {
      MatchMode match = MatchMode.prefix,
      MatchKind kind = MatchKind.template,
      DataFormat format = DataFormat.hex,
      bool ignoreCase = false,
    }) => ReplyRule(
      id: 'r',
      name: 'n',
      match: match,
      kind: kind,
      format: format,
      ignoreCase: ignoreCase,
      pattern: pattern,
      enabled: true,
      hits: 0,
      replies: const [],
    );

    List<String?>? caps(ReplyRule r, List<int> bytes) =>
        SerialBytes.ruleCaptures(
          r,
          bytes,
        )?.map((c) => c == null ? null : SerialBytes.toHex(c)).toList();

    final frame = [0xA5, 0x5A, 0x03, 0x11, 0x22, 0x0D];

    test('HEX 模板通配符与结尾', () {
      expect(caps(rule('A5 ?? 03'), frame), ['5A']);
      expect(caps(rule('A5 * 0D', match: MatchMode.frame), frame), [
        '5A 03 11 22',
      ]);
      expect(caps(rule('?? 0D', match: MatchMode.suffix), frame), ['22']);
      expect(caps(rule('11 ??', match: MatchMode.suffix), frame), isNull);
      expect(caps(rule('03 * 22', match: MatchMode.contains), frame), ['11']);
      expect(caps(rule('A5 *', match: MatchMode.frame), [0xA5]), ['']);
      expect(
        SerialBytes.templateCaptureCount('A5 ? 03', DataFormat.hex),
        isNull,
      );
      expect(SerialBytes.templateCaptureCount('A 5 ?? *', DataFormat.hex), 2);
    });

    test('ASCII 模板与忽略大小写', () {
      final ok = 'OK+TEMP=25\r\n'.codeUnits;
      expect(
        caps(
          rule(
            'ok+temp=*\\r\\n',
            format: DataFormat.ascii,
            match: MatchMode.frame,
          ),
          ok,
        ),
        isNull,
      );
      expect(
        caps(
          rule(
            'ok+temp=*\\r\\n',
            format: DataFormat.ascii,
            match: MatchMode.frame,
            ignoreCase: true,
          ),
          ok,
        ),
        ['32 35'],
      );
      expect(
        caps(rule('a\\?', format: DataFormat.ascii), 'a?'.codeUnits),
        isEmpty,
      );
      expect(
        caps(rule('a\\?', format: DataFormat.ascii), 'ab'.codeUnits),
        isNull,
      );
    });

    test('正则 HEX 与 ASCII', () {
      expect(caps(rule(r'^a5 5a (\w\w)', kind: MatchKind.regex), frame), [
        '03',
      ]);
      expect(caps(rule(r'(11 22)? 0D$', kind: MatchKind.regex), frame), [
        '11 22',
      ]);
      expect(caps(rule(r'5(A)', kind: MatchKind.regex), frame), [null]);
      final ascii = 'ID=7\r'.codeUnits;
      expect(
        caps(
          rule(r'^id=(\d)\r', kind: MatchKind.regex, format: DataFormat.ascii),
          ascii,
        ),
        isNull,
      );
      expect(
        caps(
          rule(
            r'^id=(\d)\r',
            kind: MatchKind.regex,
            format: DataFormat.ascii,
            ignoreCase: true,
          ),
          ascii,
        ),
        ['37'],
      );
      expect(SerialBytes.isRegex('(ab'), isFalse);
    });

    test(r'应答 $n 展开与越界', () {
      final c = [
        Uint8List.fromList([0x11, 0x22]),
        Uint8List(0),
        null,
      ];
      expect(SerialBytes.expandReply(r'A5 $1 0D', c), 'A5 11 22 0D');
      expect(SerialBytes.expandReply(r'A5 $2', c), 'A5');
      expect(SerialBytes.expandReply(r'$2', c), isNull);
      expect(SerialBytes.expandReply(r'A5 $3', c), isNull);
      expect(SerialBytes.expandReply(r'A5 $4', c), isNull);
      expect(SerialBytes.isReplyHex(r'A5 $1'), isTrue);
      expect(SerialBytes.isReplyHex(r'A5 $0'), isFalse);
      expect(SerialBytes.maxCaptureRef(r'$2 $10 $1'), 10);
    });

    test('旧规则 JSON 读入为模板 HEX', () {
      final r = ReplyRule.fromJson({
        'match': 'frame',
        'pattern': 'A5',
        'enabled': true,
      })!;
      expect(r.kind, MatchKind.template);
      expect(r.format, DataFormat.hex);
      expect(r.ignoreCase, isFalse);
      final back = ReplyRule.fromJson(
        rule(
          'x',
          kind: MatchKind.regex,
          format: DataFormat.ascii,
          ignoreCase: true,
        ).toJson(),
      )!;
      expect(back.kind, MatchKind.regex);
      expect(back.format, DataFormat.ascii);
      expect(back.ignoreCase, isTrue);
    });
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
