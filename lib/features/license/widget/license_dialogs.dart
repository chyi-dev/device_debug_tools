import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../i18n/i18n.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_dialog.dart';
import '../cubit/license_cubit.dart';

Future<void> showLicenseActivateDialog(BuildContext context) {
  final cubit = context.read<LicenseCubit>();
  cubit.clearActivateError();
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: const _LicenseActivateDialog(),
    ),
  );
}

class _LicenseActivateDialog extends StatefulWidget {
  const _LicenseActivateDialog();

  @override
  State<_LicenseActivateDialog> createState() => _LicenseActivateDialogState();
}

class _LicenseActivateDialogState extends State<_LicenseActivateDialog> {
  late final TextEditingController _code;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _submit() async {
    final ok = await context.read<LicenseCubit>().activate(_code.text.trim());
    if (!mounted) return;
    if (ok) {
      final t = Translations.of(context);
      AppSnackBar.success(context, t.license.success);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    final state = context.watch<LicenseCubit>().state;

    String statusLine;
    if (state.licenseExpiresOn != null && !state.showUnlicensedBanner) {
      statusLine = t.license.licenseExpires(date: _fmtDate(state.licenseExpiresOn!));
    } else if (state.inTrial) {
      statusLine = t.license.trialEnds(date: _fmtDate(state.trialEndsOn));
    } else if (state.licenseExpiresOn != null) {
      statusLine = t.license.licenseExpires(date: _fmtDate(state.licenseExpiresOn!));
    } else {
      statusLine = t.license.unlicensed;
    }

    String? errorText;
    switch (state.activateError) {
      case 'expired':
        errorText = t.license.expired;
      case 'invalid':
        errorText = t.license.invalid;
      case null:
        errorText = null;
      default:
        errorText = t.license.invalid;
    }

    return SerialDialogFrame(
      title: t.license.dialogTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  style: AppTextStyles.mono(cs, fontSize: 14, color: palette.text),
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
            statusLine,
            style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            t.license.activationHint,
            style: AppTextStyles.caption(cs).copyWith(
              color: palette.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            t.license.activationCode,
            style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _code,
            style: AppTextStyles.mono(cs, fontSize: 13, color: palette.text),
            decoration: InputDecoration(
              isDense: true,
              errorText: errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            minLines: 2,
            maxLines: 3,
            onChanged: (_) => context.read<LicenseCubit>().clearActivateError(),
            onSubmitted: (_) {
              if (!state.activating) _submit();
            },
          ),
        ],
      ),
      actions: [
        SerialButton(
          label: t.common.cancel,
          onPressed: state.activating
              ? null
              : () => Navigator.of(context).pop(),
        ),
        SerialButton(
          label: t.license.activate,
          primary: true,
          onPressed: state.activating ? null : _submit,
        ),
      ],
    );
  }
}
