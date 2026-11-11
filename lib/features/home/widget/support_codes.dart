import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';

const kWechatOfficialAsset = 'assets/appreciate/wechat_official.jpg';
const kWechatRewardAsset = 'assets/appreciate/wechat_reward.jpg';

/// 公众号与赞赏码并排展示，底部标注。
class SupportCodes extends StatelessWidget {
  const SupportCodes({super.key, this.qrWidth = 160});

  final double qrWidth;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CodeColumn(
            asset: kWechatOfficialAsset,
            label: t.common.officialAccount,
            qrWidth: qrWidth,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _CodeColumn(
            asset: kWechatRewardAsset,
            label: t.common.rewardCode,
            qrWidth: qrWidth,
          ),
        ),
      ],
    );
  }
}

class _CodeColumn extends StatelessWidget {
  const _CodeColumn({
    required this.asset,
    required this.label,
    required this.qrWidth,
  });

  final String asset;
  final String label;
  final double qrWidth;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          width: qrWidth,
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
        ),
      ],
    );
  }
}
