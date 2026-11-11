import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../i18n/i18n.dart';
import '../../serial/widget/serial_dialog.dart';
import '../cubit/mcp_cubit.dart';
import '../cubit/mcp_state.dart';
import '../model/mcp_models.dart';
import 'mcp_license_gate.dart';

Future<void> showMcpSettingsDialog(BuildContext context) async {
  if (!await ensureMcpLicensed(context)) return;
  if (!context.mounted) return;
  final cubit = context.read<McpCubit>();
  return showSerialDialog<void>(
    context: context,
    builder: (dialogContext) => BlocProvider.value(
      value: cubit,
      child: const _McpSettingsDialog(),
    ),
  );
}

class _McpSettingsDialog extends StatelessWidget {
  const _McpSettingsDialog();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<McpCubit, McpState>(
      builder: (context, state) {
        final s = state.settings;
        return SerialDialogFrame(
          title: t.mcp.settingsTitle,
          maxWidth: 520,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Check(
                label: t.mcp.enable,
                value: s.enabled,
                onChanged: (v) => context.read<McpCubit>().setEnabled(v),
              ),
              if (s.enabled) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.clientConnected
                      ? t.mcp.clientConnected
                      : t.mcp.waitingClient,
                  style: AppTextStyles.body(cs).copyWith(color: palette.text),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  t.mcp.endpoint(url: state.endpoint),
                  style: AppTextStyles.mono(cs).copyWith(fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: state.cursorConfigJson),
                      );
                      if (!context.mounted) return;
                      AppSnackBar.success(context, t.mcp.configCopied);
                    },
                    child: Text(t.mcp.copyConfig),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                t.mcp.authTitle,
                style: AppTextStyles.caption(cs).copyWith(
                  color: palette.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _Check(
                label: t.mcp.allowSend,
                value: s.allowSend,
                onChanged: (v) => context.read<McpCubit>().saveSettings(
                  s.copyWith(allowSend: v),
                ),
              ),
              _Check(
                label: t.mcp.allowRead,
                value: s.allowRead,
                onChanged: (v) => context.read<McpCubit>().saveSettings(
                  s.copyWith(allowRead: v),
                ),
              ),
              _Check(
                label: t.mcp.allowReply,
                value: s.allowReply,
                onChanged: (v) => context.read<McpCubit>().saveSettings(
                  s.copyWith(allowReply: v),
                ),
              ),
              _Check(
                label: t.mcp.allowScript,
                value: s.allowScript,
                onChanged: (v) => context.read<McpCubit>().saveSettings(
                  s.copyWith(allowScript: v),
                ),
              ),
              _Check(
                label: t.mcp.allowQuick,
                value: s.allowQuick,
                onChanged: (v) => context.read<McpCubit>().saveSettings(
                  s.copyWith(allowQuick: v),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PolicyRow(
                label: t.mcp.replyPolicy,
                value: s.replyPolicy,
                onChanged: (v) => context.read<McpCubit>().saveSettings(
                  s.copyWith(replyPolicy: v),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PolicyRow(
                label: t.mcp.scriptPolicy,
                value: s.scriptPolicy,
                onChanged: (v) => context.read<McpCubit>().saveSettings(
                  s.copyWith(scriptPolicy: v),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PolicyRow(
                label: t.mcp.quickPolicy,
                value: s.quickPolicy,
                onChanged: (v) => context.read<McpCubit>().saveSettings(
                  s.copyWith(quickPolicy: v),
                ),
              ),
              if (state.pendingCount > 0) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  t.mcp.pendingHint(count: state.pendingCount),
                  style: AppTextStyles.body(cs).copyWith(color: palette.muted),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t.common.close),
            ),
          ],
        );
      },
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      value: value,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final McpEnablePolicy value;
  final ValueChanged<McpEnablePolicy> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Row(
      children: [
        Expanded(child: Text(label)),
        DropdownButton<McpEnablePolicy>(
          value: value,
          items: [
            DropdownMenuItem(
              value: McpEnablePolicy.on,
              child: Text(t.mcp.policyOn),
            ),
            DropdownMenuItem(
              value: McpEnablePolicy.off,
              child: Text(t.mcp.policyOff),
            ),
            DropdownMenuItem(
              value: McpEnablePolicy.ask,
              child: Text(t.mcp.policyAsk),
            ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}
