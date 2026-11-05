import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'crockford_base32.dart';

sealed class LicenseVerifyResult {}

class LicenseVerifyOk extends LicenseVerifyResult {
  LicenseVerifyOk(this.expiresOnUtc);

  final DateTime expiresOnUtc;
}

class LicenseVerifyExpired extends LicenseVerifyResult {
  LicenseVerifyExpired(this.expiresOnUtc);

  final DateTime expiresOnUtc;
}

class LicenseVerifyInvalid extends LicenseVerifyResult {
  LicenseVerifyInvalid([this.reason = 'invalid']);

  final String reason;
}

/// 离线激活码编解码：Ed25519 + Crockford Base32。
abstract final class LicenseCodec {
  static const int version = 1;
  static const _payloadPrefix = 'DDT1';

  static String formatDeviceCode(String raw) {
    final n = normalizeDeviceCode(raw);
    final buf = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write('-');
      buf.write(n[i]);
    }
    return buf.toString();
  }

  static String normalizeDeviceCode(String input) {
    final cleaned = StringBuffer();
    for (final rune in input.toUpperCase().runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '-' || ch == ' ') continue;
      cleaned.write(ch);
    }
    return cleaned.toString();
  }

  static String formatGrouped(String raw) {
    final n = normalizeDeviceCode(raw);
    final buf = StringBuffer();
    for (var i = 0; i < n.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write('-');
      buf.write(n[i]);
    }
    return buf.toString();
  }

  /// 从机器标识字节生成显示用设备码（SHA-256 前 10 字节）。
  static String deviceCodeFromMachineId(List<int> machineIdBytes) {
    // 调用方传入已哈希的 10 字节，或原始标识由上层哈希。
    assert(machineIdBytes.length == 10);
    return formatDeviceCode(CrockfordBase32.encode(machineIdBytes));
  }

  static String payloadMessage({
    required String deviceCode,
    required DateTime expiresOnUtc,
  }) {
    final device = normalizeDeviceCode(deviceCode);
    final day = _dateOnlyUtc(expiresOnUtc);
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$_payloadPrefix|$device|$y-$m-$d';
  }

  static Future<String> issue({
    required List<int> privateKeyBytes,
    required String deviceCode,
    required DateTime expiresOnUtc,
  }) async {
    final day = _dateOnlyUtc(expiresOnUtc);
    final message = utf8.encode(
      payloadMessage(deviceCode: deviceCode, expiresOnUtc: day),
    );
    final keyPair = await Ed25519().newKeyPairFromSeed(privateKeyBytes);
    final signature = await Ed25519().sign(message, keyPair: keyPair);
    final days = day.difference(DateTime.utc(1970, 1, 1)).inDays;
    final body = BytesBuilder(copy: false)
      ..addByte(version)
      ..add(_uint32Be(days))
      ..add(signature.bytes);
    return formatGrouped(CrockfordBase32.encode(body.toBytes()));
  }

  static Future<LicenseVerifyResult> verify({
    required List<int> publicKeyBytes,
    required String deviceCode,
    required String activationCode,
    required DateTime nowUtc,
  }) async {
    late final Uint8List raw;
    try {
      raw = CrockfordBase32.decode(activationCode);
    } on FormatException {
      return LicenseVerifyInvalid('format');
    }
    if (raw.length != 1 + 4 + 64) {
      return LicenseVerifyInvalid('length');
    }
    if (raw[0] != version) {
      return LicenseVerifyInvalid('version');
    }
    final days = _readUint32Be(raw, 1);
    final expires = DateTime.utc(1970, 1, 1).add(Duration(days: days));
    final sigBytes = raw.sublist(5);
    final message = utf8.encode(
      payloadMessage(deviceCode: deviceCode, expiresOnUtc: expires),
    );
    final ok = await Ed25519().verify(
      message,
      signature: Signature(
        sigBytes,
        publicKey: SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519),
      ),
    );
    if (!ok) return LicenseVerifyInvalid('signature');
    final today = _dateOnlyUtc(nowUtc);
    if (today.isAfter(expires)) {
      return LicenseVerifyExpired(expires);
    }
    return LicenseVerifyOk(expires);
  }

  static DateTime _dateOnlyUtc(DateTime dt) =>
      DateTime.utc(dt.year, dt.month, dt.day);

  static Uint8List _uint32Be(int value) {
    final out = Uint8List(4);
    out[0] = (value >> 24) & 0xff;
    out[1] = (value >> 16) & 0xff;
    out[2] = (value >> 8) & 0xff;
    out[3] = value & 0xff;
    return out;
  }

  static int _readUint32Be(List<int> bytes, int offset) =>
      ((bytes[offset] & 0xff) << 24) |
      ((bytes[offset + 1] & 0xff) << 16) |
      ((bytes[offset + 2] & 0xff) << 8) |
      (bytes[offset + 3] & 0xff);

}
