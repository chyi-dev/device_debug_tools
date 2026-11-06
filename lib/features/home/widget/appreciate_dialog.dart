import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_dialog.dart';

const _qrAsset = 'assets/appreciate/wechat_reward.jpg';
const _qrWidth = 320.0;
const _dialogMaxWidth = 380.0;

Future<void> showAppreciateDialog(BuildContext context) {
  final t = Translations.of(context);
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) {
      final palette = SerialPalette.of(dialogContext);
      final cs = Theme.of(dialogContext).colorScheme;
      return SerialDialogFrame(
        title: t.serial.menu.appreciate,
        maxWidth: _dialogMaxWidth,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: SizedBox(
                width: _qrWidth,
                child: Image.asset(_qrAsset, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              t.common.appreciateHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
            ),
          ],
        ),
        actions: [
          SerialButton(
            label: t.common.close,
            primary: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      );
    },
  );
}
