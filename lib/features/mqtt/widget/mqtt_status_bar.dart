import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import '../../serial/widget/serial_status_widgets.dart';
import '../cubit/mqtt_console_cubit.dart';
import '../cubit/mqtt_console_state.dart';
import '../model/mqtt_models.dart';
import 'mqtt_l10n.dart';

class MqttStatusBar extends StatelessWidget {
  const MqttStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<MqttConsoleCubit, MqttConsoleState>(
      builder: (context, state) {
        final version = state.version == MqttVersion.v5 ? '5.0' : '3.1.1';
        final conn =
            '${state.endpoint} ${state.connected ? 'OPENED' : 'CLOSED'}, MQTT $version, ${state.clientId}';
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
                SerialStatusCell(child: SerialStatusCount('RX', state.rxCount)),
                SerialStatusCell(child: SerialStatusCount('TX', state.txCount)),
                SerialStatusCell(
                  child: SerialStatusTextButton(
                    label: t.serial.status.reset,
                    onPressed: context.read<MqttConsoleCubit>().resetCounters,
                  ),
                ),
                SerialStatusCell(
                  child: Text(
                    t.mqtt.status.subs(count: state.subs.length),
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted),
                  ),
                ),
                Expanded(
                  key: serialStatusHintKey,
                  child: SerialStatusHint(
                    text: mqttNoticeText(t, state.hint),
                    showCopy: state.hint.kind != MqttNoticeKind.ready,
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
