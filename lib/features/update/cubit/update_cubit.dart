import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../../../env/app_env.dart';
import '../model/app_release.dart';
import '../repository/update_repository.dart';
import 'update_state.dart';

class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit({required UpdateRepository repository})
    : _repository = repository,
      super(const UpdateIdle());

  final UpdateRepository _repository;
  bool _busy = false;

  /// 生产入口启动后静默检查；开发包与 widget 测试跳过。
  Future<void> checkOnStartup() async {
    if (appIsDev) return;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return;
    if (!_repository.shouldSilentCheck()) return;
    await _check(manual: false);
  }

  Future<void> checkManual() => _check(manual: true);

  Future<void> _check({required bool manual}) async {
    if (_busy) return;
    _busy = true;
    emit(UpdateChecking(manual: manual));
    try {
      final outcome = await _repository.checkLatest();
      switch (outcome) {
        case UpdateCheckUpToDate(:final currentVersion):
          if (manual) {
            emit(UpdateUpToDate(version: currentVersion, manual: true));
          } else {
            emit(const UpdateIdle());
          }
        case UpdateCheckAvailable(
          :final currentVersion,
          :final release,
          :final canInstall,
        ):
          if (!manual && _repository.isDismissed(release.version)) {
            emit(const UpdateIdle());
          } else {
            emit(
              UpdateAvailable(
                currentVersion: currentVersion,
                release: release,
                canInstall: canInstall,
                manual: manual,
              ),
            );
          }
      }
    } on AppException catch (e, s) {
      AppLogger.i.error(
        '检查更新失败',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
      if (manual) {
        emit(UpdateFailed(message: e.message, manual: true));
      } else {
        emit(const UpdateIdle());
      }
    } catch (e, s) {
      AppLogger.i.error(
        '检查更新失败',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
      if (manual) {
        emit(UpdateFailed(message: e.toString(), manual: true));
      } else {
        emit(const UpdateIdle());
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> dismissAvailable(AppRelease release) async {
    await _repository.dismissVersion(release.version);
    emit(const UpdateIdle());
  }

  Future<void> openReleasePage(AppRelease release) async {
    try {
      await _repository.openReleasePage(release);
      emit(const UpdateIdle());
    } on AppException catch (e) {
      emit(UpdateFailed(message: e.message, manual: true));
    }
  }

  Future<void> downloadAndInstall(AppRelease release) async {
    if (_busy) return;
    _busy = true;
    emit(
      UpdateDownloading(
        release: release,
        received: 0,
        total: release.windowsSetupSize,
      ),
    );
    try {
      final file = await _repository.downloadWindowsSetup(
        release,
        onProgress: (received, total) {
          if (isClosed) return;
          emit(
            UpdateDownloading(
              release: release,
              received: received,
              total: total ?? release.windowsSetupSize,
            ),
          );
        },
      );
      await _repository.launchInstallerAndExit(file);
    } on AppException catch (e, s) {
      AppLogger.i.error(
        '下载或启动安装包失败',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
      emit(UpdateFailed(message: e.message, manual: true));
    } catch (e, s) {
      AppLogger.i.error(
        '下载或启动安装包失败',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
      emit(UpdateFailed(message: e.toString(), manual: true));
    } finally {
      _busy = false;
    }
  }

  void clearFeedback() {
    if (state is UpdateUpToDate || state is UpdateFailed) {
      emit(const UpdateIdle());
    }
  }

  @override
  Future<void> close() {
    _repository.dispose();
    return super.close();
  }
}
