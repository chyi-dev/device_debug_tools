import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_status_widgets.dart';
import '../cubit/ble_console_cubit.dart';
import '../cubit/ble_console_state.dart';
import '../model/ble_models.dart';
import 'ble_l10n.dart';

class BleStatusBar extends StatelessWidget {
  const BleStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<BleConsoleCubit, BleConsoleState>(
      builder: (context, state) {
        final device = state.selected?.label;
        final conn = device == null
            ? t.ble.closed
            : state.connected
            ? '$device CONNECTED, MTU ${state.mtu}, ${_writeLabel(state.writeType)}'
            : '$device CLOSED';
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
                          color: state.connected ? palette.on : palette.off,
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        Expanded(
                          child: Text(
                            conn,
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
                Flexible(
                  child: SerialStatusCell(
                    child: Text(
                      '${t.ble.pin.notify} ${state.pinNotify?.uuid ?? '—'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        cs,
                      ).copyWith(color: palette.muted),
                    ),
                  ),
                ),
                Flexible(
                  child: SerialStatusCell(
                    child: Text(
                      '${t.ble.pin.write} ${state.pinWrite?.uuid ?? '—'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        cs,
                      ).copyWith(color: palette.muted),
                    ),
                  ),
                ),
                SerialStatusCell(child: SerialStatusCount('RX', state.rxCount)),
                SerialStatusCell(child: SerialStatusCount('TX', state.txCount)),
                SerialStatusCell(
                  child: SerialStatusTextButton(
                    label: t.serial.status.reset,
                    onPressed: context.read<BleConsoleCubit>().resetCounters,
                  ),
                ),
                SerialStatusCell(
                  child: Text(
                    t.serial.status.reply(
                      enabled: state.rules.where((rule) => rule.enabled).length,
                      total: state.rules.length,
                    ),
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted),
                  ),
                ),
                Expanded(
                  key: serialStatusHintKey,
                  child: SerialStatusHint(
                    text: bleNoticeText(t, state.hint),
                    showCopy: state.hint.kind != BleNoticeKind.ready,
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

String _writeLabel(BleWriteType type) =>
    type == BleWriteType.withResponse ? 'With Response' : 'Without Response';
