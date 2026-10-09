import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_style.dart';
import '../../i18n/i18n.dart';

/// 错误态 + 重试。
class AppError extends StatelessWidget {
  const AppError({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final cs = Theme.of(context).colorScheme;
    return _FeedbackLayout(
      icon: Icons.error_outline,
      iconColor: cs.error,
      message: message ?? t.common.error,
      action: onRetry == null
          ? null
          : OutlinedButton(onPressed: onRetry, child: Text(t.common.retry)),
    );
  }
}

/// 空态。
class AppEmpty extends StatelessWidget {
  const AppEmpty({super.key, this.message, this.icon = Icons.inbox_outlined});

  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _FeedbackLayout(
      icon: icon,
      iconColor: cs.onSurfaceVariant,
      message: message ?? Translations.of(context).common.empty,
    );
  }
}

class _FeedbackLayout extends StatelessWidget {
  const _FeedbackLayout({
    required this.icon,
    required this.iconColor,
    required this.message,
    this.action,
  });

  final IconData icon;
  final Color iconColor;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(cs),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
