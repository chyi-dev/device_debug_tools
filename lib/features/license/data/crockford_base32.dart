import 'dart:typed_data';

/// Crockford Base32：字母表不含 I L O U；解码时 O→0、I/L→1。
abstract final class CrockfordBase32 {
  static const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  static String encode(List<int> bytes) {
    if (bytes.isEmpty) return '';
    final out = StringBuffer();
    var buffer = 0;
    var bits = 0;
    for (final b in bytes) {
      buffer = (buffer << 8) | (b & 0xff);
      bits += 8;
      while (bits >= 5) {
        bits -= 5;
        out.write(alphabet[(buffer >> bits) & 0x1f]);
      }
    }
    if (bits > 0) {
      out.write(alphabet[(buffer << (5 - bits)) & 0x1f]);
    }
    return out.toString();
  }

  static Uint8List decode(String input) {
    final cleaned = StringBuffer();
    for (final rune in input.toUpperCase().runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '-' || ch == ' ') continue;
      cleaned.write(_normalizeChar(ch));
    }
    final text = cleaned.toString();
    if (text.isEmpty) return Uint8List(0);

    final out = BytesBuilder(copy: false);
    var buffer = 0;
    var bits = 0;
    for (var i = 0; i < text.length; i++) {
      final idx = alphabet.indexOf(text[i]);
      if (idx < 0) {
        throw FormatException('非法 Base32 字符: ${text[i]}');
      }
      buffer = (buffer << 5) | idx;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.addByte((buffer >> bits) & 0xff);
      }
    }
    return out.toBytes();
  }

  static String _normalizeChar(String ch) {
    switch (ch) {
      case 'O':
        return '0';
      case 'I':
      case 'L':
        return '1';
      default:
        return ch;
    }
  }
}
