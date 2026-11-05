/// 授权状态快照，供横幅与激活对话框使用。
class LicenseState {
  const LicenseState({
    required this.deviceCode,
    required this.showUnlicensedBanner,
    required this.inTrial,
    required this.trialEndsOn,
    required this.ready,
    this.licenseExpiresOn,
    this.activateError,
    this.activating = false,
  });

  final String deviceCode;
  final bool showUnlicensedBanner;
  final bool inTrial;
  final DateTime trialEndsOn;
  final DateTime? licenseExpiresOn;
  final bool ready;
  final String? activateError;
  final bool activating;

  static final initial = LicenseState(
    deviceCode: '',
    showUnlicensedBanner: false,
    inTrial: true,
    trialEndsOn: DateTime.utc(1970),
    ready: false,
  );

  LicenseState copyWith({
    String? deviceCode,
    bool? showUnlicensedBanner,
    bool? inTrial,
    DateTime? trialEndsOn,
    DateTime? licenseExpiresOn,
    bool clearLicenseExpiresOn = false,
    bool? ready,
    String? activateError,
    bool clearActivateError = false,
    bool? activating,
  }) {
    return LicenseState(
      deviceCode: deviceCode ?? this.deviceCode,
      showUnlicensedBanner: showUnlicensedBanner ?? this.showUnlicensedBanner,
      inTrial: inTrial ?? this.inTrial,
      trialEndsOn: trialEndsOn ?? this.trialEndsOn,
      licenseExpiresOn: clearLicenseExpiresOn
          ? null
          : (licenseExpiresOn ?? this.licenseExpiresOn),
      ready: ready ?? this.ready,
      activateError: clearActivateError
          ? null
          : (activateError ?? this.activateError),
      activating: activating ?? this.activating,
    );
  }
}
