import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:device_debug_tools/core/storage/storage_keys.dart';
import 'package:device_debug_tools/features/license/data/device_code_source.dart';
import 'package:device_debug_tools/features/license/data/license_codec.dart';
import 'package:device_debug_tools/features/license/repository/license_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

class _FixedDeviceCode extends DeviceCodeSource {
  _FixedDeviceCode(this.code) : super();

  final String code;

  @override
  Future<String> resolve() async => code;
}

void main() {
  late Directory tempDir;
  late Box<dynamic> box;
  late SimpleKeyPairData keyPair;
  late List<int> publicKey;
  late List<int> privateKey;

  const device = 'ABCD-EFGH-IJKL-MNOP';

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ddt_lic_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<dynamic>(StorageKeys.settingsBox);
    final pair = await Ed25519().newKeyPair();
    keyPair = await pair.extract() as SimpleKeyPairData;
    publicKey = await keyPair.extractPublicKey().then((k) => k.bytes);
    privateKey = keyPair.bytes;
  });

  tearDown(() async {
    if (Hive.isBoxOpen(StorageKeys.settingsBox)) {
      await Hive.close();
    }
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('试用期内不显示横幅，激活后仍不显示', () async {
    var now = DateTime.utc(2025, 11, 5);
    final repo = LicenseRepository(
      settings: box,
      deviceCodes: _FixedDeviceCode(device),
      publicKeyBytes: publicKey,
      clock: () => now,
    );

    final first = await repo.load();
    expect(first.evaluation.showUnlicensedBanner, isFalse);
    expect(first.evaluation.inTrial, isTrue);

    now = DateTime.utc(2026, 11, 6);
    final expired = await repo.load();
    expect(expired.evaluation.showUnlicensedBanner, isTrue);

    final code = await LicenseCodec.issue(
      privateKeyBytes: privateKey,
      deviceCode: device,
      expiresOnUtc: DateTime.utc(2027, 11, 5),
    );
    final activated = await repo.activate(code);
    expect(activated.evaluation.showUnlicensedBanner, isFalse);
    expect(activated.evaluation.licenseExpiresOn, DateTime.utc(2027, 11, 5));
  });
}
