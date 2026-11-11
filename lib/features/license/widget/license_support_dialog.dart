import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../i18n/i18n.dart';
import '../../home/widget/support_codes.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_dialog.dart';
import '../cubit/license_cubit.dart';
import '../cubit/license_state.dart';
import 'license_dialogs.dart';

/// 未激活时展示公众号 / 赞赏码、设备码与激活路径。
Future<void> showLicenseSupportDialog(BuildContext context) {
  final cubit = context.read<LicenseCubit>();
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: const _LicenseSupportDialog(),
    ),
  );
}

class _LicenseSupportDialog extends StatelessWidget {
  const _LicenseSupportDialog();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<LicenseCubit, LicenseState>(
      builder: (context, state) {
        return SerialDialogFrame(
          title: t.license.unlicensed,
          maxWidth: 520,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.license.supportBody,
                style: AppTextStyles.body(cs).copyWith(
                  color: palette.text,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SupportCodes(qrWidth: 160),
              const SizedBox(height: AppSpacing.lg),
              Text(
                t.license.deviceCode,
                style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      state.deviceCode.isEmpty ? '…' : state.deviceCode,
                      style: AppTextStyles.mono(
                        cs,
                        fontSize: 14,
                        color: palette.text,
                      ),
                    ),
                  ),
                  SerialButton(
                    label: t.license.copyDeviceCode,
                    onPressed: state.deviceCode.isEmpty
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(text: state.deviceCode),
                            );
                            if (!context.mounted) return;
                            AppSnackBar.success(context, t.license.copied);
                          },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.license.supportPathHint,
                style: AppTextStyles.caption(cs).copyWith(
                  color: palette.muted,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            SerialButton(
              label: t.common.close,
              onPressed: () => Navigator.of(context).pop(),
            ),
            SerialButton(
              label: t.license.activateEllipsis,
              primary: true,
              onPressed: () async {
                Navigator.of(context).pop();
                if (!context.mounted) return;
                await showLicenseActivateDialog(context);
              },
            ),
          ],
        );
      },
    );
  }
}
