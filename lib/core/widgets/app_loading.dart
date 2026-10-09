import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../../app/theme/app_colors.dart';

/// 全屏阻塞加载；轻提示请用 `AppSnackBar`。
abstract final class AppLoading {
  static void show([String? status]) {
    EasyLoading.show(status: status);
  }

  static void dismiss() {
    EasyLoading.dismiss();
  }
}

void configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorColor = AppColors.primary
    ..progressColor = AppColors.primary
    ..backgroundColor = AppColors.primaryLight
    ..textColor = AppColors.primary
    ..maskType = EasyLoadingMaskType.black
    ..userInteractions = false;
}
