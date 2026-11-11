import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import 'support_codes.dart';

/// 关于弹窗共用的项目地址与公众号 / 赞赏码。
class AboutContact extends StatelessWidget {
  const AboutContact({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.common.github,
          style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        SelectableText(
          t.common.githubUrl,
          style: AppTextStyles.mono(cs, fontSize: 13, color: palette.text),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          t.common.aboutSupportHint,
          style: AppTextStyles.caption(cs).copyWith(
            color: palette.muted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const SupportCodes(qrWidth: 140),
      ],
    );
  }
}
