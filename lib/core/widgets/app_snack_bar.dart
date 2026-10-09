import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';

enum AppSnackType { success, error, info }

/// 统一轻提示；禁止在页面内直接 `ScaffoldMessenger.showSnackBar(SnackBar(...))`。
abstract final class AppSnackBar {
  static const double _maxWidth = 480;

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackType.error);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: AppSnackType.info);

  static void show(
    BuildContext context, {
    required String message,
    AppSnackType type = AppSnackType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg, icon) = _style(type, isDark);
    final width = MediaQuery.sizeOf(context).width;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message, style: TextStyle(color: fg))),
            ],
          ),
          backgroundColor: bg,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          width: width > _maxWidth + AppSpacing.xl * 2 ? _maxWidth : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
  }

  static (Color, Color, IconData) _style(AppSnackType type, bool isDark) {
    return switch (type) {
      AppSnackType.success => (
          isDark ? AppColors.snackSuccessBgDark : AppColors.snackSuccessBg,
          isDark ? AppColors.snackSuccessFgDark : AppColors.snackSuccessFg,
          Icons.check_circle_outline,
        ),
      AppSnackType.error => (
          isDark ? AppColors.snackErrorBgDark : AppColors.snackErrorBg,
          isDark ? AppColors.snackErrorFgDark : AppColors.snackErrorFg,
          Icons.error_outline,
        ),
      AppSnackType.info => (
          isDark ? AppColors.snackInfoBgDark : AppColors.snackInfoBg,
          isDark ? AppColors.snackInfoFgDark : AppColors.snackInfoFg,
          Icons.info_outline,
        ),
    };
  }
}
