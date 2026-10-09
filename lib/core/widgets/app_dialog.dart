import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../i18n/i18n.dart';

/// 统一对话框入口。
abstract final class AppDialogs {
  static const double _maxWidth = 440;

  /// 确认对话框，确认返回 `true`，取消或关闭返回 `false`。
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    String? confirmLabel,
    String? cancelLabel,
    bool destructive = false,
  }) async {
    final t = Translations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text(title),
          content: message == null
              ? null
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxWidth),
                  child: Text(message),
                ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel ?? t.common.cancel),
            ),
            FilledButton(
              style: destructive
                  ? FilledButton.styleFrom(backgroundColor: cs.error)
                  : null,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel ?? t.common.confirm),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
