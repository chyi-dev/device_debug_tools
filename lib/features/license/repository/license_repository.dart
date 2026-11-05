import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../core/storage/storage_keys.dart';
import '../data/device_code_source.dart';
import '../data/license_codec.dart';
import '../data/license_public_key.dart';
import '../model/license_evaluation.dart';

class LicenseSnapshot {
  const LicenseSnapshot({
    required this.deviceCode,
    required this.evaluation,
  });

  final String deviceCode;
  final LicenseEvaluation evaluation;
}

class LicenseRepository {
  LicenseRepository({
    required Box<dynamic> settings,
    DeviceCodeSource? deviceCodes,
    List<int>? publicKeyBytes,
    DateTime Function()? clock,
  }) : _settings = settings,
       _deviceCodes = deviceCodes ?? DeviceCodeSource(settings: settings),
       _publicKey = publicKeyBytes ?? LicensePublicKey.bytes,
       _clock = clock ?? DateTime.now;

  final Box<dynamic> _settings;
  final DeviceCodeSource _deviceCodes;
  final List<int> _publicKey;
  final DateTime Function() _clock;

  Future<LicenseSnapshot> load() async {
    final deviceCode = await _deviceCodes.resolve();
    final now = _clock().toUtc();
    final trialStarted = _ensureTrialStarted(now);
    final lastSeen = _readLastSeen() ?? trialStarted;
    final stored = _settings.get(StorageKeys.licenseActivationCode) as String?;

    DateTime? verifiedExpires;
    if (stored != null && stored.isNotEmpty) {
      final result = await LicenseCodec.verify(
        publicKeyBytes: _publicKey,
        deviceCode: deviceCode,
        activationCode: stored,
        nowUtc: now.isBefore(lastSeen) ? lastSeen : now,
      );
      switch (result) {
        case LicenseVerifyOk(:final expiresOnUtc):
          verifiedExpires = expiresOnUtc;
        case LicenseVerifyExpired(:final expiresOnUtc):
          verifiedExpires = expiresOnUtc;
        case LicenseVerifyInvalid():
          verifiedExpires = null;
      }
    }

    final evaluation = evaluateLicense(
      trialStartedAt: trialStarted,
      lastSeenAt: lastSeen,
      now: now,
      storedActivation: stored,
      trialDays: AppConstants.licenseTrialDays,
      verifyStored: (_) => verifiedExpires,
    );

    await _writeLastSeen(evaluation.effectiveNow);
    return LicenseSnapshot(deviceCode: deviceCode, evaluation: evaluation);
  }

  /// 校验并持久化激活码；失败抛 [ValidationException]（message: invalid / expired）。
  Future<LicenseSnapshot> activate(String activationCode) async {
    final deviceCode = await _deviceCodes.resolve();
    final now = _clock().toUtc();
    final lastSeen = _readLastSeen() ?? now;
    final effective = now.isBefore(lastSeen) ? lastSeen : now;

    final result = await LicenseCodec.verify(
      publicKeyBytes: _publicKey,
      deviceCode: deviceCode,
      activationCode: activationCode,
      nowUtc: effective,
    );

    switch (result) {
      case LicenseVerifyOk():
        await _settings.put(
          StorageKeys.licenseActivationCode,
          LicenseCodec.formatGrouped(
            LicenseCodec.normalizeDeviceCode(activationCode),
          ),
        );
        AppLogger.i.info('授权激活成功', category: LogCategory.app);
        return load();
      case LicenseVerifyExpired():
        throw ValidationException('expired');
      case LicenseVerifyInvalid():
        throw ValidationException('invalid');
    }
  }

  DateTime _ensureTrialStarted(DateTime now) {
    final existing = _settings.get(StorageKeys.licenseTrialStartedMs) as int?;
    if (existing != null) {
      return DateTime.fromMillisecondsSinceEpoch(existing, isUtc: true);
    }
    final started = DateTime.utc(now.year, now.month, now.day);
    _settings.put(
      StorageKeys.licenseTrialStartedMs,
      started.millisecondsSinceEpoch,
    );
    return started;
  }

  DateTime? _readLastSeen() {
    final ms = _settings.get(StorageKeys.licenseLastSeenMs) as int?;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<void> _writeLastSeen(DateTime at) async {
    final existing = _readLastSeen();
    final value = existing == null || at.isAfter(existing) ? at : existing;
    await _settings.put(
      StorageKeys.licenseLastSeenMs,
      value.millisecondsSinceEpoch,
    );
  }
}
