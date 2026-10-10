import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../cubit/serial_console_cubit.dart';
import '../cubit/serial_console_state.dart';
import '../serial_metrics.dart';
import 'serial_chrome.dart';
import 'serial_l10n.dart';

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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Cell(
                          child: Row(
                            children: [
                              SerialLamp(
                                size: SerialMetrics.statusLamp,
                                color: state.open ? palette.on : palette.off,
                              ),
                              const SizedBox(width: AppSpacing.xs + 2),
                              Text(
                                state.connectionLabel,
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
                                .read<SerialConsoleCubit>()
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
                              enabled: enabled,
                              total: state.rules.length,
                            ),
                            style: AppTextStyles.caption(
                              cs,
                            ).copyWith(color: palette.muted),
                          ),
                        ),
                        if (state.saveActive)
                          _Cell(
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
                      ],
                    ),
                  ),
                ),
                _Cell(
                  last: true,
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption(
                      cs,
                    ).copyWith(color: palette.muted),
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
            text: value.toString(),
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
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          left: last ? BorderSide(color: palette.line2) : BorderSide.none,
          right: last ? BorderSide.none : BorderSide(color: palette.line2),
        ),
      ),
      child: child,
    );
  }
}
