import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../cubit/serial_console_cubit.dart';
import '../cubit/serial_console_state.dart';
import '../model/serial_models.dart';
import '../serial_metrics.dart';
import 'serial_chrome.dart';
import 'serial_l10n.dart';
import 'serial_status_widgets.dart';

class SerialStatusBar extends StatelessWidget {
  const SerialStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<SerialConsoleCubit, SerialConsoleState>(
      builder: (context, state) {
        final enabled = state.rules.where((rule) => rule.enabled).length;
        final hint = serialNoticeText(t, state.hint);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border(top: BorderSide(color: palette.line)),
          ),
          child: SizedBox(
            height: SerialMetrics.statusBar,
            child: Row(
              children: [
                Flexible(
                  child: SerialStatusCell(
                    child: Row(
                      children: [
                        SerialLamp(
                          size: SerialMetrics.statusLamp,
                          color: state.open ? palette.on : palette.off,
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Expanded(
                          child: Text(
                            state.connectionLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.mono(
                              cs,
                              fontSize: 12,
                              color: palette.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SerialStatusCell(child: SerialStatusCount('RX', state.rxCount)),
                SerialStatusCell(child: SerialStatusCount('TX', state.txCount)),
                SerialStatusCell(
                  child: SerialStatusTextButton(
                    label: t.serial.status.reset,
                    onPressed: context.read<SerialConsoleCubit>().resetCounters,
                  ),
                ),
                SerialStatusCell(
                  child: Text(
                    t.serial.status.reply(
                      enabled: enabled,
                      total: state.rules.length,
                    ),
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted),
                  ),
                ),
                if (state.saveActive)
                  SerialStatusCell(
                    child: Text(
                      t.serial.status.saving(
                        name: state.saveName,
                        count: state.savedCount,
                      ),
                      style: AppTextStyles.caption(
                        cs,
                      ).copyWith(color: palette.logSys),
                    ),
                  ),
                Expanded(
                  key: serialStatusHintKey,
                  child: SerialStatusHint(
                    text: hint,
                    showCopy: state.hint.kind != SerialNoticeKind.ready,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
