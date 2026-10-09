import 'dart:convert';
import 'dart:typed_data';

import '../model/serial_models.dart';

/// HEX / 转义 / 校验。算法与设计稿 engine 一致。
abstract final class SerialBytes {
  static Uint8List? parseHex(String text) {
    final clean = text.replaceAll(RegExp(r'0x', caseSensitive: false), '').replaceAll(
          RegExp(r'[^0-9a-fA-F]'),
          '',
        );
    if (clean.isEmpty || clean.length.isOdd) return null;
    final out = Uint8List(clean.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }

  static bool isHex(String text) => parseHex(text) != null;

  static String toHex(List<int> bytes) => bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(' ');

  static String toAscii(List<int> bytes) => String.fromCharCodes(
        bytes.map((b) => b >= 32 && b < 127 ? b : 0x2E),
      );

  static Uint8List textBytes(String text, {required bool escape}) {
    if (!escape) return Uint8List.fromList(utf8.encode(text));
    final out = <int>[];
    var i = 0;
    while (i < text.length) {
      if (text.startsWith(r'\x[', i)) {
        final end = text.indexOf(']', i + 3);
        if (end > i) {
          final parsed = parseHex(text.substring(i + 3, end));
          if (parsed != null) out.addAll(parsed);
          i = end + 1;
          continue;
        }
      }
      if (i + 4 <= text.length && text.startsWith(r'\x', i)) {
        final value = int.tryParse(text.substring(i + 2, i + 4), radix: 16);
        if (value != null) {
          out.add(value);
          i += 4;
          continue;
        }
      }
      if (i + 1 < text.length && text[i] == r'\') {
        const map = {'r': 13, 'n': 10, 't': 9, '0': 0, '\\': 92};
        final mapped = map[text[i + 1]];
        if (mapped != null) {
          out.add(mapped);
          i += 2;
          continue;
        }
      }
      var units = 1;
      final unit = text.codeUnitAt(i);
      if (unit >= 0xD800 && unit <= 0xDBFF && i + 1 < text.length) {
        units = 2;
      }
      out.addAll(utf8.encode(text.substring(i, i + units)));
      i += units;
    }
    return Uint8List.fromList(out);
  }

  static int sum8(List<int> bytes) =>
      bytes.fold<int>(0, (sum, b) => (sum + b) & 0xFF);

  static int xor8(List<int> bytes) => bytes.fold<int>(0, (sum, b) => sum ^ b);

  static int lrc(List<int> bytes) => (-sum8(bytes)) & 0xFF;

  static int crc8(List<int> bytes) {
    var crc = 0;
    for (final b in bytes) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 0x80) != 0 ? ((crc << 1) ^ 0x07) & 0xFF : (crc << 1) & 0xFF;
      }
    }
    return crc;
  }

  /// MODBUS，低字节在前。
  static List<int> crc16(List<int> bytes) {
    var crc = 0xFFFF;
    for (final b in bytes) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xA001 : crc >> 1;
      }
    }
    return [crc & 0xFF, (crc >> 8) & 0xFF];
  }

  /// IEEE，大端。
  static List<int> crc32(List<int> bytes) {
    var crc = 0xFFFFFFFF;
    for (final b in bytes) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    crc = (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
    return [
      (crc >> 24) & 0xFF,
      (crc >> 16) & 0xFF,
      (crc >> 8) & 0xFF,
      crc & 0xFF,
    ];
  }

  static List<int> checksumBytes(List<int> bytes, ChecksumKind kind) {
    return switch (kind) {
      ChecksumKind.none => const [],
      ChecksumKind.sum => [sum8(bytes)],
      ChecksumKind.xor => [xor8(bytes)],
      ChecksumKind.lrc => [lrc(bytes)],
      ChecksumKind.crc8 => [crc8(bytes)],
      ChecksumKind.crc16 => crc16(bytes),
      ChecksumKind.crc32 => crc32(bytes),
    };
  }

  static EncodeResult encode({
    required String text,
    required DataFormat format,
    required bool escape,
    required bool atCrlf,
    required bool crlf,
    required ChecksumKind checksum,
  }) {
    final Uint8List? raw = format == DataFormat.hex
        ? parseHex(text)
        : textBytes(text, escape: escape);
    if (raw == null) return const EncodeResult.fail(EncodeError.badHex);
    if (raw.isEmpty) return const EncodeResult.fail(EncodeError.empty);
    final withSum = Uint8List.fromList([
      ...raw,
      ...checksumBytes(raw, checksum),
    ]);
    final endsCrlf = withSum.length >= 2 &&
        withSum[withSum.length - 2] == 0x0D &&
        withSum[withSum.length - 1] == 0x0A;
    final isAt = format != DataFormat.hex && RegExp(r'^\s*AT', caseSensitive: false).hasMatch(text);
    if ((crlf || (atCrlf && isAt)) && !endsCrlf) {
      return EncodeResult.ok(Uint8List.fromList([...withSum, 0x0D, 0x0A]));
    }
    return EncodeResult.ok(withSum);
  }

  /// 切换发送格式时转换输入框。无法无损转换时保留原文。
  static String convertText({
    required String text,
    required DataFormat from,
    required DataFormat to,
    required bool escape,
  }) {
    if (from == to) return text;
    if (from == DataFormat.hex && to == DataFormat.ascii) {
      final bytes = parseHex(text);
      if (bytes == null) return text;
      if (toAscii(bytes).contains('.')) return text;
      try {
        return utf8.decode(bytes);
      } on FormatException {
        return text;
      }
    }
    return toHex(textBytes(text, escape: escape));
  }

  static bool ruleMatches(ReplyRule rule, List<int> bytes) {
    final pattern = parseHex(rule.pattern);
    if (pattern == null) return false;
    final haystack = toHex(bytes);
    final needle = toHex(pattern);
    return switch (rule.match) {
      MatchMode.frame => haystack == needle,
      MatchMode.prefix => haystack.startsWith(needle),
      MatchMode.contains => haystack.contains(needle),
    };
  }
}
