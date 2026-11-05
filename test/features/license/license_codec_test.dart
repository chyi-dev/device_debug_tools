import 'package:cryptography/cryptography.dart';
import 'package:device_debug_tools/features/license/data/license_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SimpleKeyPairData keyPair;
  late List<int> publicKey;
  late List<int> privateKey;

  setUp(() async {
    final pair = await Ed25519().newKeyPair();
    keyPair = await pair.extract() as SimpleKeyPairData;
    publicKey = await keyPair.extractPublicKey().then((k) => k.bytes);
    privateKey = keyPair.bytes;
  });

  const device = 'ABCD-EFGH-IJKL-MNOP';
  final expires = DateTime.utc(2027, 11, 5);

  test('签发后本机校验通过', () async {
    final code = await LicenseCodec.issue(
      privateKeyBytes: privateKey,
      deviceCode: device,
      expiresOnUtc: expires,
    );
    final result = await LicenseCodec.verify(
      publicKeyBytes: publicKey,
      deviceCode: device,
      activationCode: code,
      nowUtc: DateTime.utc(2027, 11, 5),
    );
    expect(result, isA<LicenseVerifyOk>());
    expect((result as LicenseVerifyOk).expiresOnUtc, expires);
  });

  test('到期日当天有效、次日失效', () async {
    final code = await LicenseCodec.issue(
      privateKeyBytes: privateKey,
      deviceCode: device,
      expiresOnUtc: expires,
    );
    expect(
      await LicenseCodec.verify(
        publicKeyBytes: publicKey,
        deviceCode: device,
        activationCode: code,
        nowUtc: DateTime.utc(2027, 11, 5, 23, 59),
      ),
      isA<LicenseVerifyOk>(),
    );
    expect(
      await LicenseCodec.verify(
        publicKeyBytes: publicKey,
        deviceCode: device,
        activationCode: code,
        nowUtc: DateTime.utc(2027, 11, 6),
      ),
      isA<LicenseVerifyExpired>(),
    );
  });

  test('换设备码失败', () async {
    final code = await LicenseCodec.issue(
      privateKeyBytes: privateKey,
      deviceCode: device,
      expiresOnUtc: expires,
    );
    expect(
      await LicenseCodec.verify(
        publicKeyBytes: publicKey,
        deviceCode: 'ZZZZ-ZZZZ-ZZZZ-ZZZZ',
        activationCode: code,
        nowUtc: DateTime.utc(2027, 1, 1),
      ),
      isA<LicenseVerifyInvalid>(),
    );
  });

  test('改一字失败', () async {
    final code = await LicenseCodec.issue(
      privateKeyBytes: privateKey,
      deviceCode: device,
      expiresOnUtc: expires,
    );
    final chars = code.replaceAll('-', '').split('');
    chars[4] = chars[4] == 'A' ? 'B' : 'A';
    final tampered = LicenseCodec.formatGrouped(chars.join());
    expect(
      await LicenseCodec.verify(
        publicKeyBytes: publicKey,
        deviceCode: device,
        activationCode: tampered,
        nowUtc: DateTime.utc(2027, 1, 1),
      ),
      isA<LicenseVerifyInvalid>(),
    );
  });

  test('设备码格式化', () {
    expect(
      LicenseCodec.formatDeviceCode('ABCDEFGHIJKLMNOP'),
      'ABCD-EFGH-IJKL-MNOP',
    );
    expect(LicenseCodec.normalizeDeviceCode('abcd-efgh-ijkl-mnop'), 'ABCDEFGHIJKLMNOP');
  });
}
