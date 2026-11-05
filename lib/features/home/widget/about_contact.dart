import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';

/// 关于弹窗共用的项目地址与邮箱。
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
        _Row(
          label: t.common.github,
          value: t.common.githubUrl,
          labelStyle: AppTextStyles.caption(cs).copyWith(color: palette.muted),
          valueStyle: AppTextStyles.mono(cs, fontSize: 13, color: palette.text),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Row(
          label: t.common.email,
          value: t.common.emailAddress,
          labelStyle: AppTextStyles.caption(cs).copyWith(color: palette.muted),
          valueStyle: AppTextStyles.mono(cs, fontSize: 13, color: palette.text),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: AppSpacing.xs),
        SelectableText(value, style: valueStyle),
      ],
    );
  }
}
