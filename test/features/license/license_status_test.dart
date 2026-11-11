import 'package:device_debug_tools/features/license/cubit/license_state.dart';
import 'package:device_debug_tools/features/license/model/license_evaluation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final trialStart = DateTime.utc(2025, 11, 5);

  group('LicenseState.isActivated', () {
    test('试用中不算已激活', () {
      final s = LicenseState(
        deviceCode: 'ABC',
        showUnlicensedBanner: false,
        inTrial: true,
        trialEndsOn: DateTime.utc(2026, 11, 5),
        ready: true,
      );
      expect(s.isActivated, isFalse);
    });

    test('试用结束未激活不算已激活', () {
      final s = LicenseState(
        deviceCode: 'ABC',
        showUnlicensedBanner: true,
        inTrial: false,
        trialEndsOn: DateTime.utc(2026, 11, 5),
        ready: true,
      );
      expect(s.isActivated, isFalse);
    });

    test('有效激活码为已激活', () {
      final s = LicenseState(
        deviceCode: 'ABC',
        showUnlicensedBanner: false,
        inTrial: false,
        trialEndsOn: DateTime.utc(2026, 11, 5),
        licenseExpiresOn: DateTime.utc(2027, 11, 5),
        ready: true,
      );
      expect(s.isActivated, isTrue);
    });
  });

  group('evaluateLicense', () {
    test('试用第 365 天仍无提示', () {
      final r = evaluateLicense(
        trialStartedAt: trialStart,
        lastSeenAt: DateTime.utc(2026, 11, 4),
        now: DateTime.utc(2026, 11, 5),
        storedActivation: null,
        verifyStored: (_) => null,
      );
      expect(r.showUnlicensedBanner, isFalse);
      expect(r.inTrial, isTrue);
    });

    test('试用第 366 天出现提示', () {
      final r = evaluateLicense(
        trialStartedAt: trialStart,
        lastSeenAt: DateTime.utc(2026, 11, 5),
        now: DateTime.utc(2026, 11, 6),
        storedActivation: null,
        verifyStored: (_) => null,
      );
      expect(r.showUnlicensedBanner, isTrue);
      expect(r.inTrial, isFalse);
    });

    test('时钟回拨不延长试用', () {
      final r = evaluateLicense(
        trialStartedAt: trialStart,
        lastSeenAt: DateTime.utc(2026, 11, 6),
        now: DateTime.utc(2025, 12, 1),
        storedActivation: null,
        verifyStored: (_) => null,
      );
      expect(r.showUnlicensedBanner, isTrue);
      expect(r.effectiveNow, DateTime.utc(2026, 11, 6));
    });

    test('未过期激活码无提示', () {
      final expires = DateTime.utc(2027, 11, 5);
      final r = evaluateLicense(
        trialStartedAt: trialStart,
        lastSeenAt: DateTime.utc(2026, 12, 1),
        now: DateTime.utc(2026, 12, 1),
        storedActivation: 'CODE',
        verifyStored: (_) => expires,
      );
      expect(r.showUnlicensedBanner, isFalse);
      expect(r.licenseExpiresOn, expires);
    });

    test('激活码到期次日重新提示', () {
      final expires = DateTime.utc(2027, 11, 5);
      final r = evaluateLicense(
        trialStartedAt: trialStart,
        lastSeenAt: DateTime.utc(2027, 11, 5),
        now: DateTime.utc(2027, 11, 6),
        storedActivation: 'CODE',
        verifyStored: (_) => expires,
      );
      expect(r.showUnlicensedBanner, isTrue);
    });
  });
}
