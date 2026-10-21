import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
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
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Cell(
                          child: Row(
                            children: [
                              SerialLamp(
                                size: SerialMetrics.statusLamp,
                                color: state.connected
                                    ? palette.on
                                    : palette.off,
                              ),
                              const SizedBox(width: AppSpacing.xs + 2),
                              Text(
                                conn,
                                style: AppTextStyles.mono(
                                  cs,
                                  fontSize: 12,
                                  color: palette.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _Cell(child: _Count('RX', state.rxCount, palette, cs)),
                        _Cell(child: _Count('TX', state.txCount, palette, cs)),
                        _Cell(
                          child: TextButton(
                            onPressed: context
                                .read<MqttConsoleCubit>()
                                .resetCounters,
                            style: TextButton.styleFrom(
                              foregroundColor: palette.accent,
                              minimumSize: Size.zero,
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: AppTextStyles.caption(cs),
                            ),
                            child: Text(t.serial.status.reset),
                          ),
                        ),
                        _Cell(
                          child: Text(
                            t.mqtt.status.subs(count: state.subs.length),
                            style: AppTextStyles.caption(
                              cs,
                            ).copyWith(color: palette.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: _Cell(
                    last: true,
                    child: Text(
                      mqttNoticeText(t, state.hint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption(
                        cs,
                      ).copyWith(color: palette.muted),
                    ),
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

class _Count extends StatelessWidget {
  const _Count(this.label, this.value, this.palette, this.cs);

  final String label;
  final int value;
  final SerialPalette palette;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: '$label: ',
        style: AppTextStyles.caption(cs).copyWith(color: palette.muted),
        children: [
          TextSpan(
            text: '$value',
            style: AppTextStyles.mono(
              cs,
              fontSize: 12,
              color: palette.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.child, this.last = false});

  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = SerialPalette.of(context);
    return Container(
      height: SerialMetrics.statusBar,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: last ? null : Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          left: last ? BorderSide(color: palette.line2) : BorderSide.none,
          right: last ? BorderSide.none : BorderSide(color: palette.line2),
        ),
      ),
      child: last
          ? Align(alignment: Alignment.centerLeft, widthFactor: 1, child: child)
          : child,
    );
  }
}
