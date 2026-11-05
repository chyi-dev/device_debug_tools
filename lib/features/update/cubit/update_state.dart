import '../model/app_release.dart';

/// 全局更新检查状态。
sealed class UpdateState {
  const UpdateState();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking({required this.manual});

  final bool manual;
}

class UpdateUpToDate extends UpdateState {
  const UpdateUpToDate({required this.version, required this.manual});

  final String version;
  final bool manual;
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable({
    required this.currentVersion,
    required this.release,
    required this.canInstall,
    required this.manual,
  });

  final String currentVersion;
  final AppRelease release;
  final bool canInstall;
  final bool manual;
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading({
    required this.release,
    required this.received,
    this.total,
  });

  final AppRelease release;
  final int received;
  final int? total;

  double? get progress {
    final t = total;
    if (t == null || t <= 0) return null;
    return (received / t).clamp(0.0, 1.0);
  }
}

class UpdateFailed extends UpdateState {
  const UpdateFailed({required this.message, required this.manual});

  final String message;
  final bool manual;
}
