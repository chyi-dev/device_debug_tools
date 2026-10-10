import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_style.dart';
import '../../../app/theme/serial_palette.dart';
import '../../../i18n/i18n.dart';
import '../cubit/serial_console_cubit.dart';
import '../cubit/serial_console_state.dart';
import '../data/serial_bytes.dart';
import '../model/serial_models.dart';
import '../serial_metrics.dart';
import 'serial_chrome.dart';
import 'serial_l10n.dart';

class SerialSendBox extends StatefulWidget {
  const SerialSendBox({super.key});

  @override
  State<SerialSendBox> createState() => _SerialSendBoxState();
}

class _SerialSendBoxState extends State<SerialSendBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _seen = '';

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final palette = SerialPalette.of(context);
    final cs = Theme.of(context).colorScheme;
    return BlocConsumer<SerialConsoleCubit, SerialConsoleState>(
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
        final cubit = context.read<SerialConsoleCubit>();
        final preview = _preview(t, state);
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
                          focusNode: _focus,
                          enabled: state.fileBytes == null,
                          expands: true,
                          maxLines: null,
                          onChanged: (value) {
                            _seen = value;
                            cubit.setTxText(value);
                          },
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
                            children: [
                              Expanded(
                                child: SerialButton(
                                  label: state.looping
                                      ? t.serial.sendBox.stopLoop
                                      : t.serial.sendBox.send,
                                  expand: true,
                                  primary: !state.looping,
                                  alert: state.looping,
                                  onPressed: cubit.sendFromEditor,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs + 2),
                              SerialButton(
                                label: t.serial.sendBox.clear,
                                expand: true,
                                onPressed: () {
                                  cubit.clearTx();
                                  _controller.clear();
                                  _focus.requestFocus();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: palette.line2)),
                ),
                child: SizedBox(
                  height: 28,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                preview.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.mono(
                                  cs,
                                  fontSize: 12,
                                  color: preview.error
                                      ? palette.off
                                      : palette.muted,
                                ),
                              ),
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth * 0.62,
                              ),
                              child: Text(
                                t.serial.sendBox.foot,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: AppTextStyles.mono(
                                  cs,
                                  fontSize: 12,
                                  color: palette.muted,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  ({String text, bool error}) _preview(
    Translations t,
    SerialConsoleState state,
  ) {
    final file = state.fileBytes;
    final text = file != null ? SerialBytes.toHex(file) : state.txText;
    final format = file != null ? DataFormat.hex : state.txFormat;
    final encoded = SerialBytes.encode(
      text: text,
      format: format,
      escape: state.escape,
      atCrlf: state.atCrlf,
      crlf: state.crlf,
      checksum: state.checksum,
    );
    if (encoded.error != null) {
      return (text: encodeErrorText(t, encoded.error!), error: true);
    }
    final bytes = encoded.bytes ?? const <int>[];
    final shown = bytes.length > 24
        ? '${SerialBytes.toHex(bytes.sublist(0, 24))} …'
        : SerialBytes.toHex(bytes);
    return (
      text: t.serial.sendBox.preview(count: bytes.length, hex: shown),
      error: false,
    );
  }
}
