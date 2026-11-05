import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/storage/storage_keys.dart';
import 'license_codec.dart';

/// 读取本机稳定标识并生成设备码；失败时持久化随机码。
class DeviceCodeSource {
  DeviceCodeSource({
    Box<dynamic>? settings,
    DeviceInfoPlugin? deviceInfo,
    Random? random,
  }) : _settings = settings,
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
       _random = random ?? Random.secure();

  final Box<dynamic>? _settings;
  final DeviceInfoPlugin _deviceInfo;
  final Random _random;

  Future<String> resolve() async {
    final cached = _settings?.get(StorageKeys.licenseDeviceCode) as String?;
    if (cached != null && cached.isNotEmpty) {
      return LicenseCodec.formatDeviceCode(cached);
    }

    String? machineId;
    try {
      machineId = await _readMachineId();
    } catch (e, s) {
      AppLogger.i.error(
        '读取机器标识失败',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
    }

    final rawBytes = machineId == null || machineId.isEmpty
        ? _randomBytes(32)
        : utf8.encode(machineId);
    final digest = sha256.convert(rawBytes).bytes;
    final code = LicenseCodec.deviceCodeFromMachineId(
      Uint8List.fromList(digest.sublist(0, 10)),
    );

    await _settings?.put(
      StorageKeys.licenseDeviceCode,
      LicenseCodec.normalizeDeviceCode(code),
    );
    return code;
  }

  Future<String?> _readMachineId() async {
    if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      return info.deviceId;
    }
    if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      return info.systemGUID;
    }
    if (Platform.isLinux) {
      final info = await _deviceInfo.linuxInfo;
      return info.machineId;
    }
    return null;
  }

  Uint8List _randomBytes(int length) {
    final out = Uint8List(length);
    for (var i = 0; i < length; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }
}
