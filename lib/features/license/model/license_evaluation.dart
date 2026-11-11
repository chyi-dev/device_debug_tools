import '../../../core/constants/app_constants.dart';

/// 纯函数评估：试用 / 已激活 / 需提示。
class LicenseEvaluation {
  const LicenseEvaluation({
    required this.showUnlicensedBanner,
    required this.inTrial,
    required this.effectiveNow,
    required this.trialEndsOn,
    this.licenseExpiresOn,
  });

  final bool showUnlicensedBanner;
  final bool inTrial;
  final DateTime effectiveNow;
  final DateTime trialEndsOn;
  final DateTime? licenseExpiresOn;
}

/// [verifyStored]：已存激活码校验成功时返回 UTC 到期日，否则 `null`。
LicenseEvaluation evaluateLicense({
  required DateTime trialStartedAt,
  required DateTime lastSeenAt,
  required DateTime now,
  required String? storedActivation,
  required DateTime? Function(String activationCode) verifyStored,
  int trialDays = AppConstants.licenseTrialDays,
}) {
  final effective = now.isBefore(lastSeenAt) ? lastSeenAt : now;
  final trialStartDay = DateTime.utc(
    trialStartedAt.year,
    trialStartedAt.month,
    trialStartedAt.day,
  );
  final trialEndsOn = trialStartDay.add(Duration(days: trialDays));
  final effectiveDay = DateTime.utc(
    effective.year,
    effective.month,
    effective.day,
  );

  DateTime? expires;
  if (storedActivation != null && storedActivation.isNotEmpty) {
    expires = verifyStored(storedActivation);
  }

  if (expires != null) {
    final expDay = DateTime.utc(expires.year, expires.month, expires.day);
    if (!effectiveDay.isAfter(expDay)) {
      return LicenseEvaluation(
        showUnlicensedBanner: false,
        inTrial: false,
        effectiveNow: effective,
        trialEndsOn: trialEndsOn,
        licenseExpiresOn: expDay,
      );
    }
  }

  final inTrial = !effectiveDay.isAfter(trialEndsOn);
  return LicenseEvaluation(
    showUnlicensedBanner: !inTrial,
    inTrial: inTrial,
    effectiveNow: effective,
    trialEndsOn: trialEndsOn,
    licenseExpiresOn: expires == null
        ? null
        : DateTime.utc(expires.year, expires.month, expires.day),
  );
}
