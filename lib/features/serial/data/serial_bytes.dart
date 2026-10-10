import 'dart:convert';
import 'dart:typed_data';

import '../model/serial_models.dart';

/// HEX / 转义 / 校验。算法与设计稿 engine 一致。
abstract final class SerialBytes {
  static Uint8List? parseHex(String text) {
    final clean = text
        .replaceAll(RegExp(r'0x', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
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

  static String toAscii(List<int> bytes) =>
      String.fromCharCodes(bytes.map((b) => b >= 32 && b < 127 ? b : 0x2E));

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
        crc = (crc & 0x80) != 0
            ? ((crc << 1) ^ 0x07) & 0xFF
            : (crc << 1) & 0xFF;
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
    final endsCrlf =
        withSum.length >= 2 &&
        withSum[withSum.length - 2] == 0x0D &&
        withSum[withSum.length - 1] == 0x0A;
    final isAt =
        format != DataFormat.hex &&
        RegExp(r'^\s*AT', caseSensitive: false).hasMatch(text);
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

  static bool ruleMatches(ReplyRule rule, List<int> bytes) =>
      ruleCaptures(rule, bytes) != null;

  /// 命中返回捕获（按 `$1`、`$2` 顺序），未命中返回 null。
  /// 正则 HEX 捕获到半个字节时该项为 null，引用它的应答不发送。
  static List<Uint8List?>? ruleCaptures(ReplyRule rule, List<int> bytes) {
    if (rule.kind == MatchKind.regex) return _regexCaptures(rule, bytes);
    final tokens = _parseTemplate(rule.pattern, rule.format);
    if (tokens == null) return null;
    final fold = rule.format == DataFormat.ascii && rule.ignoreCase;
    final anchoredStart =
        rule.match == MatchMode.prefix || rule.match == MatchMode.frame;
    final anchoredEnd =
        rule.match == MatchMode.frame || rule.match == MatchMode.suffix;
    final lastStart = anchoredStart ? 0 : bytes.length;
    for (var start = 0; start <= lastStart; start++) {
      final caps = <Uint8List?>[];
      if (_matchFrom(tokens, 0, bytes, start, anchoredEnd, fold, caps)) {
        return caps;
      }
    }
    return null;
  }

  /// 模板合法时返回通配符个数，非法返回 null。
  static int? templateCaptureCount(String pattern, DataFormat format) {
    final tokens = _parseTemplate(pattern, format);
    return tokens?.where((t) => t.byte == null).length;
  }

  static bool isRegex(String pattern) {
    if (pattern.isEmpty) return false;
    try {
      RegExp(pattern);
      return true;
    } on FormatException {
      return false;
    }
  }

  static final _captureRef = RegExp(r'\$(\d+)');

  /// 应答里引用的最大 `$n`，没有引用为 0。
  static int maxCaptureRef(String data) {
    var max = 0;
    for (final m in _captureRef.allMatches(data)) {
      final n = int.parse(m.group(1)!);
      if (n > max) max = n;
    }
    return max;
  }

  /// `$n` 换成占位字节后是否为合法 HEX，用于编辑框校验。
  static bool isReplyHex(String data) =>
      isHex(data.replaceAll(_captureRef, ' 00 ')) &&
      _captureRef.allMatches(data).every((m) => int.parse(m.group(1)!) > 0);

  /// 把 `$n` 换成捕获字节的 HEX；引用越界、捕获无效或结果不是 HEX 时返回 null。
  static String? expandReply(String data, List<Uint8List?> captures) {
    var ok = true;
    final out = data.replaceAllMapped(_captureRef, (m) {
      final n = int.parse(m.group(1)!);
      final cap = n >= 1 && n <= captures.length ? captures[n - 1] : null;
      if (cap == null) {
        ok = false;
        return '';
      }
      return ' ${toHex(cap)} ';
    });
    final bytes = ok ? parseHex(out) : null;
    return bytes == null ? null : toHex(bytes);
  }

  static List<Uint8List?>? _regexCaptures(ReplyRule rule, List<int> bytes) {
    final hex = rule.format == DataFormat.hex;
    final RegExp re;
    try {
      re = RegExp(rule.pattern, caseSensitive: !hex && !rule.ignoreCase);
    } on FormatException {
      return null;
    }
    final m = re.firstMatch(hex ? toHex(bytes) : String.fromCharCodes(bytes));
    if (m == null) return null;
    return [
      for (var i = 1; i <= m.groupCount; i++)
        switch (m.group(i)) {
          null || '' => Uint8List(0),
          final text when hex => parseHex(text),
          final text => Uint8List.fromList(text.codeUnits),
        },
    ];
  }

  static bool _matchFrom(
    List<_Token> tokens,
    int k,
    List<int> bytes,
    int pos,
    bool anchoredEnd,
    bool fold,
    List<Uint8List?> caps,
  ) {
    if (k == tokens.length) return !anchoredEnd || pos == bytes.length;
    final token = tokens[k];
    if (token.many) {
      for (var end = bytes.length; end >= pos; end--) {
        caps.add(Uint8List.fromList(bytes.sublist(pos, end)));
        if (_matchFrom(tokens, k + 1, bytes, end, anchoredEnd, fold, caps)) {
          return true;
        }
        caps.removeLast();
      }
      return false;
    }
    if (pos >= bytes.length) return false;
    final byte = token.byte;
    if (byte == null) {
      caps.add(Uint8List.fromList([bytes[pos]]));
      if (_matchFrom(tokens, k + 1, bytes, pos + 1, anchoredEnd, fold, caps)) {
        return true;
      }
      caps.removeLast();
      return false;
    }
    final same = fold ? _lower(bytes[pos]) == _lower(byte) : bytes[pos] == byte;
    return same &&
        _matchFrom(tokens, k + 1, bytes, pos + 1, anchoredEnd, fold, caps);
  }

  static int _lower(int b) => b >= 0x41 && b <= 0x5A ? b + 0x20 : b;

  static List<_Token>? _parseTemplate(String pattern, DataFormat format) {
    final tokens = format == DataFormat.hex
        ? _parseHexTemplate(pattern)
        : _parseAsciiTemplate(pattern);
    return tokens == null || tokens.isEmpty ? null : tokens;
  }

  /// 与 [parseHex] 一致：先去掉 `0x`，其余非十六进制字符视为分隔。
  static List<_Token>? _parseHexTemplate(String pattern) {
    final clean = pattern
        .replaceAll(RegExp(r'0x', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^0-9a-fA-F?*]'), '');
    final tokens = <_Token>[];
    var i = 0;
    while (i < clean.length) {
      final c = clean[i];
      if (c == '*') {
        tokens.add(const _Token.many());
        i++;
      } else if (c == '?') {
        if (i + 1 >= clean.length || clean[i + 1] != '?') return null;
        tokens.add(const _Token.any());
        i += 2;
      } else {
        if (i + 1 >= clean.length) return null;
        final value = int.tryParse(clean.substring(i, i + 2), radix: 16);
        if (value == null) return null;
        tokens.add(_Token.byte(value));
        i += 2;
      }
    }
    return tokens;
  }

  static List<_Token>? _parseAsciiTemplate(String pattern) {
    const escapes = {
      'r': 13,
      'n': 10,
      't': 9,
      '0': 0,
      r'\': 92,
      '?': 63,
      '*': 42,
    };
    final tokens = <_Token>[];
    var i = 0;
    while (i < pattern.length) {
      final c = pattern[i];
      if (c == '*') {
        tokens.add(const _Token.many());
        i++;
        continue;
      }
      if (c == '?') {
        tokens.add(const _Token.any());
        i++;
        continue;
      }
      if (c == r'\' && i + 1 < pattern.length) {
        final next = pattern[i + 1];
        final mapped = escapes[next];
        if (mapped != null) {
          tokens.add(_Token.byte(mapped));
          i += 2;
          continue;
        }
        if (next == 'x' && i + 4 <= pattern.length) {
          final value = int.tryParse(
            pattern.substring(i + 2, i + 4),
            radix: 16,
          );
          if (value != null) {
            tokens.add(_Token.byte(value));
            i += 4;
            continue;
          }
        }
      }
      var units = 1;
      final unit = pattern.codeUnitAt(i);
      if (unit >= 0xD800 && unit <= 0xDBFF && i + 1 < pattern.length) {
        units = 2;
      }
      for (final b in utf8.encode(pattern.substring(i, i + units))) {
        tokens.add(_Token.byte(b));
      }
      i += units;
    }
    return tokens;
  }
}

/// 模板记号：固定字节、任意一字节（`??` / `?`）、任意长度（`*`）。
class _Token {
  const _Token.byte(int this.byte) : many = false;
  const _Token.any() : byte = null, many = false;
  const _Token.many() : byte = null, many = true;

  final int? byte;
  final bool many;
}
