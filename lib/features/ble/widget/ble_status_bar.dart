import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
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
                        _Cell(
                          child: Text(
                            '${t.ble.pin.notify} ${state.pinNotify?.uuid ?? '—'}',
                            style: AppTextStyles.caption(
                              cs,
                            ).copyWith(color: palette.muted),
                          ),
                        ),
                        _Cell(
                          child: Text(
                            '${t.ble.pin.write} ${state.pinWrite?.uuid ?? '—'}',
                            style: AppTextStyles.caption(
                              cs,
                            ).copyWith(color: palette.muted),
                          ),
                        ),
                        _Cell(child: _Count('RX', state.rxCount, palette, cs)),
                        _Cell(child: _Count('TX', state.txCount, palette, cs)),
                        _Cell(
                          child: TextButton(
                            onPressed: context
                                .read<BleConsoleCubit>()
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
                            t.serial.status.reply(
                              enabled: state.rules
                                  .where((rule) => rule.enabled)
                                  .length,
                              total: state.rules.length,
                            ),
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
                      bleNoticeText(t, state.hint),
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

String _writeLabel(BleWriteType type) =>
    type == BleWriteType.withResponse ? 'With Response' : 'Without Response';

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
