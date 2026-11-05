import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../../serial/data/serial_bytes.dart';
import '../../serial/serial_metrics.dart';
import '../../serial/widget/serial_chrome.dart';
import '../cubit/ble_console_cubit.dart';
import '../cubit/ble_console_state.dart';

class BleSendBox extends StatefulWidget {
  const BleSendBox({super.key});

  @override
  State<BleSendBox> createState() => _BleSendBoxState();
}

class _BleSendBoxState extends State<BleSendBox> {
  final TextEditingController _controller = TextEditingController();
  String _seen = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return BlocConsumer<BleConsoleCubit, BleConsoleState>(
      listenWhen: (a, b) => a.txText != b.txText,
      listener: (context, state) {
        if (state.txText != _controller.text) {
          _controller.value = TextEditingValue(
            text: state.txText,
            selection: TextSelection.collapsed(offset: state.txText.length),
          );
        }
        _seen = state.txText;
      },
      builder: (context, state) {
        if (_controller.text.isEmpty &&
            state.txText.isNotEmpty &&
            _seen.isEmpty) {
          _controller.text = state.txText;
          _seen = state.txText;
        }
        final cubit = context.read<BleConsoleCubit>();
        final bytes = SerialBytes.parseHex(state.txText);
        final foot = state.pinWrite == null
            ? t.ble.noWrite
            : t.ble.bytes(
                count: bytes?.length ?? 0,
                uuid: state.pinWrite!.uuid,
              );
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.panel,
            border: Border.all(color: palette.line),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            children: [
              SizedBox(
                height: SerialMetrics.sendHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Focus(
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              event.logicalKey == LogicalKeyboardKey.enter &&
                              HardwareKeyboard.instance.isControlPressed) {
                            cubit.sendFromEditor();
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextField(
                          controller: _controller,
                          expands: true,
                          maxLines: null,
                          onChanged: cubit.setTxText,
                          style: AppTextStyles.mono(
                            cs,
                            fontSize: 15,
                            height: 1.5,
                            color: palette.text,
                          ),
                          cursorColor: palette.accent,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: palette.field,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(
                              AppSpacing.sm + 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: palette.line)),
                      ),
                      child: SizedBox(
                        width: SerialMetrics.sendSide,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SerialButton(
                                label: t.ble.send,
                                primary: true,
                                expand: true,
                                onPressed: cubit.sendFromEditor,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              SerialButton(
                                label: t.ble.clear,
                                expand: true,
                                onPressed: () => cubit.setTxText(''),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.line2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        foot,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption(cs).copyWith(
                          color: state.pinWrite == null
                              ? palette.off
                              : palette.muted,
                        ),
                      ),
                    ),
                    Text(
                      t.ble.ctrlEnter,
                      style: AppTextStyles.caption(
                        cs,
                      ).copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
