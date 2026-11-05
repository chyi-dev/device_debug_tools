import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/exception/app_exception.dart';
import '../../../core/logger/app_logger.dart';
import '../../../core/logger/log_category.dart';
import '../repository/license_repository.dart';
import 'license_state.dart';

class LicenseCubit extends Cubit<LicenseState> {
  LicenseCubit({required LicenseRepository repository})
    : _repository = repository,
      super(LicenseState.initial);

  final LicenseRepository _repository;

  Future<void> start() async {
    try {
      final snap = await _repository.load();
      emit(_fromSnapshot(snap));
    } catch (e, s) {
      AppLogger.i.error(
        '加载授权状态失败',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
      emit(state.copyWith(ready: true, showUnlicensedBanner: false));
    }
  }

  Future<bool> activate(String code) async {
    emit(state.copyWith(activating: true, clearActivateError: true));
    try {
      final snap = await _repository.activate(code);
      emit(_fromSnapshot(snap));
      return true;
    } on ValidationException catch (e) {
      emit(
        state.copyWith(
          activating: false,
          activateError: e.message,
        ),
      );
      return false;
    } catch (e, s) {
      AppLogger.i.error(
        '激活失败',
        category: LogCategory.app,
        error: e,
        stackTrace: s,
      );
      emit(
        state.copyWith(
          activating: false,
          activateError: 'invalid',
        ),
      );
      return false;
    }
  }

  void clearActivateError() {
    if (state.activateError != null) {
      emit(state.copyWith(clearActivateError: true));
    }
  }

  LicenseState _fromSnapshot(LicenseSnapshot snap) {
    final e = snap.evaluation;
    return LicenseState(
      deviceCode: snap.deviceCode,
      showUnlicensedBanner: e.showUnlicensedBanner,
      inTrial: e.inTrial,
      trialEndsOn: e.trialEndsOn,
      licenseExpiresOn: e.licenseExpiresOn,
      ready: true,
      activating: false,
    );
  }
}
